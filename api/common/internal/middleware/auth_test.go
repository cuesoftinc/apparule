package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

// testWebURL is the single origin cookie-authenticated requests may come from.
const testWebURL = "https://app.example.com"

func testConfig() *config.Config {
	return &config.Config{WebURL: testWebURL}
}

func requestWith(origin, site string) *http.Request {
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	if origin != "" {
		req.Header.Set("Origin", origin)
	}
	if site != "" {
		req.Header.Set("Sec-Fetch-Site", site)
	}
	return req
}

func TestCookieRequestAllowedAcceptsTheWebApp(t *testing.T) {
	cfg := testConfig()
	cases := []struct {
		name   string
		origin string
		site   string
		want   bool
	}{
		{"web origin, same-origin", testWebURL, "same-origin", true},
		{"web origin, same-site", testWebURL, "same-site", true},
		{"web origin, no fetch metadata", testWebURL, "", true},
		{"no origin, same-origin", "", "same-origin", true},
		{"foreign origin is rejected", "https://evil.example.com", "cross-site", false},
		{"sibling origin is rejected", "https://second.example.com", "same-site", false},
		{"missing headers is rejected", "", "", false},
		{"no origin, cross-site is rejected", "", "cross-site", false},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := CookieRequestAllowed(cfg, requestWith(c.origin, c.site)); got != c.want {
				t.Fatalf("CookieRequestAllowed = %v, want %v (origin=%q site=%q)", got, c.want, c.origin, c.site)
			}
		})
	}
}
