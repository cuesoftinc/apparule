package service

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

var usernameRe = regexp.MustCompile(`^[a-z0-9._]{3,30}$`)

// SignInGoogle resolves a verified Google identity to its account id: by
// subject, else by the verified email (rebinding the subject), else a new
// account with its personal workspace and self customer (flows/auth.md §3).
// Concurrent first sign-ins converge on one row.
func (s *Services) SignInGoogle(ctx context.Context, id *auth.Identity) (string, error) {
	var accountID string
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		var err error
		accountID, err = repository.FindAccountBySub(ctx, tx, id.Sub)
		if !errors.Is(err, repository.ErrNotFound) {
			return err
		}
		accountID, err = repository.FindAccountByEmail(ctx, tx, id.Email)
		if err != nil {
			return err
		}
		return repository.BindGoogleSub(ctx, tx, accountID, id.Sub)
	})
	if errors.Is(err, repository.ErrNotFound) {
		return s.createAccount(ctx, id)
	}
	return accountID, err
}

func (s *Services) createAccount(ctx context.Context, id *auth.Identity) (string, error) {
	display := strings.TrimSpace(id.Name)
	if display == "" {
		display, _, _ = strings.Cut(id.Email, "@")
	}
	var avatar *string
	if id.Picture != "" {
		avatar = &id.Picture
	}
	for attempt := 0; attempt < 5; attempt++ {
		var accountID string
		err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
			username, err := s.freeUsername(ctx, tx, id.Email, attempt)
			if err != nil {
				return err
			}
			accountID, err = repository.CreateAccount(ctx, tx, repository.NewAccount{
				GoogleSub: id.Sub, Email: id.Email, Username: username, DisplayName: display, AvatarURL: avatar,
			})
			return err
		})
		if errors.Is(err, repository.ErrConflict) {
			// Lost a race: either the same subject signed in concurrently, or the
			// username was taken between check and insert.
			var existing string
			if s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
				existing, err = repository.FindAccountBySub(ctx, tx, id.Sub)
				return err
			}) == nil {
				return existing, nil
			}
			continue
		}
		return accountID, err
	}
	return "", errors.New("could not allocate a username")
}

// freeUsername derives a default username from the email (claimable later,
// data-model.md §2).
func (s *Services) freeUsername(ctx context.Context, tx pgx.Tx, email string, attempt int) (string, error) {
	local, _, _ := strings.Cut(strings.ToLower(email), "@")
	base := regexp.MustCompile(`[^a-z0-9._]`).ReplaceAllString(local, "")
	if len(base) > 24 {
		base = base[:24]
	}
	for len(base) < 3 {
		base += "_"
	}
	candidate := base
	if attempt > 0 {
		candidate = base + "_" + randomHex(2)
	}
	taken, err := repository.UsernameTaken(ctx, tx, candidate)
	if err != nil || !taken {
		return candidate, err
	}
	return base + "_" + randomHex(2), nil
}

func randomHex(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// Me reads the caller's account.
func (s *Services) Me(ctx context.Context, p *Principal) (*model.Account, error) {
	var a *model.Account
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		a, err = repository.GetAccount(ctx, tx, p.AccountID)
		return err
	})
	return a, err
}

// MePatch is PATCH /me's body.
type MePatch struct {
	Username            *string          `json:"username"`
	DisplayName         *string          `json:"display_name"`
	ProfileLocation     *model.Location  `json:"profile_location"`
	ClearLocation       bool             `json:"-"`
	NotificationPrefs   *map[string]bool `json:"notification_prefs"`
	MeasurementTemplate *string          `json:"measurement_template"`
	TemplateSet         bool             `json:"-"`
}

func (s *Services) UpdateMe(ctx context.Context, p *Principal, in MePatch) (*model.Account, error) {
	var out *model.Account
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		current, err := repository.GetAccount(ctx, tx, p.AccountID)
		if err != nil {
			return err
		}
		var patch repository.AccountPatch
		if in.Username != nil && *in.Username != current.Username {
			name := *in.Username
			if !usernameRe.MatchString(name) {
				return invalid("Username must be 3-30 chars of a-z 0-9 . _")
			}
			changed, err := repository.UsernameChangedAt(ctx, tx, p.AccountID)
			if err != nil {
				return err
			}
			if changed != nil && s.Now().Sub(*changed) < 30*24*time.Hour {
				return conflict("rename_too_soon", "You can change your username once every 30 days")
			}
			taken, err := repository.UsernameTaken(ctx, tx, name)
			if err != nil {
				return err
			}
			if taken {
				return conflict("name_taken", "That username is taken")
			}
			patch.Username = &name
		}
		if in.DisplayName != nil {
			name := strings.TrimSpace(*in.DisplayName)
			if name == "" || len(name) > 60 {
				return invalid("display_name must be 1-60 characters")
			}
			patch.DisplayName = &name
		}
		if in.ProfileLocation != nil || in.ClearLocation {
			loc := in.ProfileLocation
			if loc != nil && (loc.City == "" || loc.State == "" || loc.Country == "") {
				return invalid("profile_location needs city, state and country")
			}
			patch.ProfileLocation = &loc
		}
		if in.NotificationPrefs != nil {
			prefs := current.NotificationPrefs
			for k, v := range *in.NotificationPrefs {
				switch k {
				case "quotes":
					prefs.Quotes = v
				case "order_status":
					prefs.OrderStatus = v
				case "social":
					prefs.Social = v
				case "payouts":
					prefs.Payouts = v
				default:
					return invalid("unknown notification preference " + k)
				}
			}
			patch.NotificationPrefs = &prefs
		}
		if in.TemplateSet {
			// A-10: settable and editable, never cleared back to null.
			if in.MeasurementTemplate == nil || (*in.MeasurementTemplate != "women" && *in.MeasurementTemplate != "men") {
				return invalid("measurement_template must be women or men")
			}
			patch.MeasurementTemplate = in.MeasurementTemplate
		}
		if err := repository.UpdateAccount(ctx, tx, p.AccountID, patch); err != nil {
			if errors.Is(err, repository.ErrConflict) {
				return conflict("name_taken", "That username is taken")
			}
			return err
		}
		out, err = repository.GetAccount(ctx, tx, p.AccountID)
		return err
	})
	return out, err
}

