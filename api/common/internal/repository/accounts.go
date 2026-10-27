package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// Principal is everything authorization needs about the caller, resolved
// once per request (engineering.md §2).
type Principal struct {
	AccountID       string
	Email           string
	Username        string
	IsStaff         bool
	Suspended       bool
	DeletionPending bool
	WorkspaceID     string
	SelfCustomerID  string
	DesignerID      *string
	KYCVerified     bool
}

// FindAccountByUID returns the account id for a Firebase uid.
func FindAccountByUID(ctx context.Context, tx pgx.Tx, uid string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `SELECT id FROM account WHERE firebase_uid = $1`, uid).Scan(&id)
	return id, translate(err)
}

type NewAccount struct {
	FirebaseUID string
	Email       string
	Username    string
	DisplayName string
	AvatarURL   *string
}

// CreateAccount inserts the account with its personal workspace and self
// customer (data-model.md §6.1). A racing first sign-in loses on the
// firebase_uid constraint and returns ErrConflict (flows/auth.md §6).
func CreateAccount(ctx context.Context, tx pgx.Tx, a NewAccount) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO account (firebase_uid, email, username, display_name, avatar_url)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`, a.FirebaseUID, a.Email, a.Username, a.DisplayName, a.AvatarURL).Scan(&id)
	if err != nil {
		return "", translate(err)
	}
	var ws string
	if err := tx.QueryRow(ctx, `INSERT INTO workspace (name) VALUES ($1) RETURNING id`, a.DisplayName).Scan(&ws); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO workspace_member (workspace_id, account_id, role) VALUES ($1, $2, 'owner')`, ws, id); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO customer (workspace_id, account_id, kind, display_name) VALUES ($1, $2, 'self', $3)`,
		ws, id, a.DisplayName); err != nil {
		return "", err
	}
	return id, nil
}

// UsernameTaken reports whether a username is in use (case-insensitive).
func UsernameTaken(ctx context.Context, tx pgx.Tx, username string) (bool, error) {
	var taken bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM account WHERE lower(username) = lower($1))`, username).Scan(&taken)
	return taken, err
}

// LoadPrincipal reads the caller's authorization facts.
func LoadPrincipal(ctx context.Context, tx pgx.Tx, accountID string) (*Principal, error) {
	p := &Principal{AccountID: accountID}
	var suspended *time.Time
	var deletion string
	err := tx.QueryRow(ctx, `SELECT a.email, a.username, a.is_staff, a.suspended_at, a.deletion_state,
			c.workspace_id, c.id, d.id, coalesce(d.kyc_state = 'verified', false)
		FROM account a
		JOIN customer c ON c.account_id = a.id AND c.kind = 'self'
		LEFT JOIN designer_profile d ON d.account_id = a.id
		WHERE a.id = $1`, accountID).
		Scan(&p.Email, &p.Username, &p.IsStaff, &suspended, &deletion, &p.WorkspaceID, &p.SelfCustomerID, &p.DesignerID, &p.KYCVerified)
	if err != nil {
		return nil, translate(err)
	}
	p.Suspended = suspended != nil
	p.DeletionPending = deletion == "deletion_pending"
	return p, nil
}

// GetAccount reads the caller's own account (GET /me).
func GetAccount(ctx context.Context, tx pgx.Tx, accountID string) (*model.Account, error) {
	var a model.Account
	var location, prefs []byte
	var designerID *string
	var kyc *string
	err := tx.QueryRow(ctx, `SELECT a.id, a.firebase_uid, a.email, a.username, a.display_name, a.avatar_url,
			a.profile_location, a.deletion_state, a.is_staff, c.measurement_template, a.notification_prefs, a.created_at,
			d.id, d.kyc_state
		FROM account a
		JOIN customer c ON c.account_id = a.id AND c.kind = 'self'
		LEFT JOIN designer_profile d ON d.account_id = a.id
		WHERE a.id = $1`, accountID).
		Scan(&a.ID, &a.FirebaseUID, &a.Email, &a.Username, &a.DisplayName, &a.AvatarURL, &location, &a.DeletionState,
			&a.IsStaff, &a.MeasurementTemplate, &prefs, &a.CreatedAt, &designerID, &kyc)
	if err != nil {
		return nil, translate(err)
	}
	if len(location) > 0 {
		a.ProfileLocation = &model.Location{}
		_ = json.Unmarshal(location, a.ProfileLocation)
	}
	_ = json.Unmarshal(prefs, &a.NotificationPrefs)
	a.Designer = model.DesignerFlags{Enabled: designerID != nil, KYCComplete: kyc != nil && *kyc == "verified"}
	consent, err := ListConsent(ctx, tx, accountID)
	if err != nil {
		return nil, err
	}
	a.Consent = consent
	return &a, nil
}

// ListConsent returns the latest record per document.
func ListConsent(ctx context.Context, tx pgx.Tx, accountID string) ([]model.Consent, error) {
	rows, err := tx.Query(ctx, `SELECT DISTINCT ON (document) document, version, accepted_at FROM consent_record
		WHERE account_id = $1 ORDER BY document, accepted_at DESC`, accountID)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*model.Consent, error) {
		var c model.Consent
		return &c, r.Scan(&c.Document, &c.Version, &c.AcceptedAt)
	})
}

func RecordConsent(ctx context.Context, tx pgx.Tx, accountID, document, version string) (*model.Consent, error) {
	var c model.Consent
	err := tx.QueryRow(ctx, `INSERT INTO consent_record (account_id, document, version) VALUES ($1, $2, $3)
		RETURNING document, version, accepted_at`, accountID, document, version).Scan(&c.Document, &c.Version, &c.AcceptedAt)
	return &c, err
}

