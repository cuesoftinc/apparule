// Package storage is object storage (system-design.md §5.1): GCS in cloud
// via ADC, any S3-compatible store (MinIO) for compose and self-host.
// api/common moves images out of tmp/ when they are kept (§6.2), and owns
// captures/, media/, attachments/, exports/ and compute/. Every object is
// private and reached through a short-lived signed URL (system-design.md I-8).
package storage

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	gcs "cloud.google.com/go/storage"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"google.golang.org/api/iterator"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

type Object struct {
	Key     string
	Created time.Time
}

type Store interface {
	Bucket() string
	Prefix() string
	Put(ctx context.Context, key string, data []byte, contentType string) error
	Get(ctx context.Context, key string) ([]byte, error)
	Delete(ctx context.Context, key string) error
	List(ctx context.Context, prefix string) ([]Object, error)
	// Copy copies an object within the bucket (server side).
	Copy(ctx context.Context, src, dst string) error
	// SignedURL is a time-limited GET URL for a private object.
	SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error)
}

// ErrMissing is returned by Get and Copy for an object that doesn't exist.
var ErrMissing = errors.New("object missing")

func Open(ctx context.Context, cfg config.Storage) (Store, error) {
	if cfg.Driver == "s3" {
		client, err := minio.New(cfg.Endpoint, &minio.Options{
			Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
			Secure: cfg.UseSSL,
		})
		if err != nil {
			return nil, err
		}
		// Compose and self-host: common owns the bucket, so it creates it.
		if exists, err := client.BucketExists(ctx, cfg.Bucket); err != nil {
			return nil, err
		} else if !exists {
			if err := client.MakeBucket(ctx, cfg.Bucket, minio.MakeBucketOptions{}); err != nil {
				return nil, err
			}
		}
		return cached(&s3Store{client: client, bucket: cfg.Bucket, prefix: cfg.Prefix}), nil
	}
	client, err := gcs.NewClient(ctx)
	if err != nil {
		return nil, err
	}
	return cached(&gcsStore{bucket: client.Bucket(cfg.Bucket), name: cfg.Bucket, prefix: cfg.Prefix}), nil
}

// TmpPrefix is where api/uploads writes images.
func TmpPrefix(s Store) string { return s.Prefix() + "/tmp/" }

// ComputePrefix holds claim-check payloads of bus messages.
func ComputePrefix(s Store) string { return s.Prefix() + "/compute/" }

// ── Signed URL cache ────────────────────────────────────────────────────

// maxSigned bounds the cache; past it stale entries go, then all of them.
const maxSigned = 10_000

type signKey struct {
	key string
	ttl time.Duration
}

type signedURL struct {
	url     string
	expires time.Time
}

// signCache reuses a signed URL for half its life, so a feed signs each
// image once rather than on every read (GCS signs through IAM on Cloud Run).
type signCache struct {
	Store
	mu   sync.Mutex
	urls map[signKey]signedURL
}

func cached(s Store) Store { return &signCache{Store: s, urls: map[signKey]signedURL{}} }

func (c *signCache) SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error) {
	k := signKey{key, ttl}
	now := time.Now()
	c.mu.Lock()
	hit, ok := c.urls[k]
	c.mu.Unlock()
	if ok && hit.expires.Sub(now) > ttl/2 {
		return hit.url, nil
	}
	u, err := c.Store.SignedURL(ctx, key, ttl)
	if err != nil {
		return "", err
	}
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.urls) >= maxSigned {
		for k, v := range c.urls {
			if v.expires.Sub(now) <= k.ttl/2 {
				delete(c.urls, k)
			}
		}
		if len(c.urls) >= maxSigned {
			clear(c.urls)
		}
	}
	c.urls[k] = signedURL{url: u, expires: now.Add(ttl)}
	return u, nil
}

// ── GCS ─────────────────────────────────────────────────────────────────

type gcsStore struct {
	bucket *gcs.BucketHandle
	name   string
	prefix string
}

func (s *gcsStore) Bucket() string { return s.name }
func (s *gcsStore) Prefix() string { return s.prefix }

