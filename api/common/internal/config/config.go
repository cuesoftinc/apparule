// Package config is the typed environment config (CueLABS standard: fail
// fast on missing settings). Names follow docs/system-design.md §10.3.
// Nothing else in the service reads the environment.
package config

import (
	"crypto/ed25519"
	"encoding/base64"
	"errors"
	"fmt"
	"net/url"
	"os"
	"slices"
	"sort"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port        string
	CORSOrigins []string
	DatabaseURL string

	Kafka   Kafka
	Redis   Redis
	Storage Storage
	Wake    Wake

	// WebURL is where the browser lands after Google sign-in (the web app).
	WebURL string
	// AppReturnURLs are the exact mobile return URLs sign-in may hand back to.
	AppReturnURLs []string
	Auth          Auth

	Ticket Ticket
	// UploadsURL is the public URL of POST /api/v1/uploads, returned with
	// every ticket so clients needn't know the routing (§7.1).
	UploadsURL string

	Paystack Paystack

	Limits Limits

	// Cloud Scheduler OIDC for POST /internal/jobs/{name}: unset fails closed.
	SchedulerAudience     string
	SchedulerInvokerEmail string
}

// Auth is Google SSO plus the API's own session: Google proves the identity,
// the API signs the session token with JWTSecret and seals handoffs with
// SessionSecret. Required by the server only (RequireAuth).
type Auth struct {
	GoogleClientID     string
	GoogleClientSecret string
	GoogleRedirectURI  string
	JWTSecret          string
	// JWTAccessTTL is the session token and cookie lifetime.
	JWTAccessTTL      time.Duration
	SessionSecret     string
	SessionCookieName string
	OAuthStateCookie  string

	// SSO start limits (per source and global), and the proxy hops trusted
	// when reading the caller's address from X-Forwarded-For.
	StartSourceRate    int
	StartGlobalRate    int
	StartSourcePending int
	StartGlobalPending int
	TrustedProxyHops   int
}

type Kafka struct {
	Brokers  []string
	Username string
	Password string
	SSLCA    string
}

// Wake holds the base URLs of the services to wake after publishing for
// them (scale to zero, shared-messaging.md). Empty where every service
// always runs (compose, Helm).
type Wake struct {
	Common       string // used by the jobs: they wake common while work is pending
	Segmentation string
	Commerce     string
}

type Redis struct {
	Host     string
	Port     string
	Username string
	Password string
	TLS      bool
	DB       int

	// KeyPrefix leads every key: the Valkey ACL allows apparule:* only.
	KeyPrefix string
}

type Storage struct {
	Driver    string // gcs | s3
	Bucket    string
	Prefix    string // e.g. apparule/stg
	Endpoint  string
	AccessKey string
	SecretKey string
	UseSSL    bool
}

type Ticket struct {
	KeyID      string
	PrivateKey ed25519.PrivateKey
	TTL        time.Duration
}

// Paystack: common verifies webhook signatures with the secret key and
// hands the public key to clients for checkout (§8 "Money").
type Paystack struct {
	SecretKey string
	PublicKey string
}

// Limits are enforced before a ticket exists (engineering.md §3, §8).
type Limits struct {
	ImageMaxBytes    int64
	UploadBytesDay   int64
	CapturesPerMin   int
	CapturesPerDay   int
	SocialPerMin     int
	CommentsPerMin   int
	RequestsPerDay   int
	OpenRequests     int
	PostsPerDay      int
	ProcessingResend time.Duration
	ProcessingFail   time.Duration
}