// AccountPatch is a partial update of the caller's own account.
type AccountPatch struct {
	Username            *string
	DisplayName         *string
	ProfileLocation     **model.Location
	NotificationPrefs   *model.NotificationPrefs
	MeasurementTemplate *string
}

func UpdateAccount(ctx context.Context, tx pgx.Tx, accountID string, p AccountPatch) error {
	if p.Username != nil {
		if _, err := tx.Exec(ctx, `UPDATE account SET username = $2, username_changed_at = now() WHERE id = $1`, accountID, *p.Username); err != nil {
			return translate(err)
		}
	}
	if p.DisplayName != nil {
		if _, err := tx.Exec(ctx, `UPDATE account SET display_name = $2 WHERE id = $1`, accountID, *p.DisplayName); err != nil {
			return err
		}
	}
	if p.ProfileLocation != nil {
		if _, err := tx.Exec(ctx, `UPDATE account SET profile_location = $2 WHERE id = $1`, accountID, jsonOrNil(*p.ProfileLocation)); err != nil {
			return err
		}
	}
	if p.NotificationPrefs != nil {
		if _, err := tx.Exec(ctx, `UPDATE account SET notification_prefs = $2 WHERE id = $1`, accountID, mustJSON(p.NotificationPrefs)); err != nil {
			return err
		}
	}
	if p.MeasurementTemplate != nil {
		if _, err := tx.Exec(ctx, `UPDATE customer SET measurement_template = $2 WHERE account_id = $1 AND kind = 'self'`,
			accountID, *p.MeasurementTemplate); err != nil {
			return err
		}
	}
	return nil
}

// UsernameChangedAt is when the caller last renamed (max once per 30 days).
func UsernameChangedAt(ctx context.Context, tx pgx.Tx, accountID string) (*time.Time, error) {
	var at *time.Time
	err := tx.QueryRow(ctx, `SELECT username_changed_at FROM account WHERE id = $1`, accountID).Scan(&at)
	return at, translate(err)
}

// ActiveMoney reports non-terminal orders (either role) or unsettled payouts
// (flows/auth.md §4: deletion is blocked while money is in flight).
func ActiveMoney(ctx context.Context, tx pgx.Tx, accountID string) (bool, error) {
	var active bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (
			SELECT 1 FROM request WHERE (customer_account_id = $1 OR designer_account_id = $1)
				AND status NOT IN ('delivered', 'refunded', 'declined', 'cancelled'))
		OR EXISTS (SELECT 1 FROM payout p JOIN designer_profile d ON d.id = p.designer_id
			WHERE d.account_id = $1 AND p.state = 'pending')`, accountID).Scan(&active)
	return active, err
}

func RequestDeletion(ctx context.Context, tx pgx.Tx, accountID string) error {
	_, err := tx.Exec(ctx, `UPDATE account SET deletion_state = 'deletion_pending', deletion_requested_at = now()
		WHERE id = $1 AND deletion_state = 'active'`, accountID)
	return err
}

// AccountNotify is what writing a notification for an account needs.
type AccountNotify struct {
	ID          string
	Username    string
	DisplayName string
	Email       string
	AvatarURL   *string
	Prefs       model.NotificationPrefs
}

func LoadAccountNotify(ctx context.Context, tx pgx.Tx, accountID string) (*AccountNotify, error) {
	var a AccountNotify
	var prefs []byte
	err := tx.QueryRow(ctx, `SELECT id, username, display_name, email, avatar_url, notification_prefs FROM account WHERE id = $1`, accountID).
		Scan(&a.ID, &a.Username, &a.DisplayName, &a.Email, &a.AvatarURL, &prefs)
	if err != nil {
		return nil, translate(err)
	}
	_ = json.Unmarshal(prefs, &a.Prefs)
	return &a, nil
}

// AccountByUsername resolves a username to its account id.
func AccountByUsername(ctx context.Context, tx pgx.Tx, username string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `SELECT id FROM account WHERE lower(username) = lower($1)`, username).Scan(&id)
	return id, translate(err)
}

func SetDeviceToken(ctx context.Context, tx pgx.Tx, accountID, token, platform string) error {
	_, err := tx.Exec(ctx, `INSERT INTO device_token (token, account_id, platform) VALUES ($1, $2, $3)
		ON CONFLICT (token) DO UPDATE SET account_id = EXCLUDED.account_id, platform = EXCLUDED.platform, updated_at = now()`,
		token, accountID, platform)
	return err
}

func DeleteDeviceToken(ctx context.Context, tx pgx.Tx, accountID, token string) error {
	_, err := tx.Exec(ctx, `DELETE FROM device_token WHERE token = $1 AND account_id = $2`, token, accountID)
	return err
}

func DeviceTokens(ctx context.Context, tx pgx.Tx, accountID string) ([]string, error) {
	rows, err := tx.Query(ctx, `SELECT token FROM device_token WHERE account_id = $1 ORDER BY updated_at DESC LIMIT 10`, accountID)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*string, error) {
		var t string
		return &t, r.Scan(&t)
	})
}

// Bypass runs fn with row-level security lifted inside the caller's
// transaction, for the few writes one account makes on another's behalf
// (the notification a request sends its designer).
func Bypass(ctx context.Context, tx pgx.Tx, fn func() error) error {
	var prev string
	if err := tx.QueryRow(ctx, `SELECT coalesce(current_setting('app.bypass_rls', true), ''), set_config('app.bypass_rls', 'on', true)`).
		Scan(&prev, new(string)); err != nil {
		return err
	}
	if err := fn(); err != nil {
		return err // the transaction is aborted; it rolls back with the setting
	}
	_, err := tx.Exec(ctx, `SELECT set_config('app.bypass_rls', $1, true)`, prev)
	return err
}
