// Package model holds the JSON shapes of the HTTP API. They mirror the web
// models (web/src/models/entities), which with the mock server are the
// contract this service implements (system-design.md §7.3).
package model

import (
	"encoding/json"
	"time"
)

// ── Accounts ────────────────────────────────────────────────────────────

type Location struct {
	City    string `json:"city"`
	State   string `json:"state"`
	Country string `json:"country"`
}

type Consent struct {
	Document   string    `json:"document"`
	Version    string    `json:"version"`
	AcceptedAt time.Time `json:"accepted_at"`
}

type NotificationPrefs struct {
	Quotes      bool `json:"quotes"`
	OrderStatus bool `json:"order_status"`
	Social      bool `json:"social"`
	Payouts     bool `json:"payouts"`
}

type DesignerFlags struct {
	Enabled     bool `json:"enabled"`
	KYCComplete bool `json:"kyc_complete"`
}

type Account struct {
	ID                  string            `json:"id"`
	FirebaseUID         string            `json:"firebase_uid"`
	Email               string            `json:"email"`
	Username            string            `json:"username"`
	DisplayName         string            `json:"display_name"`
	AvatarURL           *string           `json:"avatar_url"`
	ProfileLocation     *Location         `json:"profile_location"`
	DeletionState       string            `json:"deletion_state"`
	Designer            DesignerFlags     `json:"designer"`
	IsStaff             bool              `json:"is_staff"`
	MeasurementTemplate *string           `json:"measurement_template"`
	NotificationPrefs   NotificationPrefs `json:"notification_prefs"`
	Consent             []Consent         `json:"consent"`
	CreatedAt           time.Time         `json:"created_at"`
}

// ── The vault ───────────────────────────────────────────────────────────

type Measurement struct {
	ID         string   `json:"id"`
	SessionID  string   `json:"session_id"`
	Name       string   `json:"name"`
	ValueCM    float64  `json:"value_cm"`
	Source     string   `json:"source"`
	Confidence *float64 `json:"confidence"`
}

// QCFailure is a failed_qc session's verdict, with the retake copy
// (flows/vault.md §1).
type QCFailure struct {
	Code     string `json:"code"`
	Pose     string `json:"pose"`
	Message  string `json:"message"`
	Guidance string `json:"guidance"`
}

type Session struct {
	ID            string          `json:"id"`
	CustomerID    string          `json:"customer_id"`
	Method        string          `json:"method"`
	InputHeightCM *float64        `json:"input_height_cm"`
	Status        string          `json:"status"`
	Measurements  []Measurement   `json:"measurements"`
	PipelineMeta  json.RawMessage `json:"pipeline_meta"`
	// Asynchronous capture (system-design.md §6.1).
	QC        *QCFailure        `json:"qc,omitempty"`
	Poses     map[string]string `json:"poses,omitempty"`
	ErrorCode *string           `json:"error_code,omitempty"`
	CreatedAt time.Time         `json:"created_at"`
}

// CaptureStarted answers POST /me/sessions for a capture: the session and
// the ticket for its upload to api/uploads.
type CaptureStarted struct {
	Session
	Upload UploadTicket `json:"upload"`
}

type UploadTicket struct {
	Ticket    string    `json:"ticket"`
	URL       string    `json:"url"`
	Fields    []string  `json:"fields"`
	MaxFiles  int       `json:"max_files"`
	MaxBytes  int64     `json:"max_bytes"`
	ExpiresAt time.Time `json:"expires_at"`
}

type Export struct {
	URL    string `json:"url"`
	Format string `json:"format"`
}

// ── Media ───────────────────────────────────────────────────────────────

type MediaBatch struct {
	ID     string        `json:"id"`
	Kind   string        `json:"kind"`
	Status string        `json:"status"`
	Items  []MediaItem   `json:"items"`
	Upload *UploadTicket `json:"upload,omitempty"`
}

type MediaItem struct {
	ID     string `json:"id"`
	URL    string `json:"url"`
	Width  int    `json:"width"`
	Height int    `json:"height"`
}

// ── Social ──────────────────────────────────────────────────────────────

