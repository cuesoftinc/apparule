// Package storage is object storage (system-design.md §5.1): GCS in cloud
// via ADC, any S3-compatible store (MinIO) for compose and self-host.
// api/common moves images out of tmp/ when they are kept (§6.2), and owns
// captures/, media/, attachments/, exports/ and compute/. media/ holds
// published post images and is publicly readable; everything else is
// reached through short-lived signed URLs.
package storage

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
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
	// PublicURL is the permanent URL of an object under media/.
	PublicURL(key string) string
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
		// Published post images are public, as in cloud (§5.1).
		policy := fmt.Sprintf(`{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["*"]},`+
			`"Action":["s3:GetObject"],"Resource":["arn:aws:s3:::%s/%s/media/*"]}]}`, cfg.Bucket, cfg.Prefix)
		// Not every S3 stand-in takes bucket policies (SeaweedFS grants public
		// reads in its own config); a refusal only affects local image URLs.
		if err := client.SetBucketPolicy(ctx, cfg.Bucket, policy); err != nil {
			slog.Warn("bucket policy not applied; media/ may not be public", "error", err)
		}
		public := cfg.PublicBaseURL
		if public == "" {
			scheme := "http"
			if cfg.UseSSL {
				scheme = "https"
			}
			public = fmt.Sprintf("%s://%s/%s", scheme, cfg.Endpoint, cfg.Bucket)
		}
		return &s3Store{client: client, bucket: cfg.Bucket, prefix: cfg.Prefix, public: strings.TrimRight(public, "/")}, nil
	}
	client, err := gcs.NewClient(ctx)
	if err != nil {
		return nil, err
	}
	public := cfg.PublicBaseURL
	if public == "" {
		public = "https://storage.googleapis.com/" + cfg.Bucket
	}
	return &gcsStore{bucket: client.Bucket(cfg.Bucket), name: cfg.Bucket, prefix: cfg.Prefix, public: strings.TrimRight(public, "/")}, nil
}

// TmpPrefix is where api/uploads writes images.
func TmpPrefix(s Store) string { return s.Prefix() + "/tmp/" }

// ComputePrefix holds claim-check payloads of bus messages.
func ComputePrefix(s Store) string { return s.Prefix() + "/compute/" }

// ── GCS ─────────────────────────────────────────────────────────────────

type gcsStore struct {
	bucket *gcs.BucketHandle
	name   string
	prefix string
	public string
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

func (s *gcsStore) PublicURL(key string) string { return s.public + "/" + key }

// ── S3 / MinIO ──────────────────────────────────────────────────────────

type s3Store struct {
	client *minio.Client
	bucket string
	prefix string
	public string
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

func (s *s3Store) PublicURL(key string) string { return s.public + "/" + key }

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