func (s *gcsStore) Put(ctx context.Context, key string, data []byte, contentType string) error {
	w := s.bucket.Object(key).NewWriter(ctx)
	w.ContentType = contentType
	if _, err := w.Write(data); err != nil {
		_ = w.Close()
		return err
	}
	return w.Close()
}

func (s *gcsStore) Get(ctx context.Context, key string) ([]byte, error) {
	r, err := s.bucket.Object(key).NewReader(ctx)
	if errors.Is(err, gcs.ErrObjectNotExist) {
		return nil, ErrMissing
	}
	if err != nil {
		return nil, err
	}
	defer r.Close()
	return io.ReadAll(r)
}

func (s *gcsStore) Delete(ctx context.Context, key string) error {
	err := s.bucket.Object(key).Delete(ctx)
	if errors.Is(err, gcs.ErrObjectNotExist) {
		return nil
	}
	return err
}

func (s *gcsStore) List(ctx context.Context, prefix string) ([]Object, error) {
	var out []Object
	it := s.bucket.Objects(ctx, &gcs.Query{Prefix: prefix})
	for {
		attrs, err := it.Next()
		if errors.Is(err, iterator.Done) {
			return out, nil
		}
		if err != nil {
			return nil, err
		}
		out = append(out, Object{Key: attrs.Name, Created: attrs.Created})
	}
}

func (s *gcsStore) Copy(ctx context.Context, src, dst string) error {
	_, err := s.bucket.Object(dst).CopierFrom(s.bucket.Object(src)).Run(ctx)
	if errors.Is(err, gcs.ErrObjectNotExist) {
		return ErrMissing
	}
	return err
}

// SignedURL signs with the service account through the IAM Credentials API
// on Cloud Run (roles/iam.serviceAccountTokenCreator on itself).
func (s *gcsStore) SignedURL(_ context.Context, key string, ttl time.Duration) (string, error) {
	return s.bucket.SignedURL(key, &gcs.SignedURLOptions{Method: http.MethodGet, Expires: time.Now().Add(ttl), Scheme: gcs.SigningSchemeV4})
}

// ── S3 / MinIO ──────────────────────────────────────────────────────────

type s3Store struct {
	client *minio.Client
	bucket string
	prefix string
}

func (s *s3Store) Bucket() string { return s.bucket }
func (s *s3Store) Prefix() string { return s.prefix }

func (s *s3Store) Put(ctx context.Context, key string, data []byte, contentType string) error {
	_, err := s.client.PutObject(ctx, s.bucket, key, bytes.NewReader(data), int64(len(data)), minio.PutObjectOptions{ContentType: contentType})
	return err
}

func (s *s3Store) Get(ctx context.Context, key string) ([]byte, error) {
	obj, err := s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
	if err != nil {
		return nil, err
	}
	defer obj.Close()
	data, err := io.ReadAll(obj)
	if minio.ToErrorResponse(err).Code == "NoSuchKey" {
		return nil, ErrMissing
	}
	return data, err
}

func (s *s3Store) Copy(ctx context.Context, src, dst string) error {
	_, err := s.client.CopyObject(ctx, minio.CopyDestOptions{Bucket: s.bucket, Object: dst}, minio.CopySrcOptions{Bucket: s.bucket, Object: src})
	if minio.ToErrorResponse(err).Code == "NoSuchKey" {
		return ErrMissing
	}
	return err
}

func (s *s3Store) SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error) {
	u, err := s.client.PresignedGetObject(ctx, s.bucket, key, ttl, nil)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

func (s *s3Store) Delete(ctx context.Context, key string) error {
	return s.client.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}

func (s *s3Store) List(ctx context.Context, prefix string) ([]Object, error) {
	var out []Object
	for obj := range s.client.ListObjects(ctx, s.bucket, minio.ListObjectsOptions{Prefix: prefix, Recursive: true}) {
		if obj.Err != nil {
			return nil, obj.Err
		}
		if !strings.HasSuffix(obj.Key, "/") {
			out = append(out, Object{Key: obj.Key, Created: obj.LastModified})
		}
	}
	return out, nil
}
