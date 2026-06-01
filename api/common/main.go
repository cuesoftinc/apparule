package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	// 1. Production Best Practice: Read settings from system environment variables
	configPath := os.Getenv("FIREBASE_CONFIG_PATH")
	if configPath == "" {
		// Fallback to our local sandbox file for seamless development
		configPath = "firebase-secrets.json"
		log.Println("[Init] WARNING: FIREBASE_CONFIG_PATH env variable not found. Defaulting to local sandbox file.")
	}

	// 2. Initialize our Authentication Layer with the configuration path
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