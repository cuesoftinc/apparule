// Package app wires config into dependencies once, for cmd/server and
// cmd/jobs alike.
package app

import (
	"context"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/config"
	"github.com/cuesoftinc/apparule/api/common/internal/kafka"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
	"github.com/cuesoftinc/apparule/api/common/internal/storage"
	"github.com/cuesoftinc/apparule/api/common/internal/ticket"
)

type App struct {
	Config   *config.Config
	DB       *repository.DB
	Store    storage.Store
	Limiter  *ratelimit.Limiter
	Contract *kafka.Contract
	Services *service.Services
}

func New(ctx context.Context, cfg *config.Config) (*App, error) {
	db, err := repository.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return nil, err
	}
	store, err := storage.Open(ctx, cfg.Storage)
	if err != nil {
		return nil, err
	}
	contract, err := kafka.LoadContract()
	if err != nil {
		return nil, err
	}
	limiter := ratelimit.New(cfg.Redis)
	signer := ticket.NewSigner(cfg.Ticket.KeyID, cfg.Ticket.PrivateKey, cfg.Ticket.TTL)
	return &App{
		Config: cfg, DB: db, Store: store, Limiter: limiter, Contract: contract,
		Services: &service.Services{DB: db, Store: store, Tickets: signer, Limiter: limiter, Config: cfg, Now: time.Now},
	}, nil
}

func (a *App) Close() {
	a.DB.Close()
	_ = a.Limiter.Close()
}
