// Command server is the entrypoint for the Apparule common (auth + core) API.
package main

import (
	"log/slog"
	"os"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/server"
)

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))

	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	authSvc, err := auth.New(cfg)
	if err != nil {
		slog.Error("failed to initialize auth", "error", err)
		os.Exit(1)
	}

	if err := server.New(cfg, authSvc).Run(); err != nil {
		slog.Error("server error", "error", err)
		os.Exit(1)
	}
}