type PostDesigner struct {
	ID          string  `json:"id"`
	Username    string  `json:"username"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
	Verified    bool    `json:"verified"`
}

type PostMedia struct {
	ID       string `json:"id"`
	PostID   string `json:"post_id"`
	URL      string `json:"url"`
	Position int    `json:"position"`
	AltText  string `json:"alt_text"`
	Width    int    `json:"width"`
	Height   int    `json:"height"`
}

type Post struct {
	ID             string       `json:"id"`
	Designer       PostDesigner `json:"designer"`
	Caption        string       `json:"caption"`
	StyleTags      []string     `json:"style_tags"`
	BasePriceCents *int64       `json:"base_price_cents"`
	Currency       string       `json:"currency"`
	TurnaroundDays int          `json:"turnaround_days"`
	Media          []PostMedia  `json:"media"`
	LikeCount      int          `json:"like_count"`
	CommentCount   int          `json:"comment_count"`
	Liked          bool         `json:"liked"`
	Saved          bool         `json:"saved"`
	CreatedAt      time.Time    `json:"created_at"`
}

type CommentAuthor struct {
	ID        string  `json:"id"`
	Username  string  `json:"username"`
	AvatarURL *string `json:"avatar_url"`
}

type Comment struct {
	ID                 string        `json:"id"`
	PostID             string        `json:"post_id"`
	Author             CommentAuthor `json:"author"`
	Body               string        `json:"body"`
	LikeCount          int           `json:"like_count"`
	Liked              bool          `json:"liked"`
	HiddenByModeration bool          `json:"hidden_by_moderation"`
	CreatedAt          time.Time     `json:"created_at"`
}

type PayoutAccount struct {
	ProviderRef  *string `json:"provider_ref"`
	BankName     *string `json:"bank_name"`
	AccountLast4 *string `json:"account_last4"`
	// none | pending | verified | lapsed
	KYCState string `json:"kyc_state"`
	// Set while pending or after a failed attempt (B8 resolution states).
	AccountName *string `json:"account_name,omitempty"`
	Reason      *string `json:"reason,omitempty"`
}

type DesignerProfile struct {
	ID             string        `json:"id"`
	AccountID      string        `json:"account_id"`
	Username       string        `json:"username"`
	DisplayName    string        `json:"display_name"`
	Bio            string        `json:"bio"`
	AvatarURL      *string       `json:"avatar_url"`
	PayoutAccount  PayoutAccount `json:"payout_account"`
	Verified       bool          `json:"verified"`
	Location       *Location     `json:"location"`
	FollowersCount int           `json:"followers_count"`
	FollowingCount int           `json:"following_count"`
	PostsCount     int           `json:"posts_count"`
}

type UserSummary struct {
	Username      string  `json:"username"`
	DisplayName   string  `json:"display_name"`
	AvatarURL     *string `json:"avatar_url"`
	Verified      bool    `json:"verified"`
	IsDesigner    bool    `json:"is_designer"`
	Meta          *string `json:"meta"`
	ViewerFollows bool    `json:"viewer_follows"`
}

type ProfileAccount struct {
	Username    string  `json:"username"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// PublicProfile is the designer or user form of GET /profiles/{username}.
type PublicProfile struct {
	Kind          string           `json:"kind"`
	Designer      *DesignerProfile `json:"designer,omitempty"`
	Account       *ProfileAccount  `json:"account,omitempty"`
	ViewerFollows *bool            `json:"viewer_follows,omitempty"`
	ViewerIsSelf  bool             `json:"viewer_is_self"`
}

// Page is cursor pagination (api.md §4).
type Page[T any] struct {
	Items      []T     `json:"items"`
	NextCursor *string `json:"next_cursor"`
}

// ── Orders ──────────────────────────────────────────────────────────────

type Delivery struct {
	RecipientName string  `json:"recipient_name"`
	Phone         string  `json:"phone"`
	Line1         string  `json:"line1"`
	Line2         *string `json:"line2,omitempty"`
	City          string  `json:"city"`
	State         string  `json:"state"`
	Country       string  `json:"country"`
}

type SnapshotValue struct {
	Name    string  `json:"name"`
	ValueCM float64 `json:"value_cm"`
}

type SnapshotValues struct {
	Method       string          `json:"method"`
	MeasuredAt   time.Time       `json:"measured_at"`
	Measurements []SnapshotValue `json:"measurements"`
}

type Snapshot struct {
	ID        string         `json:"id"`
	RequestID string         `json:"request_id"`
	Values    SnapshotValues `json:"values"`
	CreatedAt time.Time      `json:"created_at"`
}

type OrderEvent struct {
	ID        string    `json:"id"`
	RequestID string    `json:"request_id"`
	Kind      string    `json:"kind"`
	Actor     string    `json:"actor"`
	CreatedAt time.Time `json:"created_at"`
}

type Payment struct {
	ID               string `json:"id"`
	RequestID        string `json:"request_id"`
	Provider         string `json:"provider"`
	State            string `json:"state"`
	Currency         string `json:"currency"`
	AmountCents      int64  `json:"amount_cents"`
	PlatformFeeCents int64  `json:"platform_fee_cents"`
}

type Party struct {
	ID        string  `json:"id"`
	Username  string  `json:"username"`
	AvatarURL *string `json:"avatar_url"`
}

type OrderPost struct {
	ID       string `json:"id"`
	Caption  string `json:"caption"`
	ThumbURL string `json:"thumb_url"`
}

type Dispute struct {
	Reason string  `json:"reason"`
	Detail *string `json:"detail"`
}

type Order struct {
	ID            string       `json:"id"`
	OrderNumber   string       `json:"order_number"`
	Post          OrderPost    `json:"post"`
	Customer      Party        `json:"customer"`
	Designer      Party        `json:"designer"`
	Status        string       `json:"status"`
	Notes         string       `json:"notes"`
	BudgetCents   *int64       `json:"budget_cents"`
	QuoteCents    *int64       `json:"quote_cents"`
	Currency      string       `json:"currency"`
	DueAt         *time.Time   `json:"due_at"`
	TargetDate    *string      `json:"target_date"`
	Tracking      *string      `json:"tracking"`
	DeclineReason *string      `json:"decline_reason"`
	Dispute       *Dispute     `json:"dispute"`
	Delivery      Delivery     `json:"delivery"`
	Snapshot      Snapshot     `json:"snapshot"`
	Events        []OrderEvent `json:"events"`
	Payment       *Payment     `json:"payment"`
	CreatedAt     time.Time    `json:"created_at"`
	// Set by POST /requests/{id}/pay while the charge is pending.
	Checkout *Checkout `json:"checkout,omitempty"`
}

// Checkout is what a client needs to open Paystack's checkout for an order.
// The charge settles by webhook (§6.3), never by the client's word.
type Checkout struct {
	Provider    string `json:"provider"`
	Reference   string `json:"reference"`
	AmountCents int64  `json:"amount_cents"`
	Currency    string `json:"currency"`
	Email       string `json:"email"`
	PublicKey   string `json:"public_key"`
}

type ThreadMessage struct {
	ID        string    `json:"id"`
	RequestID string    `json:"request_id"`
	AuthorID  string    `json:"author_id"`
	Body      string    `json:"body"`
	ImageURL  *string   `json:"image_url"`
	CreatedAt time.Time `json:"created_at"`
}

// ── Notifications, earnings, moderation ─────────────────────────────────

type Actor struct {
	Username  string  `json:"username"`
	AvatarURL *string `json:"avatar_url"`
}

type Notification struct {
	ID         string     `json:"id"`
	AccountID  string     `json:"account_id"`
	Kind       string     `json:"kind"`
	PayloadRef string     `json:"payload_ref"`
	Text       string     `json:"text"`
	Actor      *Actor     `json:"actor"`
	ThumbURL   *string    `json:"thumb_url"`
	ReadAt     *time.Time `json:"read_at"`
	CreatedAt  time.Time  `json:"created_at"`
}

type EarningsEntry struct {
	ID          string    `json:"id"`
	Kind        string    `json:"kind"`
	AmountCents int64     `json:"amount_cents"`
	Currency    string    `json:"currency"`
	OrderNumber string    `json:"order_number"`
	ProviderRef *string   `json:"provider_ref"`
	CreatedAt   time.Time `json:"created_at"`
}

type Earnings struct {
	BalanceCents int64           `json:"balance_cents"`
	PendingCents int64           `json:"pending_cents"`
	Currency     string          `json:"currency"`
	Transactions []EarningsEntry `json:"transactions"`
}

type ReportPreview struct {
	Text           string  `json:"text"`
	ThumbURL       *string `json:"thumb_url"`
	AuthorUsername *string `json:"author_username"`
}

type Ref struct {
	ID       string `json:"id"`
	Username string `json:"username"`
}

type Report struct {
	ID             string        `json:"id"`
	Reporter       Ref           `json:"reporter"`
	SubjectKind    string        `json:"subject_kind"`
	SubjectID      string        `json:"subject_id"`
	SubjectPreview ReportPreview `json:"subject_preview"`
	Reason         string        `json:"reason"`
	Detail         *string       `json:"detail"`
	Status         string        `json:"status"`
	Action         *string       `json:"action"`
	ActionedBy     *Ref          `json:"actioned_by"`
	ActionedAt     *time.Time    `json:"actioned_at"`
	CreatedAt      time.Time     `json:"created_at"`
}

type InstanceRequest struct {
	ID        string    `json:"id"`
	Status    string    `json:"status"`
	Notes     string    `json:"notes"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