// Load reads the environment; it returns every missing setting at once.
func Load() (*Config, error) {
	var missing []string
	need := func(name string) string {
		v := strings.TrimSpace(os.Getenv(name))
		if v == "" {
			missing = append(missing, name)
		}
		return v
	}

	cfg := &Config{
		Port:        or(os.Getenv("PORT"), "8080"),
		CORSOrigins: split(or(os.Getenv("CORS_ORIGINS"), "http://localhost:3000")),
		DatabaseURL: need("DATABASE_URL"),
		UploadsURL:  or(os.Getenv("UPLOADS_URL"), "/api/v1/uploads"),

		SchedulerAudience:     strings.TrimRight(strings.TrimSpace(os.Getenv("SCHEDULER_AUDIENCE")), "/"),
		SchedulerInvokerEmail: strings.TrimSpace(os.Getenv("SCHEDULER_INVOKER_EMAIL")),
		Kafka: Kafka{
			Brokers:  split(need("KAFKA_BROKERS")),
			Username: os.Getenv("KAFKA_USERNAME"),
			Password: os.Getenv("KAFKA_PASSWORD"),
			SSLCA:    os.Getenv("KAFKA_SSL_CA"),
		},
		Redis: Redis{
			Host:     os.Getenv("REDIS_HOST"),
			Port:     or(os.Getenv("REDIS_PORT"), "6379"),
			Username: os.Getenv("REDIS_USERNAME"),
			Password: os.Getenv("REDIS_PASSWORD"),
			TLS:      os.Getenv("REDIS_TLS") == "true",
			DB:       atoi(os.Getenv("REDIS_DB"), 0),

			KeyPrefix: strings.Trim(or(os.Getenv("REDIS_KEY_PREFIX"), "apparule"), ":"),
		},
		Storage: Storage{
			Driver:    or(os.Getenv("STORAGE_DRIVER"), "gcs"),
			Bucket:    need("STORAGE_BUCKET"),
			Prefix:    strings.TrimRight(need("STORAGE_PREFIX"), "/"),
			Endpoint:  os.Getenv("STORAGE_ENDPOINT"),
			AccessKey: os.Getenv("STORAGE_ACCESS_KEY"),
			SecretKey: os.Getenv("STORAGE_SECRET_KEY"),
			UseSSL:    os.Getenv("STORAGE_USE_SSL") != "false",
		},
		Wake: Wake{
			Common:       strings.TrimSpace(os.Getenv("WAKE_COMMON_URL")),
			Segmentation: strings.TrimSpace(os.Getenv("WAKE_SEGMENTATION_URL")),
			Commerce:     strings.TrimSpace(os.Getenv("WAKE_COMMERCE_URL")),
		},
		Paystack: Paystack{
			SecretKey: strings.TrimSpace(os.Getenv("PAYSTACK_SECRET_KEY")),
			PublicKey: strings.TrimSpace(os.Getenv("PAYSTACK_PUBLIC_KEY")),
		},
		Limits: Limits{
			ImageMaxBytes:    10 << 20, // flows/vault.md §1, pages.md B5
			UploadBytesDay:   int64(atoi(os.Getenv("UPLOAD_BYTES_PER_DAY"), 100<<20)),
			CapturesPerMin:   10,
			CapturesPerDay:   100,
			SocialPerMin:     60,
			CommentsPerMin:   10,
			RequestsPerDay:   20,
			OpenRequests:     10,
			PostsPerDay:      20,
			ProcessingResend: 60 * time.Second,
			ProcessingFail:   180 * time.Second,
		},
	}

	webURL := "http://localhost:3000"
	if len(cfg.CORSOrigins) > 0 {
		webURL = cfg.CORSOrigins[0]
	}
	cfg.WebURL = strings.TrimRight(or(os.Getenv("WEB_URL"), webURL), "/")
	cfg.AppReturnURLs = split(or(os.Getenv("APP_RETURN_URLS"), "apparule://app"))
	cfg.Auth = Auth{
		GoogleClientID:     strings.TrimSpace(os.Getenv("GOOGLE_CLIENT_ID")),
		GoogleClientSecret: strings.TrimSpace(os.Getenv("GOOGLE_CLIENT_SECRET")),
		GoogleRedirectURI:  or(os.Getenv("GOOGLE_REDIRECT_URI"), "http://localhost:8080/api/v1/auth/sso/google/callback"),
		JWTSecret:          os.Getenv("JWT_SECRET"),
		JWTAccessTTL:       jwtAccessTTL(),
		SessionSecret:      os.Getenv("SESSION_SECRET"),
		SessionCookieName:  or(os.Getenv("SESSION_COOKIE_NAME"), "apparule_session"),
		OAuthStateCookie:   or(os.Getenv("OAUTH_STATE_COOKIE"), "apparule_oauth_state"),

		StartSourceRate:    atoi(os.Getenv("SSO_START_SOURCE_RATE_LIMIT"), 10),
		StartGlobalRate:    atoi(os.Getenv("SSO_START_GLOBAL_RATE_LIMIT"), 300),
		StartSourcePending: atoi(os.Getenv("SSO_STATE_SOURCE_LIMIT"), 20),
		StartGlobalPending: atoi(os.Getenv("SSO_STATE_GLOBAL_LIMIT"), 2000),
		TrustedProxyHops:   atoi(os.Getenv("TRUSTED_PROXY_HOPS"), 0),
	}

	if cfg.Storage.Driver != "gcs" && cfg.Storage.Driver != "s3" {
		missing = append(missing, "STORAGE_DRIVER (gcs|s3)")
	}
	if cfg.Storage.Driver == "s3" && cfg.Storage.Endpoint == "" {
		missing = append(missing, "STORAGE_ENDPOINT")
	}

	ticket, err := parseTicketKey(need("UPLOAD_TICKET_PRIVATE_KEY"))
	if err != nil && !errors.Is(err, errEmpty) {
		missing = append(missing, "UPLOAD_TICKET_PRIVATE_KEY ("+err.Error()+")")
	}
	cfg.Ticket = ticket

	if len(missing) > 0 {
		return nil, fmt.Errorf("missing or invalid configuration: %s", strings.Join(missing, ", "))
	}
	return cfg, nil
}

