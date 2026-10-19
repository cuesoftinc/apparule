package repository

import (
	"context"
	"encoding/json"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
)

// MediaURL turns a stored object key into a URL clients can load.
type MediaURL func(key string) string

// ── Designers ───────────────────────────────────────────────────────────

type DesignerRow struct {
	model.DesignerProfile
	BankCode        *string
	PayoutAttemptID *string
}

// designerCols reads a designer profile with its account, and derives the
// social counts from the graph at read time (pages.md B6).
const designerCols = `d.id, d.account_id, a.username, d.display_name, d.bio, a.avatar_url, d.verified,
	d.kyc_state, d.kyc_reason, d.recipient_code, d.bank_code, d.bank_name, d.account_last4, d.account_name,
	d.payout_attempt_id, a.profile_location,
	(SELECT count(*) FROM follow f WHERE f.designer_id = d.id),
	(SELECT count(*) FROM follow f WHERE f.follower_id = d.account_id),
	(SELECT count(*) FROM post p WHERE p.designer_id = d.id AND p.hidden_at IS NULL)`

func scanDesigner(r pgx.Row) (*DesignerRow, error) {
	var d DesignerRow
	var location []byte
	pa := &d.PayoutAccount
	err := r.Scan(&d.ID, &d.AccountID, &d.Username, &d.DisplayName, &d.Bio, &d.AvatarURL, &d.Verified,
		&pa.KYCState, &pa.Reason, &pa.ProviderRef, &d.BankCode, &pa.BankName, &pa.AccountLast4, &pa.AccountName,
		&d.PayoutAttemptID, &location, &d.FollowersCount, &d.FollowingCount, &d.PostsCount)
	if err != nil {
		return nil, translate(err)
	}
	if len(location) > 0 {
		d.Location = &model.Location{}
		_ = json.Unmarshal(location, d.Location)
	}
	return &d, nil
}

func DesignerByAccount(ctx context.Context, tx pgx.Tx, accountID string) (*DesignerRow, error) {
	return scanDesigner(tx.QueryRow(ctx, `SELECT `+designerCols+` FROM designer_profile d JOIN account a ON a.id = d.account_id
		WHERE d.account_id = $1`, accountID))
}

func DesignerByID(ctx context.Context, tx pgx.Tx, id string) (*DesignerRow, error) {
	return scanDesigner(tx.QueryRow(ctx, `SELECT `+designerCols+` FROM designer_profile d JOIN account a ON a.id = d.account_id
		WHERE d.id = $1`, id))
}

func DesignerByUsername(ctx context.Context, tx pgx.Tx, username string) (*DesignerRow, error) {
	return scanDesigner(tx.QueryRow(ctx, `SELECT `+designerCols+` FROM designer_profile d JOIN account a ON a.id = d.account_id
		WHERE lower(a.username) = lower($1) AND a.suspended_at IS NULL`, username))
}

