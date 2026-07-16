// Package config loads runtime configuration from the environment.
package config

import (
	"errors"
	"os"
	"strings"
)

// Config holds runtime configuration sourced from environment variables.
type Config struct {
	Port               string
	JWTSecret          string
	FirebaseConfigPath string
	ProjectID          string
	AllowedOrigins     []string
}

// Load reads configuration from the environment, applying local-dev defaults.
func Load() (*Config, error) {
	c := &Config{
		Port:               getenv("PORT", "8080"),
		JWTSecret:          os.Getenv("JWT_SECRET"),
		FirebaseConfigPath: os.Getenv("FIREBASE_CONFIG_PATH"),
		ProjectID:          firstNonEmpty(os.Getenv("GOOGLE_CLOUD_PROJECT"), os.Getenv("GCP_PROJECT")),
		AllowedOrigins:     splitCSV(getenv("CORS_ORIGINS", "http://localhost:3000")),
	}

	// Fail fast rather than fall back to a baked-in secret: a hard-coded
	// default would make every token forgeable in any environment that
	// forgot to set JWT_SECRET.
	if c.JWTSecret == "" {
		return nil, errors.New("JWT_SECRET is required (set it in the environment or .env)")
	}

	// Local-dev comfort (migrated from the original main.go): if neither a
	// config path nor a project id is set, fall back to a local file.
	if c.FirebaseConfigPath == "" && c.ProjectID == "" {
		c.FirebaseConfigPath = "firebase-secrets.json"
	}
	return c, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}

func splitCSV(s string) []string {
	out := make([]string, 0)
	for _, p := range strings.Split(s, ",") {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}
