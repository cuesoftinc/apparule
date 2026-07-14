// Package auth holds authentication configuration and session-token logic.
//
// NOTE (flagged for the security PRD): the Google login path does not yet
// verify the incoming ID token against Firebase/Google, and the email path is
// a no-op dispatch. This behavior is migrated as-is from the original prototype;
// hardening (real token verification, single-use email links) is tracked
// separately.
package auth

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
)

// FirebaseConfig mirrors the structural fields required by GCP/Firebase.
type FirebaseConfig struct {
	Type        string `json:"type"`
	ProjectID   string `json:"project_id"`
	PrivateKey  string `json:"private_key"`
	ClientEmail string `json:"client_email"`
}

// Service carries the resolved Firebase configuration and JWT signing secret.
type Service struct {
	fb        FirebaseConfig
	jwtSecret []byte
}

// New resolves the Firebase configuration from a local JSON file or an ADC
// project id (migrated from the original InitializeAuth).
func New(cfg *config.Config) (*Service, error) {
	var fb FirebaseConfig

	if cfg.FirebaseConfigPath != "" {
		file, err := os.Open(cfg.FirebaseConfigPath)
		if err != nil {
			return nil, fmt.Errorf("unable to open config file: %w", err)
		}
		defer file.Close()

		bytes, err := io.ReadAll(file)
		if err != nil {
			return nil, fmt.Errorf("unable to read config content: %w", err)
		}
		if err := json.Unmarshal(bytes, &fb); err != nil {
			return nil, fmt.Errorf("malformed JSON credential structure: %w", err)
		}
	} else {
		fb.ProjectID = cfg.ProjectID
		if fb.ProjectID == "" {
			return nil, fmt.Errorf("invalid authentication layout: missing project identifier for ADC")
		}
	}

	slog.Info("firebase backend initialized", "project_id", fb.ProjectID)
	return &Service{fb: fb, jwtSecret: []byte(cfg.JWTSecret)}, nil
}

// ProjectID returns the resolved Firebase project id.
func (s *Service) ProjectID() string { return s.fb.ProjectID }

// GoogleLogin issues a session token for a Google sign-in.
//
// TODO(security-prd): verify idToken with Firebase/Google and issue the token
// for the verified user identity (not the service-account email).
func (s *Service) GoogleLogin(idToken string) (string, error) {
	slog.Info("google verification requested", "project_id", s.fb.ProjectID)
	// Refuse to mint a token with an empty identity (e.g. running on ADC
	// without a service-account JSON) — an empty email claim makes any
	// downstream authorization ambiguous.
	if s.fb.ClientEmail == "" {
		return "", errors.New("no service identity resolved; set FIREBASE_CONFIG_PATH (user-identity tokens tracked in security PRD)")
	}
	return s.GenerateJWT(s.fb.ClientEmail)
}

// EmailLogin routes an email authentication request.
//
// TODO(security-prd): dispatch a real single-use magic link / OTP server-side.
func (s *Service) EmailLogin(email string) {
	slog.Info("email auth dispatch", "email", email, "project_id", s.fb.ProjectID)
}
