package handler

import (
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strings"

	"github.com/cuesoftinc/apparule/api/common/internal/middleware"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
)

type Handlers struct {
	S *service.Services
}

func principal(r *http.Request) *service.Principal { return middleware.PrincipalFrom(r.Context()) }

// ── Accounts ────────────────────────────────────────────────────────────

func (h *Handlers) Me(w http.ResponseWriter, r *http.Request) {
	a, err := h.S.Me(r.Context(), principal(r))
	respond(w, r, http.StatusOK, a, err)
}

func (h *Handlers) UpdateMe(w http.ResponseWriter, r *http.Request) {
	var raw map[string]json.RawMessage
	if !decode(w, r, &raw) {
		return
	}
	var in service.MePatch
	for k, v := range raw {
		var err error
		switch k {
		case "username":
			err = json.Unmarshal(v, &in.Username)
		case "display_name":
			err = json.Unmarshal(v, &in.DisplayName)
		case "profile_location":
			if string(v) == "null" {
				in.ClearLocation = true
			} else {
				err = json.Unmarshal(v, &in.ProfileLocation)
			}
		case "notification_prefs":
			err = json.Unmarshal(v, &in.NotificationPrefs)
		case "measurement_template":
			in.TemplateSet = true
			err = json.Unmarshal(v, &in.MeasurementTemplate)
		}
		if err != nil {
			writeError(w, http.StatusUnprocessableEntity, "validation_failed", "Invalid "+k, nil)
			return
		}
	}
	a, err := h.S.UpdateMe(r.Context(), principal(r), in)
	respond(w, r, http.StatusOK, a, err)
}

func (h *Handlers) Consent(w http.ResponseWriter, r *http.Request) {
	c, err := h.S.Consent(r.Context(), principal(r))
	respond(w, r, http.StatusOK, c, err)
}

func (h *Handlers) RecordConsent(w http.ResponseWriter, r *http.Request) {
	var in struct{ Document, Version string }
	if !decode(w, r, &in) {
		return
	}
	c, err := h.S.RecordConsent(r.Context(), principal(r), in.Document, in.Version)
	respond(w, r, http.StatusCreated, c, err)
}

