// Package router maps the HTTP surface (system-design.md §7). Paths follow
// the web contract (web/src/app/api/mock/v1, web/src/models/repositories)
// under /api/v1; POST /api/v1/uploads belongs to api/uploads.
package router

import (
	"context"
	"net/http"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/handler"
	"github.com/cuesoftinc/apparule/api/common/internal/middleware"
)

// Readiness reports whether the instance can serve: Postgres reachable,
// consumers running.
type Readiness func(ctx context.Context) error

func New(h *handler.Handlers, sso *handler.AuthHandler, auth func(http.Handler) http.Handler, corsOrigins []string, ready Readiness, jobs *handler.Jobs) http.Handler {
	api := http.NewServeMux()
	routes := map[string]http.HandlerFunc{
		"GET /api/v1/me":                    h.Me,
		"PATCH /api/v1/me":                  h.UpdateMe,
		"GET /api/v1/me/export":             h.ExportData,
		"POST /api/v1/me/deletion":          h.RequestDeletion,
		"GET /api/v1/me/saved":              h.Saved,
		"POST /api/v1/me/devices":           h.SetDevice,
		"DELETE /api/v1/me/devices/{token}": h.RemoveDevice,
		"GET /api/v1/consent":               h.Consent,
		"POST /api/v1/consent":              h.RecordConsent,
		"GET /api/v1/instance-requests":     h.InstanceRequests,
		"POST /api/v1/instance-requests":    h.RequestInstance,

		// The vault (data-model.md §6.1) and asynchronous capture (§6.1).
		"GET /api/v1/me/sessions":                        h.Sessions,
		"POST /api/v1/me/sessions":                       h.CreateSession,
		"GET /api/v1/sessions/{id}":                      h.Session,
		"DELETE /api/v1/sessions/{id}":                   h.DeleteSession,
		"POST /api/v1/sessions/{id}/save":                h.SaveSession,
		"POST /api/v1/sessions/{id}/poses/{pose}/ticket": h.RetakeTicket,
		"PATCH /api/v1/sessions/{id}/measurements":       h.Corrections,
		"POST /api/v1/sessions/{id}/exports":             h.ExportSession,

		// Social.
		"GET /api/v1/feed":                          h.Feed,
		"GET /api/v1/explore":                       h.Explore,
		"POST /api/v1/posts":                        h.CreatePost,
		"GET /api/v1/posts/{id}":                    h.Post,
		"DELETE /api/v1/posts/{id}":                 h.DeletePost,
		"POST /api/v1/posts/{id}/like":              h.Like(true),
		"DELETE /api/v1/posts/{id}/like":            h.Like(false),
		"POST /api/v1/posts/{id}/save":              h.Save(true),
		"DELETE /api/v1/posts/{id}/save":            h.Save(false),
		"GET /api/v1/posts/{id}/comments":           h.Comments,
		"POST /api/v1/posts/{id}/comments":          h.AddComment,
		"POST /api/v1/follows/{designer}":           h.Follow(true),
		"DELETE /api/v1/follows/{designer}":         h.Follow(false),
		"POST /api/v1/blocks/{account}":             h.Block(true),
		"DELETE /api/v1/blocks/{account}":           h.Block(false),
		"GET /api/v1/profiles/{username}":           h.Profile,
		"GET /api/v1/profiles/{username}/posts":     h.ProfilePosts,
		"GET /api/v1/profiles/{username}/followers": h.Followers,
		"GET /api/v1/profiles/{username}/following": h.Following,
		"GET /api/v1/designers":                     h.SearchDesigners,
		"GET /api/v1/designers/suggested":           h.SuggestedDesigners,
		"POST /api/v1/media/tickets":                h.StartPostMedia,
		"GET /api/v1/media/batches/{id}":            h.MediaBatch,

		// Orders (order-lifecycle.md).
		"GET /api/v1/requests":                           h.Orders,
		"POST /api/v1/posts/{id}/requests":               h.CreateRequest,
		"GET /api/v1/requests/{id}":                      h.Order,
		"POST /api/v1/requests/{id}/cancel":              h.Cancel,
		"POST /api/v1/requests/{id}/quote":               h.Quote,
		"POST /api/v1/requests/{id}/decline":             h.Decline,
		"POST /api/v1/requests/{id}/status":              h.SetStatus,
		"POST /api/v1/requests/{id}/pay":                 h.Pay,
		"POST /api/v1/requests/{id}/confirm-delivery":    h.ConfirmDelivery,
		"POST /api/v1/requests/{id}/dispute":             h.Dispute,
		"GET /api/v1/requests/{id}/messages":             h.Messages,
		"POST /api/v1/requests/{id}/messages":            h.AddMessage,
		"POST /api/v1/requests/{id}/attachments/tickets": h.StartAttachment,

		// Designer.
		"POST /api/v1/designer-profile":                h.EnableDesigner,
		"GET /api/v1/designer/earnings":                h.Earnings,
		"GET /api/v1/designer/payout-account":          h.PayoutAccount,
		"POST /api/v1/designer/payout-account":         h.SubmitPayoutAccount,
		"POST /api/v1/designer/payout-account/resolve": h.SubmitPayoutAccount,

		// Notifications, trust and safety.
		"GET /api/v1/notifications":                     h.Notifications,
		"POST /api/v1/notifications/read":               h.MarkRead,
		"POST /api/v1/reports":                          h.FileReport,
		"GET /api/v1/moderation/queue":                  h.ModerationQueue,
		"POST /api/v1/moderation/reports/{id}/action":   h.ActOnReport,
		"POST /api/v1/moderation/requests/{id}/resolve": h.ResolveDispute,
	}
	for pattern, fn := range routes {
		api.Handle(pattern, fn)
	}

	root := http.NewServeMux()
	root.HandleFunc("GET /health", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status":"healthy"}`))
	})
	root.HandleFunc("GET /ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()
		w.Header().Set("Content-Type", "application/json")
		if err := ready(ctx); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			_, _ = w.Write([]byte(`{"status":"not_ready"}`))
			return
		}
		_, _ = w.Write([]byte(`{"status":"ready"}`))
	})
	// Sign-in is public: the session does not exist yet.
	if sso != nil {
		root.HandleFunc("GET /api/v1/auth/sso/google", sso.GoogleLogin)
		root.HandleFunc("GET /api/v1/auth/sso/google/callback", sso.GoogleCallback)
		root.HandleFunc("POST /api/v1/auth/sso/exchange", sso.ExchangeSSOHandoff)
		root.HandleFunc("POST /api/v1/auth/logout", sso.Logout)
	}
	// Paystack signs its webhooks; no user token (S-12).
	root.HandleFunc("POST /webhooks/payments", h.PaymentsWebhook)
	// Cloud Scheduler signs an OIDC token; no user token.
	root.Handle("POST /internal/jobs/{name}", jobs.Guard(http.HandlerFunc(jobs.Handle)))
	root.Handle("/api/v1/", auth(api))

	return middleware.Chain(root, middleware.Recover, middleware.RequestID, middleware.Logger, middleware.CORS(corsOrigins))
}
