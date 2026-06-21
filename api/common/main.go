package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	// Read settings from system environment variables
	configPath := os.Getenv("FIREBASE_CONFIG_PATH")
	
	// Local development comfort: If running locally without env vars, look for the file.
	// But if we are in production on Cloud Run, GOOGLE_CLOUD_PROJECT will exist, so we skip forcing the file!
	if configPath == "" && os.Getenv("GOOGLE_CLOUD_PROJECT") == "" && os.Getenv("GCP_PROJECT") == "" {
		configPath = "firebase-secrets.json"
		log.Println("[Init] WARNING: FIREBASE_CONFIG_PATH not found. Defaulting to local sandbox file.")
	}

	// Initialize our Authentication Layer (handles both local paths and Cloud Run ADC)
	err := InitializeAuth(configPath)
	if err != nil {
		log.Fatalf("[Init] Critical Error initializing authentication infrastructure: %v", err)
	}

	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", handleHealth)
	mux.HandleFunc("POST /api/auth/google", handleGoogleLogin)
	mux.HandleFunc("POST /api/auth/email", handleEmailLogin)

	log.Println("Apparule Core Engine running cleanly on http://localhost:8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy","message":"Apparule Backend Core running smoothly (Production-Ready)"}`))
}