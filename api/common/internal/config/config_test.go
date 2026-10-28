package config

import (
	"testing"
	"time"
)

func TestJWTAccessTTL(t *testing.T) {
	tests := []struct {
		name       string
		ttl, hours string
		want       time.Duration
	}{
		{"default", "", "", 24 * time.Hour},
		{"legacy hours", "", "2", 2 * time.Hour},
		{"ttl wins", "15m", "2", 15 * time.Minute},
		{"invalid ttl", "soon", "", 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("JWT_ACCESS_TTL", tt.ttl)
			t.Setenv("JWT_EXPIRY_HOURS", tt.hours)
			if got := jwtAccessTTL(); got != tt.want {
				t.Fatalf("ttl = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestAllowedOrigins(t *testing.T) {
	c := &Config{WebURL: "https://app.example.com", CORSOrigins: []string{"https://other.example.com"}, AppReturnURLs: []string{"apparule://app"}}
	for raw, want := range map[string]bool{
		"apparule://app":                 true,
		"apparule://app/x":               false,
		"apparule://evil":                false,
		"other://app":                    false,
		"https://app.example.com/x":      true,
		"https://other.example.com":      true,
		"https://evil.example.com/x":     false,
		"https://user@app.example.com/x": false,
		"javascript:alert(1)":            false,
		"/relative":                      false,
	} {
		if got := c.IsAllowedRedirectURL(raw); got != want {
			t.Errorf("IsAllowedRedirectURL(%q) = %v, want %v", raw, got, want)
		}
	}
	if !c.SecureCookies() {
		t.Fatal("https web app must use secure cookies")
	}
}