func (s *Services) Consent(ctx context.Context, p *Principal) ([]model.Consent, error) {
	var out []model.Consent
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		out, err = repository.ListConsent(ctx, tx, p.AccountID)
		return err
	})
	if out == nil {
		out = []model.Consent{}
	}
	return out, err
}

func (s *Services) RecordConsent(ctx context.Context, p *Principal, document, version string) (*model.Consent, error) {
	if (document != "tos" && document != "privacy") || strings.TrimSpace(version) == "" {
		return nil, invalid("document (tos|privacy) and version are required")
	}
	var c *model.Consent
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		c, err = repository.RecordConsent(ctx, tx, p.AccountID, document, strings.TrimSpace(version))
		return err
	})
	return c, err
}

// ExportData is "Download my data" (pages.md B7; data-model.md §4).
func (s *Services) ExportData(ctx context.Context, p *Principal) (map[string]any, error) {
	out := map[string]any{}
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		account, err := repository.GetAccount(ctx, tx, p.AccountID)
		if err != nil {
			return err
		}
		sessions, err := repository.ListSessions(ctx, tx, p.SelfCustomerID, 0, 10_000)
		if err != nil {
			return err
		}
		orders, err := repository.ListOrders(ctx, tx, p.AccountID, "customer", 0, 10_000)
		if err != nil {
			return err
		}
		saved, err := repository.SavedPosts(ctx, tx, p.AccountID, 0, 10_000, s.mediaURL(ctx))
		if err != nil {
			return err
		}
		savedIDs := make([]string, len(saved))
		for i, post := range saved {
			savedIDs[i] = post.ID
		}
		sessionOut := make([]model.Session, len(sessions))
		for i, ss := range sessions {
			sessionOut[i] = ss.Session
		}
		orderOut := make([]model.Order, len(orders))
		for i, o := range orders {
			orderOut[i] = *s.orderOut(ctx, o)
		}
		out["account"] = account
		out["sessions"] = sessionOut
		out["orders"] = orderOut
		out["consent"] = account.Consent
		out["saved_post_ids"] = savedIDs
		out["exported_at"] = s.Now().UTC()
		return nil
	})
	return out, err
}

// RequestDeletion flags the account (flows/auth.md §4); the retention sweep
// purges it once nothing is in flight.
func (s *Services) RequestDeletion(ctx context.Context, p *Principal) (*model.Account, error) {
	var out *model.Account
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		busy, err := repository.ActiveMoney(ctx, tx, p.AccountID)
		if err != nil {
			return err
		}
		if busy {
			return conflict("account_has_active_orders", "Finish or cancel your open orders before deleting your account")
		}
		if err := repository.RequestDeletion(ctx, tx, p.AccountID); err != nil {
			return err
		}
		out, err = repository.GetAccount(ctx, tx, p.AccountID)
		return err
	})
	return out, err
}

// ── Designer profile (flows/designer.md §1) ─────────────────────────────

func (s *Services) EnableDesigner(ctx context.Context, p *Principal, displayName, bio string) (*model.DesignerProfile, error) {
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		return nil, invalid("display_name is required")
	}
	if len(bio) > 300 {
		return nil, invalid("bio is at most 300 characters")
	}
	if err := active(p); err != nil {
		return nil, err
	}
	var out *model.DesignerProfile
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if _, err := repository.EnableDesigner(ctx, tx, p.AccountID, displayName, bio); err != nil {
			return err
		}
		d, err := repository.DesignerByAccount(ctx, tx, p.AccountID)
		if err != nil {
			return err
		}
		out = &d.DesignerProfile
		return nil
	})
	return out, err
}

// ── Instance requests (APP-002) ─────────────────────────────────────────

func (s *Services) RequestInstance(ctx context.Context, p *Principal, notes string) (*model.InstanceRequest, error) {
	if len(notes) > 2000 {
		return nil, invalid("notes are at most 2000 characters")
	}
	var out *model.InstanceRequest
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		out, err = repository.InsertInstanceRequest(ctx, tx, p.WorkspaceID, p.AccountID, notes)
		return err
	})
	return out, err
}

func (s *Services) InstanceRequests(ctx context.Context, p *Principal) ([]model.InstanceRequest, error) {
	var out []model.InstanceRequest
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		out, err = repository.ListInstanceRequests(ctx, tx, p.WorkspaceID)
		return err
	})
	return out, err
}

// requireDesigner returns the caller's designer id or 403.
func requireDesigner(p *Principal, message string) (string, error) {
	if p.DesignerID == nil {
		return "", newErr(http.StatusForbidden, "designer_profile_required", message)
	}
	return *p.DesignerID, nil
}