// RequireAuth fails fast on the settings Google sign-in cannot run without.
func (c *Config) RequireAuth() error {
	var missing []string
	for name, v := range map[string]string{
		"GOOGLE_CLIENT_ID": c.Auth.GoogleClientID, "GOOGLE_CLIENT_SECRET": c.Auth.GoogleClientSecret,
		"JWT_SECRET": c.Auth.JWTSecret, "SESSION_SECRET": c.Auth.SessionSecret,
	} {
		if v == "" {
			missing = append(missing, name)
		}
	}
	sort.Strings(missing)
	if a := c.Auth; a.StartSourceRate < 1 || a.StartGlobalRate < 1 || a.StartSourcePending < 1 || a.StartGlobalPending < 1 ||
		a.StartSourceRate > a.StartGlobalRate || a.StartSourcePending > a.StartGlobalPending {
		missing = append(missing, "SSO start limits (positive, source at most global)")
	}
	if a := c.Auth; a.JWTAccessTTL <= 0 {
		missing = append(missing, "JWT_ACCESS_TTL (positive duration)")
	}
	if len(missing) > 0 {
		return fmt.Errorf("missing or invalid configuration: %s", strings.Join(missing, ", "))
	}
	return nil
}

// SecureCookies is true when the web app is served over https.
func (c *Config) SecureCookies() bool { return strings.HasPrefix(c.WebURL, "https://") }

// IsAllowedOrigin reports whether origin is the web app or a CORS origin.
func (c *Config) IsAllowedOrigin(origin string) bool {
	origin = strings.TrimRight(origin, "/")
	return origin != "" && (origin == c.WebURL || slices.Contains(c.CORSOrigins, origin))
}

// IsAppReturnURL reports whether raw is exactly one of the mobile return URLs.
func (c *Config) IsAppReturnURL(raw string) bool {
	return raw != "" && slices.Contains(c.AppReturnURLs, raw)
}

// IsAllowedRedirectURL accepts a mobile return URL or an absolute URL on an
// allowed origin.
func (c *Config) IsAllowedRedirectURL(raw string) bool {
	if c.IsAppReturnURL(raw) {
		return true
	}
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" || (u.Scheme != "https" && u.Scheme != "http") || u.User != nil {
		return false
	}
	return c.IsAllowedOrigin(u.Scheme + "://" + u.Host)
}

// jwtAccessTTL reads JWT_ACCESS_TTL as a duration, falling back to the legacy
// JWT_EXPIRY_HOURS and then to 24h.
func jwtAccessTTL() time.Duration {
	if raw := strings.TrimSpace(os.Getenv("JWT_ACCESS_TTL")); raw != "" {
		d, err := time.ParseDuration(raw)
		if err != nil {
			return 0
		}
		return d
	}
	if hours := atoi(os.Getenv("JWT_EXPIRY_HOURS"), 0); hours > 0 {
		return time.Duration(hours) * time.Hour
	}
	return 24 * time.Hour
}

var errEmpty = errors.New("empty")

// parseTicketKey reads kid:<base64url 32-byte Ed25519 seed>.
func parseTicketKey(raw string) (Ticket, error) {
	if raw == "" {
		return Ticket{}, errEmpty
	}
	kid, encoded, ok := strings.Cut(raw, ":")
	seed, err := base64.RawURLEncoding.DecodeString(strings.TrimRight(encoded, "="))
	if !ok || kid == "" || err != nil || len(seed) != ed25519.SeedSize {
		return Ticket{}, errors.New("want kid:<base64url 32-byte seed>")
	}
	return Ticket{KeyID: kid, PrivateKey: ed25519.NewKeyFromSeed(seed), TTL: 5 * time.Minute}, nil
}

func or(v, fallback string) string {
	if strings.TrimSpace(v) == "" {
		return fallback
	}
	return strings.TrimSpace(v)
}

func split(v string) []string {
	var out []string
	for _, s := range strings.Split(v, ",") {
		if s = strings.TrimSpace(s); s != "" {
			out = append(out, s)
		}
	}
	return out
}

func atoi(v string, fallback int) int {
	if n, err := strconv.Atoi(strings.TrimSpace(v)); err == nil {
		return n
	}
	return fallback
}