// EnableDesigner creates the profile if missing and returns its id.
func EnableDesigner(ctx context.Context, tx pgx.Tx, accountID, displayName, bio string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO designer_profile (account_id, display_name, bio) VALUES ($1, $2, $3)
		ON CONFLICT (account_id) DO UPDATE SET display_name = EXCLUDED.display_name,
			bio = CASE WHEN EXCLUDED.bio = '' THEN designer_profile.bio ELSE EXCLUDED.bio END
		RETURNING id`, accountID, displayName, bio).Scan(&id)
	return id, err
}

// StartPayoutAttempt records a bank account submission awaiting commerce's
// verification (pages.md B8).
func StartPayoutAttempt(ctx context.Context, tx pgx.Tx, designerID, attemptID, bankCode, bankName, last4 string) error {
	_, err := tx.Exec(ctx, `UPDATE designer_profile SET kyc_state = 'pending', kyc_reason = NULL, payout_attempt_id = $2,
		bank_code = $3, bank_name = $4, account_last4 = $5, account_name = NULL, recipient_code = NULL WHERE id = $1`,
		designerID, attemptID, bankCode, bankName, last4)
	return err
}

// FinishPayoutAttempt stores commerce's verdict for the current attempt; an
// outcome for an older attempt changes nothing.
func FinishPayoutAttempt(ctx context.Context, tx pgx.Tx, designerID, attemptID string, verified bool, recipientCode, accountName, bankName, last4, reason *string) (bool, error) {
	tag, err := tx.Exec(ctx, `UPDATE designer_profile SET
			kyc_state = CASE WHEN $3 THEN 'verified' ELSE 'none' END,
			recipient_code = $4, account_name = coalesce($5, account_name), bank_name = coalesce($6, bank_name),
			account_last4 = coalesce($7, account_last4), kyc_reason = $8
		WHERE id = $1 AND payout_attempt_id = $2`, designerID, attemptID, verified, recipientCode, accountName, bankName, last4, reason)
	return tag.RowsAffected() > 0, err
}

// ── Posts ───────────────────────────────────────────────────────────────

const postCols = `p.id, d.id, a.username, d.display_name, a.avatar_url, d.verified, p.caption, p.style_tags,
	p.base_price_cents, p.currency, p.turnaround_days, p.like_count, p.comment_count,
	EXISTS (SELECT 1 FROM post_like l WHERE l.post_id = p.id AND l.account_id = $1),
	EXISTS (SELECT 1 FROM post_save s WHERE s.post_id = p.id AND s.account_id = $1),
	p.created_at`

const postFrom = ` FROM post p JOIN designer_profile d ON d.id = p.designer_id JOIN account a ON a.id = d.account_id`

// notBlocked hides posts by designers the viewer blocked or who blocked the
// viewer (data-model.md §6.2), and posts by suspended accounts.
const notBlocked = ` AND a.suspended_at IS NULL AND NOT EXISTS (SELECT 1 FROM block b
	WHERE (b.blocker_id = $1 AND b.blocked_id = a.id) OR (b.blocker_id = a.id AND b.blocked_id = $1))`

func scanPosts(ctx context.Context, tx pgx.Tx, rows pgx.Rows, url MediaURL) ([]model.Post, error) {
	posts, err := collect(rows, func(r pgx.Row) (*model.Post, error) {
		var p model.Post
		d := &p.Designer
		return &p, r.Scan(&p.ID, &d.ID, &d.Username, &d.DisplayName, &d.AvatarURL, &d.Verified, &p.Caption, &p.StyleTags,
			&p.BasePriceCents, &p.Currency, &p.TurnaroundDays, &p.LikeCount, &p.CommentCount, &p.Liked, &p.Saved, &p.CreatedAt)
	})
	if err != nil || len(posts) == 0 {
		return posts, err
	}
	ids := make([]string, len(posts))
	index := map[string]int{}
	for i := range posts {
		ids[i] = posts[i].ID
		index[posts[i].ID] = i
		posts[i].Media = []model.PostMedia{}
		if posts[i].StyleTags == nil {
			posts[i].StyleTags = []string{}
		}
	}
	mrows, err := tx.Query(ctx, `SELECT id, post_id, position, object_key, alt_text, width, height FROM post_media
		WHERE post_id::text = ANY($1) ORDER BY post_id, position`, ids)
	if err != nil {
		return nil, err
	}
	media, err := collect(mrows, func(r pgx.Row) (*model.PostMedia, error) {
		var m model.PostMedia
		var key string
		if err := r.Scan(&m.ID, &m.PostID, &m.Position, &key, &m.AltText, &m.Width, &m.Height); err != nil {
			return nil, err
		}
		m.URL = url(key)
		return &m, nil
	})
	if err != nil {
		return nil, err
	}
	for _, m := range media {
		p := &posts[index[m.PostID]]
		p.Media = append(p.Media, m)
	}
	return posts, nil
}

// GetPost reads a visible post with the viewer's engagement state.
func GetPost(ctx context.Context, tx pgx.Tx, viewerID, postID string, url MediaURL) (*model.Post, error) {
	rows, err := tx.Query(ctx, `SELECT `+postCols+postFrom+` WHERE p.id = $2 AND p.hidden_at IS NULL`+notBlocked, viewerID, postID)
	if err != nil {
		return nil, err
	}
	posts, err := scanPosts(ctx, tx, rows, url)
	if err != nil {
		return nil, err
	}
	if len(posts) == 0 {
		return nil, ErrNotFound
	}
	return &posts[0], nil
}

// PostsByIDs reads visible posts in the given order (ranked pages).
func PostsByIDs(ctx context.Context, tx pgx.Tx, viewerID string, ids []string, url MediaURL) ([]model.Post, error) {
	rows, err := tx.Query(ctx, `SELECT `+postCols+postFrom+` WHERE p.id::text = ANY($2) AND p.hidden_at IS NULL`+notBlocked, viewerID, ids)
	if err != nil {
		return nil, err
	}
	posts, err := scanPosts(ctx, tx, rows, url)
	if err != nil {
		return nil, err
	}
	byID := map[string]model.Post{}
	for _, p := range posts {
		byID[p.ID] = p
	}
	out := make([]model.Post, 0, len(ids))
	for _, id := range ids {
		if p, ok := byID[id]; ok {
			out = append(out, p)
		}
	}
	return out, nil
}

// FeedIDs ranks the viewer's feed: posts by followed designers, newest
// first (api.md §5 v1 ranking).
func FeedIDs(ctx context.Context, tx pgx.Tx, viewerID string, max int) ([]string, error) {
	return ids(ctx, tx, `SELECT p.id::text`+postFrom+`
		WHERE p.hidden_at IS NULL AND EXISTS (SELECT 1 FROM follow f WHERE f.follower_id = $1 AND f.designer_id = d.id)`+notBlocked+`
		ORDER BY p.created_at DESC, p.id LIMIT $2`, viewerID, max)
}

// ExploreFilter is GET /explore's query (api.md §5).
type ExploreFilter struct {
	Q                 string
	Tags              []string
	PriceBand         string
	MaxTurnaroundDays int
	NearMe            bool
}

// ExploreIDs ranks explore: filtered, newest first; near_me orders by
// proximity tier (same city > state > country > none, X-10), recency within.
func ExploreIDs(ctx context.Context, tx pgx.Tx, viewerID string, f ExploreFilter, home *model.Location, max int) ([]string, error) {
	where := []string{"p.hidden_at IS NULL"}
	args := []any{viewerID, max}
	add := func(cond string, v any) {
		args = append(args, v)
		where = append(where, strings.ReplaceAll(cond, "?", "$"+itoa(len(args))))
	}
	if f.Q != "" {
		add(`(p.caption ILIKE ? OR a.username ILIKE ? OR d.display_name ILIKE ? OR EXISTS (SELECT 1 FROM unnest(p.style_tags) t WHERE t ILIKE ?))`,
			"%"+escapeLike(strings.ToLower(f.Q))+"%")
	}
	if len(f.Tags) > 0 {
		add(`p.style_tags && ?`, f.Tags)
	}
	switch f.PriceBand { // NGN bands: budget <25k, mid 25-100k, premium >100k
	case "budget":
		where = append(where, `p.base_price_cents < 2500000`)
	case "mid":
		where = append(where, `p.base_price_cents BETWEEN 2500000 AND 10000000`)
	case "premium":
		where = append(where, `p.base_price_cents > 10000000`)
	}
	if f.MaxTurnaroundDays > 0 {
		add(`p.turnaround_days <= ?`, f.MaxTurnaroundDays)
	}
	order := `p.created_at DESC, p.id`
	if f.NearMe && home != nil {
		args = append(args, home.Country, home.State, home.City)
		c, s, ci := "$"+itoa(len(args)-2), "$"+itoa(len(args)-1), "$"+itoa(len(args))
		order = `CASE WHEN a.profile_location IS NULL OR a.profile_location->>'country' <> ` + c + ` THEN 3
			WHEN a.profile_location->>'state' = ` + s + ` AND a.profile_location->>'city' = ` + ci + ` THEN 0
			WHEN a.profile_location->>'state' = ` + s + ` THEN 1 ELSE 2 END, ` + order
	}
	return ids(ctx, tx, `SELECT p.id::text`+postFrom+` WHERE `+strings.Join(where, " AND ")+notBlocked+
		` ORDER BY `+order+` LIMIT $2`, args...)
}

func PostsByDesigner(ctx context.Context, tx pgx.Tx, viewerID, designerID string, offset, limit int, url MediaURL) ([]model.Post, error) {
	rows, err := tx.Query(ctx, `SELECT `+postCols+postFrom+` WHERE d.id = $2 AND p.hidden_at IS NULL`+notBlocked+`
		ORDER BY p.created_at DESC, p.id OFFSET $3 LIMIT $4`, viewerID, designerID, offset, limit)
	if err != nil {
		return nil, err
	}
	return scanPosts(ctx, tx, rows, url)
}

func SavedPosts(ctx context.Context, tx pgx.Tx, viewerID string, offset, limit int, url MediaURL) ([]model.Post, error) {
	rows, err := tx.Query(ctx, `SELECT `+postCols+postFrom+` JOIN post_save sv ON sv.post_id = p.id AND sv.account_id = $1
		WHERE p.hidden_at IS NULL`+notBlocked+` ORDER BY sv.created_at DESC, p.id OFFSET $2 LIMIT $3`, viewerID, offset, limit)
	if err != nil {
		return nil, err
	}
	return scanPosts(ctx, tx, rows, url)
}

type NewPost struct {
	DesignerID     string
	Caption        string
	StyleTags      []string
	BasePriceCents *int64
	TurnaroundDays int
}

type NewPostMedia struct {
	Key     string
	AltText string
	Width   int
	Height  int
}

func InsertPost(ctx context.Context, tx pgx.Tx, p NewPost, media []NewPostMedia) (string, error) {
	var id string
	if p.StyleTags == nil {
		p.StyleTags = []string{}
	}
	err := tx.QueryRow(ctx, `INSERT INTO post (designer_id, caption, style_tags, base_price_cents, turnaround_days)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`, p.DesignerID, p.Caption, p.StyleTags, p.BasePriceCents, p.TurnaroundDays).Scan(&id)
	if err != nil {
		return "", err
	}
	for i, m := range media {
		if _, err := tx.Exec(ctx, `INSERT INTO post_media (post_id, position, object_key, alt_text, width, height)
			VALUES ($1, $2, $3, $4, $5, $6)`, id, i, m.Key, m.AltText, m.Width, m.Height); err != nil {
			return "", err
		}
	}
	return id, nil
}

// PostOwner returns a post's designer and its media keys.
func PostOwner(ctx context.Context, tx pgx.Tx, postID string) (designerID string, keys []string, err error) {
	if err = tx.QueryRow(ctx, `SELECT designer_id FROM post WHERE id = $1`, postID).Scan(&designerID); err != nil {
		return "", nil, translate(err)
	}
	keys, err = ids(ctx, tx, `SELECT object_key FROM post_media WHERE post_id = $1`, postID)
	return designerID, keys, err
}

func DeletePost(ctx context.Context, tx pgx.Tx, postID string) error {
	_, err := tx.Exec(ctx, `DELETE FROM post WHERE id = $1`, postID)
	return err
}

func HidePost(ctx context.Context, tx pgx.Tx, postID string) error {
	_, err := tx.Exec(ctx, `UPDATE post SET hidden_at = now() WHERE id = $1 AND hidden_at IS NULL`, postID)
	return err
}

func CountPostsToday(ctx context.Context, tx pgx.Tx, designerID string) (int, error) {
	var n int
	err := tx.QueryRow(ctx, `SELECT count(*) FROM post WHERE designer_id = $1 AND created_at > now() - interval '1 day'`, designerID).Scan(&n)
	return n, err
}

// PostAuthor is the account behind a post, for notifications and blocks.
type PostAuthor struct {
	DesignerID string
	AccountID  string
	Username   string
	Caption    string
	ThumbKey   *string
}

func GetPostAuthor(ctx context.Context, tx pgx.Tx, postID string) (*PostAuthor, error) {
	var p PostAuthor
	err := tx.QueryRow(ctx, `SELECT d.id, d.account_id, a.username, p.caption,
			(SELECT object_key FROM post_media m WHERE m.post_id = p.id ORDER BY position LIMIT 1)
		FROM post p JOIN designer_profile d ON d.id = p.designer_id JOIN account a ON a.id = d.account_id
		WHERE p.id = $1 AND p.hidden_at IS NULL AND a.suspended_at IS NULL`, postID).Scan(&p.DesignerID, &p.AccountID, &p.Username, &p.Caption, &p.ThumbKey)
	return &p, translate(err)
}

// SetLike toggles a like idempotently, keeping like_count in the same
// transaction (§5.2). It reports whether anything changed.
func SetLike(ctx context.Context, tx pgx.Tx, postID, accountID string, on bool) (bool, error) {
	var tag interface{ RowsAffected() int64 }
	var err error
	if on {
		tag, err = tx.Exec(ctx, `INSERT INTO post_like (post_id, account_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, postID, accountID)
	} else {
		tag, err = tx.Exec(ctx, `DELETE FROM post_like WHERE post_id = $1 AND account_id = $2`, postID, accountID)
	}
	if err != nil || tag.RowsAffected() == 0 {
		return false, err
	}
	delta := 1
	if !on {
		delta = -1
	}
	_, err = tx.Exec(ctx, `UPDATE post SET like_count = like_count + $2 WHERE id = $1`, postID, delta)
	return true, err
}