func (h *Handlers) ExportData(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.ExportData(r.Context(), principal(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) RequestDeletion(w http.ResponseWriter, r *http.Request) {
	a, err := h.S.RequestDeletion(r.Context(), principal(r))
	respond(w, r, http.StatusOK, a, err)
}

func (h *Handlers) SetDevice(w http.ResponseWriter, r *http.Request) {
	var in struct{ Token, Platform string }
	if !decode(w, r, &in) {
		return
	}
	noContent(w, r, h.S.SetDevice(r.Context(), principal(r), in.Token, in.Platform))
}

func (h *Handlers) RemoveDevice(w http.ResponseWriter, r *http.Request) {
	noContent(w, r, h.S.RemoveDevice(r.Context(), principal(r), r.PathValue("token")))
}

func (h *Handlers) EnableDesigner(w http.ResponseWriter, r *http.Request) {
	var in struct {
		DisplayName string `json:"display_name"`
		Bio         string `json:"bio"`
	}
	if !decode(w, r, &in) {
		return
	}
	d, err := h.S.EnableDesigner(r.Context(), principal(r), in.DisplayName, in.Bio)
	respond(w, r, http.StatusCreated, d, err)
}

func (h *Handlers) RequestInstance(w http.ResponseWriter, r *http.Request) {
	var in struct{ Notes string }
	if !decode(w, r, &in) {
		return
	}
	out, err := h.S.RequestInstance(r.Context(), principal(r), in.Notes)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) InstanceRequests(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.InstanceRequests(r.Context(), principal(r))
	if out == nil {
		out = []model.InstanceRequest{}
	}
	respond(w, r, http.StatusOK, map[string]any{"items": out, "next_cursor": nil}, err)
}

// ── The vault ───────────────────────────────────────────────────────────

func (h *Handlers) Sessions(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Sessions(r.Context(), principal(r), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

// CreateSession is POST /me/sessions: tape values (method manual) are
// stored at once; a capture (input_height_cm) is created awaiting its
// photos, which go to api/uploads with the returned ticket (§6.1).
func (h *Handlers) CreateSession(w http.ResponseWriter, r *http.Request) {
	if strings.HasPrefix(r.Header.Get("Content-Type"), "multipart/") {
		writeError(w, http.StatusUnprocessableEntity, "validation_failed",
			"Create the session with JSON, then upload the photos to /api/v1/uploads with its ticket", nil)
		return
	}
	var in struct {
		Method        string                `json:"method"`
		InputHeightCM *float64              `json:"input_height_cm"`
		Measurements  []service.ManualInput `json:"measurements"`
	}
	if !decode(w, r, &in) {
		return
	}
	key := r.Header.Get("Idempotency-Key")
	if in.Method == "manual" || (in.InputHeightCM == nil && len(in.Measurements) > 0) {
		s, err := h.S.CreateManualSession(r.Context(), principal(r), in.Measurements, key)
		respond(w, r, http.StatusCreated, s, err)
		return
	}
	if in.InputHeightCM == nil {
		writeError(w, http.StatusUnprocessableEntity, "validation_failed", "input_height_cm (capture) or measurements (manual) is required", nil)
		return
	}
	s, err := h.S.CreateCapture(r.Context(), principal(r), *in.InputHeightCM, key)
	respond(w, r, http.StatusCreated, s, err)
}

func (h *Handlers) Session(w http.ResponseWriter, r *http.Request) {
	s, err := h.S.Session(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, s, err)
}

func (h *Handlers) DeleteSession(w http.ResponseWriter, r *http.Request) {
	noContent(w, r, h.S.DeleteSession(r.Context(), principal(r), r.PathValue("id")))
}

func (h *Handlers) SaveSession(w http.ResponseWriter, r *http.Request) {
	s, err := h.S.SaveSession(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, s, err)
}

func (h *Handlers) RetakeTicket(w http.ResponseWriter, r *http.Request) {
	s, err := h.S.RetakeTicket(r.Context(), principal(r), r.PathValue("id"), r.PathValue("pose"))
	respond(w, r, http.StatusCreated, s, err)
}

func (h *Handlers) Corrections(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Measurements []service.ManualInput `json:"measurements"`
	}
	if !decode(w, r, &in) {
		return
	}
	s, err := h.S.AppendCorrections(r.Context(), principal(r), r.PathValue("id"), in.Measurements)
	respond(w, r, http.StatusOK, s, err)
}

func (h *Handlers) ExportSession(w http.ResponseWriter, r *http.Request) {
	var in struct{ Format string }
	if !decode(w, r, &in) {
		return
	}
	if in.Format == "" {
		in.Format = "csv"
	}
	out, err := h.S.ExportSession(r.Context(), principal(r), r.PathValue("id"), in.Format)
	respond(w, r, http.StatusCreated, out, err)
}

// ── Social ──────────────────────────────────────────────────────────────

func (h *Handlers) Feed(w http.ResponseWriter, r *http.Request) {
	pg := paging(r)
	out, err := h.S.Feed(r.Context(), principal(r), r.URL.Query().Get("cursor"), pg.Limit)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Explore(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	f := service.ExploreFilter(q.Get("q"), q.Get("tags"), q.Get("price_band"), q.Get("max_turnaround_days"), q.Get("near_me"))
	out, err := h.S.Explore(r.Context(), principal(r), f, q.Get("cursor"), paging(r).Limit)
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Post(w http.ResponseWriter, r *http.Request) {
	p, err := h.S.Post(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, p, err)
}

func (h *Handlers) CreatePost(w http.ResponseWriter, r *http.Request) {
	var in service.PostInput
	if !decode(w, r, &in) {
		return
	}
	p, err := h.S.CreatePost(r.Context(), principal(r), in)
	respond(w, r, http.StatusCreated, p, err)
}

func (h *Handlers) DeletePost(w http.ResponseWriter, r *http.Request) {
	noContent(w, r, h.S.DeletePost(r.Context(), principal(r), r.PathValue("id")))
}

func (h *Handlers) Like(on bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		noContent(w, r, h.S.SetLike(r.Context(), principal(r), r.PathValue("id"), on))
	}
}

func (h *Handlers) Save(on bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		noContent(w, r, h.S.SetSave(r.Context(), principal(r), r.PathValue("id"), on))
	}
}

func (h *Handlers) Comments(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Comments(r.Context(), principal(r), r.PathValue("id"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) AddComment(w http.ResponseWriter, r *http.Request) {
	var in struct{ Body string }
	if !decode(w, r, &in) {
		return
	}
	c, err := h.S.AddComment(r.Context(), principal(r), r.PathValue("id"), in.Body)
	respond(w, r, http.StatusCreated, c, err)
}

func (h *Handlers) Follow(on bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		noContent(w, r, h.S.SetFollow(r.Context(), principal(r), r.PathValue("designer"), on))
	}
}

func (h *Handlers) Block(on bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		noContent(w, r, h.S.SetBlock(r.Context(), principal(r), r.PathValue("account"), on))
	}
}

func (h *Handlers) Profile(w http.ResponseWriter, r *http.Request) {
	p, err := h.S.Profile(r.Context(), principal(r), r.PathValue("username"))
	respond(w, r, http.StatusOK, p, err)
}

func (h *Handlers) ProfilePosts(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.ProfilePosts(r.Context(), principal(r), r.PathValue("username"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Followers(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Followers(r.Context(), principal(r), r.PathValue("username"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Following(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Following(r.Context(), principal(r), r.PathValue("username"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Saved(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.SavedPosts(r.Context(), principal(r), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) SuggestedDesigners(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.SuggestedDesigners(r.Context(), principal(r), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) SearchDesigners(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.SearchDesigners(r.Context(), principal(r), r.URL.Query().Get("q"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

// ── Media (create-then-upload) ──────────────────────────────────────────

func (h *Handlers) StartPostMedia(w http.ResponseWriter, r *http.Request) {
	var in struct{ Count int }
	if !decode(w, r, &in) {
		return
	}
	out, err := h.S.StartPostMedia(r.Context(), principal(r), in.Count)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) MediaBatch(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.MediaBatch(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) StartAttachment(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.StartAttachment(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusCreated, out, err)
}

// ── Orders ──────────────────────────────────────────────────────────────

func (h *Handlers) Orders(w http.ResponseWriter, r *http.Request) {
	role := "customer"
	if r.URL.Query().Get("role") == "designer" {
		role = "designer"
	}
	out, err := h.S.Orders(r.Context(), principal(r), role, paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) Order(w http.ResponseWriter, r *http.Request) {
	o, err := h.S.Order(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) CreateRequest(w http.ResponseWriter, r *http.Request) {
	var in service.RequestInput
	if !decode(w, r, &in) {
		return
	}
	p := principal(r)
	o, err := service.Idempotent(r.Context(), h.S, p, "POST /posts/"+r.PathValue("id")+"/requests", r.Header.Get("Idempotency-Key"), in,
		func() (*model.Order, error) { return h.S.CreateRequest(r.Context(), p, r.PathValue("id"), in) })
	respond(w, r, http.StatusCreated, o, err)
}

func (h *Handlers) Cancel(w http.ResponseWriter, r *http.Request) {
	o, err := h.S.Cancel(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) Quote(w http.ResponseWriter, r *http.Request) {
	var in struct {
		QuoteCents int64  `json:"quote_cents"`
		DueAt      string `json:"due_at"`
	}
	if !decode(w, r, &in) {
		return
	}
	if in.QuoteCents == 0 || in.DueAt == "" {
		writeError(w, http.StatusUnprocessableEntity, "validation_failed", "quote_cents and due_at are required", nil)
		return
	}
	o, err := h.S.Quote(r.Context(), principal(r), r.PathValue("id"), in.QuoteCents, in.DueAt)
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) Decline(w http.ResponseWriter, r *http.Request) {
	var in struct{ Reason string }
	if !decode(w, r, &in) {
		return
	}
	o, err := h.S.Decline(r.Context(), principal(r), r.PathValue("id"), in.Reason)
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) SetStatus(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Status   string  `json:"status"`
		Tracking *string `json:"tracking"`
	}
	if !decode(w, r, &in) {
		return
	}
	o, err := h.S.SetStatus(r.Context(), principal(r), r.PathValue("id"), in.Status, in.Tracking)
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) Pay(w http.ResponseWriter, r *http.Request) {
	p := principal(r)
	o, err := service.Idempotent(r.Context(), h.S, p, "POST /requests/"+r.PathValue("id")+"/pay", r.Header.Get("Idempotency-Key"), struct{}{},
		func() (*model.Order, error) { return h.S.Pay(r.Context(), p, r.PathValue("id")) })
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) ConfirmDelivery(w http.ResponseWriter, r *http.Request) {
	o, err := h.S.ConfirmDelivery(r.Context(), principal(r), r.PathValue("id"))
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) Dispute(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Reason string  `json:"reason"`
		Detail *string `json:"detail"`
	}
	if !decode(w, r, &in) {
		return
	}
	o, err := h.S.Dispute(r.Context(), principal(r), r.PathValue("id"), in.Reason, in.Detail)
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) ResolveDispute(w http.ResponseWriter, r *http.Request) {
	var in struct{ Outcome string }
	if !decode(w, r, &in) {
		return
	}
	o, err := h.S.ResolveDispute(r.Context(), principal(r), r.PathValue("id"), in.Outcome)
	respond(w, r, http.StatusOK, o, err)
}

func (h *Handlers) Messages(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Messages(r.Context(), principal(r), r.PathValue("id"), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) AddMessage(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Body     string  `json:"body"`
		ImageURL *string `json:"image_url"`
	}
	if !decode(w, r, &in) {
		return
	}
	m, err := h.S.AddMessage(r.Context(), principal(r), r.PathValue("id"), in.Body, in.ImageURL)
	respond(w, r, http.StatusCreated, m, err)
}

// ── Designer money ──────────────────────────────────────────────────────

func (h *Handlers) Earnings(w http.ResponseWriter, r *http.Request) {
	e, err := h.S.Earnings(r.Context(), principal(r))
	respond(w, r, http.StatusOK, e, err)
}

func (h *Handlers) PayoutAccount(w http.ResponseWriter, r *http.Request) {
	a, err := h.S.PayoutAccount(r.Context(), principal(r))
	respond(w, r, http.StatusOK, a, err)
}

// SubmitPayoutAccount backs both B8 calls (resolve, attach): verification is
// asynchronous through commerce, so the answer is 202 with kyc_state
// pending, and GET /designer/payout-account shows the result.
func (h *Handlers) SubmitPayoutAccount(w http.ResponseWriter, r *http.Request) {
	var in struct {
		BankCode      string `json:"bank_code"`
		AccountNumber string `json:"account_number"`
	}
	if !decode(w, r, &in) {
		return
	}
	if in.BankCode == "" || in.AccountNumber == "" {
		writeError(w, http.StatusUnprocessableEntity, "validation_failed", "bank_code and account_number are required", nil)
		return
	}
	a, err := h.S.SubmitPayoutAccount(r.Context(), principal(r), in.BankCode, in.AccountNumber)
	respond(w, r, http.StatusAccepted, a, err)
}

// ── Notifications ───────────────────────────────────────────────────────

func (h *Handlers) Notifications(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.Notifications(r.Context(), principal(r), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) MarkRead(w http.ResponseWriter, r *http.Request) {
	var in struct {
		IDs []string `json:"ids"`
	}
	body, _ := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if len(body) > 0 {
		_ = json.Unmarshal(body, &in)
	}
	noContent(w, r, h.S.MarkNotificationsRead(r.Context(), principal(r), in.IDs))
}

// ── Trust and safety ────────────────────────────────────────────────────

func (h *Handlers) FileReport(w http.ResponseWriter, r *http.Request) {
	var in struct {
		SubjectKind string  `json:"subject_kind"`
		SubjectID   string  `json:"subject_id"`
		Reason      string  `json:"reason"`
		Detail      *string `json:"detail"`
	}
	if !decode(w, r, &in) {
		return
	}
	out, err := h.S.FileReport(r.Context(), principal(r), in.SubjectKind, in.SubjectID, in.Reason, in.Detail)
	respond(w, r, http.StatusCreated, out, err)
}

func (h *Handlers) ModerationQueue(w http.ResponseWriter, r *http.Request) {
	out, err := h.S.ModerationQueue(r.Context(), principal(r), paging(r))
	respond(w, r, http.StatusOK, out, err)
}

func (h *Handlers) ActOnReport(w http.ResponseWriter, r *http.Request) {
	var in struct{ Action string }
	if !decode(w, r, &in) {
		return
	}
	out, err := h.S.ActOnReport(r.Context(), principal(r), r.PathValue("id"), in.Action)
	respond(w, r, http.StatusOK, out, err)
}

// ── Paystack webhooks (S-12) ────────────────────────────────────────────

// PaymentsWebhook answers 200 once the event is stored; Paystack retries
// anything else.
func (h *Handlers) PaymentsWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid_body", "Body too large", nil)
		return
	}
	err = h.S.ReceiveWebhook(r.Context(), body, r.Header.Get("X-Paystack-Signature"))
	if errors.Is(err, service.ErrBadSignature) {
		slog.Warn("webhook rejected", "step", "webhook", "reason", "signature")
		writeError(w, http.StatusUnauthorized, "invalid_signature", "Signature mismatch", nil)
		return
	}
	if err != nil {
		fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusOK)
}
