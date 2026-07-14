// Package server wires the router, middleware, and HTTP lifecycle.
package server

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/handler"
	"github.com/cuesoftinc/apparule/api/common/internal/middleware"
)

// Server wraps the HTTP server and its configuration.
type Server struct {
	http *http.Server
}

// New builds the router, wires middleware and routes, and returns a Server.
func New(cfg *config.Config, authSvc *auth.Service) *Server {
	gin.SetMode(gin.ReleaseMode)

	r := gin.New()
	r.Use(gin.Recovery(), middleware.RequestID(), middleware.Logger(), middleware.CORS(cfg.AllowedOrigins))

	r.GET("/health", handler.Health)
	r.GET("/ready", handler.Ready)

	ah := handler.NewAuthHandler(authSvc)
	authGroup := r.Group("/api/auth")
	{
		authGroup.POST("/google", ah.Google)
		authGroup.POST("/email", ah.Email)
	}

	return &Server{
		http: &http.Server{
			Addr:              ":" + cfg.Port,
			Handler:           r,
			ReadHeaderTimeout: 10 * time.Second,
		},
	}
}

// Run starts the server and blocks until a shutdown signal, then drains gracefully.
func (s *Server) Run() error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		slog.Info("server listening", "addr", s.http.Addr)
		if err := s.http.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("listen error", "error", err)
			stop()
		}
	}()

	<-ctx.Done()
	slog.Info("shutting down")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return s.http.Shutdown(shutdownCtx)
}