func SetSave(ctx context.Context, tx pgx.Tx, postID, accountID string, on bool) error {
	var err error
	if on {
		_, err = tx.Exec(ctx, `INSERT INTO post_save (post_id, account_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, postID, accountID)
	} else {
		_, err = tx.Exec(ctx, `DELETE FROM post_save WHERE post_id = $1 AND account_id = $2`, postID, accountID)
	}
	return err
}

// ── Comments ────────────────────────────────────────────────────────────

func ListComments(ctx context.Context, tx pgx.Tx, viewerID, postID string, offset, limit int) ([]model.Comment, error) {
	rows, err := tx.Query(ctx, `SELECT c.id, c.post_id, a.id, a.username, a.avatar_url, c.body, c.like_count, c.created_at
		FROM comment c JOIN account a ON a.id = c.author_id
		WHERE c.post_id = $2 AND NOT c.hidden_by_moderation AND a.suspended_at IS NULL
			AND NOT EXISTS (SELECT 1 FROM block b WHERE (b.blocker_id = $1 AND b.blocked_id = a.id) OR (b.blocker_id = a.id AND b.blocked_id = $1))
		ORDER BY c.created_at, c.id OFFSET $3 LIMIT $4`, viewerID, postID, offset, limit)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*model.Comment, error) {
		var c model.Comment
		return &c, r.Scan(&c.ID, &c.PostID, &c.Author.ID, &c.Author.Username, &c.Author.AvatarURL, &c.Body, &c.LikeCount, &c.CreatedAt)
	})
}

func InsertComment(ctx context.Context, tx pgx.Tx, postID, authorID, body string) (*model.Comment, error) {
	var c model.Comment
	err := tx.QueryRow(ctx, `WITH c AS (INSERT INTO comment (post_id, author_id, body) VALUES ($1, $2, $3)
			RETURNING id, post_id, author_id, body, like_count, created_at)
		SELECT c.id, c.post_id, a.id, a.username, a.avatar_url, c.body, c.like_count, c.created_at FROM c JOIN account a ON a.id = c.author_id`,
		postID, authorID, body).Scan(&c.ID, &c.PostID, &c.Author.ID, &c.Author.Username, &c.Author.AvatarURL, &c.Body, &c.LikeCount, &c.CreatedAt)
	if err != nil {
		return nil, err
	}
	_, err = tx.Exec(ctx, `UPDATE post SET comment_count = comment_count + 1 WHERE id = $1`, postID)
	return &c, err
}

// ── Follows, profiles, lists ────────────────────────────────────────────

// SetFollow toggles a follow idempotently; it reports whether it changed.
func SetFollow(ctx context.Context, tx pgx.Tx, followerID, designerID string, on bool) (bool, error) {
	var err error
	var tag interface{ RowsAffected() int64 }
	if on {
		tag, err = tx.Exec(ctx, `INSERT INTO follow (follower_id, designer_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, followerID, designerID)
	} else {
		tag, err = tx.Exec(ctx, `DELETE FROM follow WHERE follower_id = $1 AND designer_id = $2`, followerID, designerID)
	}
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() > 0, nil
}

func Follows(ctx context.Context, tx pgx.Tx, followerID, designerID string) (bool, error) {
	var on bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM follow WHERE follower_id = $1 AND designer_id = $2)`, followerID, designerID).Scan(&on)
	return on, err
}

// summaryCols builds a UserSummary row for account a, as seen by viewer $1.
const summaryCols = `a.username, a.display_name, a.avatar_url, coalesce(d.verified, false), d.id IS NOT NULL,
	nullif(trim(split_part(regexp_replace(coalesce(d.bio, ''), '·', '.', 'g'), '.', 1)), ''),
	d.id IS NOT NULL AND EXISTS (SELECT 1 FROM follow f WHERE f.follower_id = $1 AND f.designer_id = d.id)`

func scanSummaries(rows pgx.Rows) ([]model.UserSummary, error) {
	return collect(rows, func(r pgx.Row) (*model.UserSummary, error) {
		var u model.UserSummary
		return &u, r.Scan(&u.Username, &u.DisplayName, &u.AvatarURL, &u.Verified, &u.IsDesigner, &u.Meta, &u.ViewerFollows)
	})
}

func FollowersOf(ctx context.Context, tx pgx.Tx, viewerID, designerID string, offset, limit int) ([]model.UserSummary, error) {
	rows, err := tx.Query(ctx, `SELECT `+summaryCols+` FROM follow fo JOIN account a ON a.id = fo.follower_id
		LEFT JOIN designer_profile d ON d.account_id = a.id
		WHERE fo.designer_id = $2 AND a.suspended_at IS NULL ORDER BY fo.created_at DESC OFFSET $3 LIMIT $4`, viewerID, designerID, offset, limit)
	if err != nil {
		return nil, err
	}
	return scanSummaries(rows)
}

func FollowingOf(ctx context.Context, tx pgx.Tx, viewerID, accountID string, offset, limit int) ([]model.UserSummary, error) {
	rows, err := tx.Query(ctx, `SELECT `+summaryCols+` FROM follow fo JOIN designer_profile d ON d.id = fo.designer_id
		JOIN account a ON a.id = d.account_id
		WHERE fo.follower_id = $2 AND a.suspended_at IS NULL ORDER BY fo.created_at DESC OFFSET $3 LIMIT $4`, viewerID, accountID, offset, limit)
	if err != nil {
		return nil, err
	}
	return scanSummaries(rows)
}

// SuggestedDesigners are designers the viewer doesn't follow yet.
func SuggestedDesigners(ctx context.Context, tx pgx.Tx, viewerID string, offset, limit int) ([]model.UserSummary, error) {
	rows, err := tx.Query(ctx, `SELECT `+summaryCols+` FROM designer_profile d JOIN account a ON a.id = d.account_id
		WHERE a.id <> $1 AND a.suspended_at IS NULL
			AND NOT EXISTS (SELECT 1 FROM follow f WHERE f.follower_id = $1 AND f.designer_id = d.id)
			AND NOT EXISTS (SELECT 1 FROM block b WHERE (b.blocker_id = $1 AND b.blocked_id = a.id) OR (b.blocker_id = a.id AND b.blocked_id = $1))
		ORDER BY (SELECT count(*) FROM follow f WHERE f.designer_id = d.id) DESC, d.created_at DESC OFFSET $2 LIMIT $3`, viewerID, offset, limit)
	if err != nil {
		return nil, err
	}
	return scanSummaries(rows)
}

func SearchDesigners(ctx context.Context, tx pgx.Tx, viewerID, q string, offset, limit int) ([]model.UserSummary, error) {
	rows, err := tx.Query(ctx, `SELECT `+summaryCols+` FROM designer_profile d JOIN account a ON a.id = d.account_id
		WHERE a.suspended_at IS NULL AND (a.username ILIKE $2 OR d.display_name ILIKE $2 OR d.bio ILIKE $2)
			AND NOT EXISTS (SELECT 1 FROM block b WHERE (b.blocker_id = $1 AND b.blocked_id = a.id) OR (b.blocker_id = a.id AND b.blocked_id = $1))
		ORDER BY a.username OFFSET $3 LIMIT $4`, viewerID, "%"+escapeLike(strings.ToLower(q))+"%", offset, limit)
	if err != nil {
		return nil, err
	}
	return scanSummaries(rows)
}

// PublicAccount is a non-designer's public face (pages.md B6).
func PublicAccount(ctx context.Context, tx pgx.Tx, username string) (id string, acc model.ProfileAccount, err error) {
	err = tx.QueryRow(ctx, `SELECT id, username, display_name, avatar_url FROM account
		WHERE lower(username) = lower($1) AND suspended_at IS NULL`, username).Scan(&id, &acc.Username, &acc.DisplayName, &acc.AvatarURL)
	return id, acc, translate(err)
}

// ── Ranked-cursor snapshots ─────────────────────────────────────────────

func SaveSnapshot(ctx context.Context, tx pgx.Tx, accountID, fingerprint string, postIDs []string) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `INSERT INTO feed_snapshot (account_id, fingerprint, post_ids) VALUES ($1, $2, $3::uuid[]) RETURNING id`,
		accountID, fingerprint, postIDs).Scan(&id)
	return id, err
}

// LoadSnapshot returns a live (< 24 h) snapshot bound to this caller and
// query, or ErrNotFound.
func LoadSnapshot(ctx context.Context, tx pgx.Tx, id, accountID, fingerprint string) ([]string, error) {
	var out []string
	err := tx.QueryRow(ctx, `SELECT post_ids::text[] FROM feed_snapshot WHERE id::text = $1 AND account_id = $2 AND fingerprint = $3
		AND created_at > now() - interval '24 hours'`, id, accountID, fingerprint).Scan(&out)
	return out, translate(err)
}

func PruneSnapshots(ctx context.Context, tx pgx.Tx) (int64, error) {
	tag, err := tx.Exec(ctx, `DELETE FROM feed_snapshot WHERE created_at < now() - interval '24 hours'`)
	return tag.RowsAffected(), err
}

// ── Blocks ──────────────────────────────────────────────────────────────

func SetBlock(ctx context.Context, tx pgx.Tx, blockerID, blockedID string, on bool) error {
	var err error
	if on {
		_, err = tx.Exec(ctx, `INSERT INTO block (blocker_id, blocked_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, blockerID, blockedID)
	} else {
		_, err = tx.Exec(ctx, `DELETE FROM block WHERE blocker_id = $1 AND blocked_id = $2`, blockerID, blockedID)
	}
	return err
}

// Blocked reports a block in either direction.
func Blocked(ctx context.Context, tx pgx.Tx, a, b string) (bool, error) {
	var blocked bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM block WHERE (blocker_id = $1 AND blocked_id = $2) OR (blocker_id = $2 AND blocked_id = $1))`,
		a, b).Scan(&blocked)
	return blocked, err
}

// ── helpers ─────────────────────────────────────────────────────────────

func ids(ctx context.Context, tx pgx.Tx, sql string, args ...any) ([]string, error) {
	rows, err := tx.Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	return collect(rows, func(r pgx.Row) (*string, error) {
		var s string
		return &s, r.Scan(&s)
	})
}

func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}

func itoa(n int) string { return strconv.Itoa(n) }
