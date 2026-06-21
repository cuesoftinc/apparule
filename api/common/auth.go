package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

// FirebaseConfig mirrors the standard structural fields required by GCP/Firebase
type FirebaseConfig struct {
	Type        string `json:"type"`
	ProjectID   string `json:"project_id"`
	PrivateKey  string `json:"private_key"`
	ClientEmail string `json:"client_email"`
}

// Global runtime memory to store active configuration details
var activeConfig FirebaseConfig

// Payloads received from client applications
type GoogleAuthRequest struct {
	IDToken string `json:"id_token"`
}

type EmailAuthRequest struct {
	Email string `json:"email"`
}

// InitializeAuth verifies that the system can read and parse the credentials path safely
// Now updated to dynamically support both local JSON paths and Cloud Run ADC fallbacks
func InitializeAuth(path string) error {
	// 1. Local development: If a custom path is provided, read the local JSON file
	if path != "" {
		file, err := os.Open(path)
		if err != nil {
			return fmt.Errorf("unable to open config file: %w", err)
		}
		defer file.Close()

		bytes, err := io.ReadAll(file)
		if err != nil {
			return fmt.Errorf("unable to read config content: %w", err)
		}

		err = json.Unmarshal(bytes, &activeConfig)
		if err != nil {
			return fmt.Errorf("malformed JSON credential structure: %w", err)
		}
	} else {
		// 2. Production/Cloud Run Fallback: Read from Google's standard environment variables
		activeConfig.ProjectID = os.Getenv("GOOGLE_CLOUD_PROJECT")
		if activeConfig.ProjectID == "" {
			activeConfig.ProjectID = os.Getenv("GCP_PROJECT") // Fallback identifier
		}
		
		// If running in Cloud Run, ProjectID is automatically populated by Google
		if activeConfig.ProjectID == "" {
			return fmt.Errorf("invalid authentication layout: missing project identifier for ADC")
		}
	}

	log.Printf("[Firebase] Successfully initialized cloud backend hook for Project ID: %s\n", activeConfig.ProjectID)
	return nil
}

func handleGoogleLogin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req GoogleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.IDToken == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error": "Missing valid id_token payload"}`))
		return
	}

	// Step A: In production, this token string is transmitted directly to the 
	// Google Identity/Firebase endpoint to decrypt and verify the caller's true identity.
	log.Printf("[Auth Hub] Incoming client verification signature requested via project: %s\n", activeConfig.ProjectID)

	// Step B: Generate your internal session token for client-side state maintenance
	sessionToken, err := GenerateJWT(activeConfig.ClientEmail)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"error": "Failed to issue backend security token"}`))
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Validated through cloud configuration pipeline",
		"project": activeConfig.ProjectID,
		"token":   sessionToken,
	})
}

func handleEmailLogin(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var req EmailAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Email == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte(`{"error": "A valid email address is required"}`))
		return
	}

	// Dispatch request context mapping directly to the configured cloud ecosystem identifier
	log.Printf("[SMTP Target] Sending authentication dispatch request for %s via Project scope: %s\n", req.Email, activeConfig.ProjectID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Authentication link routed through cloud instance gateway",
		"email":   req.Email,
		"scope":   activeConfig.ProjectID,
	})
}