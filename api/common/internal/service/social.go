package service

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/ratelimit"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

// rankDepth bounds a ranked snapshot (api.md §5): deeper scrolls start over.
const rankDepth = 1000

// RankedPage serves feed and explore from a rank frozen at the first page
// for the cursor's 24 h life, so pages never duplicate or skip mid-scroll
// (api.md §5 [Decided]). Engagement state stays live; only the order is
// frozen. A cursor is bound to its caller and query; anything else starts
// a fresh scroll.
func (s *Services) rankedPage(ctx context.Context, p *Principal, fingerprint, cursor string, limit int,
	rank func(tx pgx.Tx) ([]string, error)) (model.Page[model.Post], error) {
	var out model.Page[model.Post]
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		snapshotID, offset := "", 0
		var ids []string
		if raw, err := base64.RawURLEncoding.DecodeString(cursor); err == nil && cursor != "" {
			if id, off, ok := strings.Cut(string(raw), ":"); ok {
				if n, err := strconv.Atoi(off); err == nil && n >= 0 {
					if list, err := repository.LoadSnapshot(ctx, tx, id, p.AccountID, fingerprint); err == nil {
						snapshotID, offset, ids = id, n, list
					}
				}
			}
		}
		if snapshotID == "" {
			list, err := rank(tx)
			if err != nil {
				return err
			}
			if snapshotID, err = repository.SaveSnapshot(ctx, tx, p.AccountID, fingerprint, list); err != nil {
				return err
			}
			ids = list
		}
		end := min(offset+limit, len(ids))
		if offset > end {
			offset = end
		}
		posts, err := repository.PostsByIDs(ctx, tx, p.AccountID, ids[offset:end], s.mediaURL)
		if err != nil {
			return err
		}
		out.Items = posts
		if end < len(ids) {
			next := base64.RawURLEncoding.EncodeToString([]byte(fmt.Sprintf("%s:%d", snapshotID, end)))
			out.NextCursor = &next
		}
		return nil
	})
	if out.Items == nil {
		out.Items = []model.Post{}
	}
	return out, err
}

// Feed is followed designers' posts, newest first (api.md §5).
func (s *Services) Feed(ctx context.Context, p *Principal, cursor string, limit int) (model.Page[model.Post], error) {
	return s.rankedPage(ctx, p, "feed", cursor, limit, func(tx pgx.Tx) ([]string, error) {
		return repository.FeedIDs(ctx, tx, p.AccountID, rankDepth)
	})
}

func (s *Services) Explore(ctx context.Context, p *Principal, f repository.ExploreFilter, cursor string, limit int) (model.Page[model.Post], error) {
	near := ""
	if f.NearMe {
		near = "1"
	}
	turnaround := ""
	if f.MaxTurnaroundDays > 0 {
		turnaround = strconv.Itoa(f.MaxTurnaroundDays)
	}
	fingerprint := strings.Join([]string{"explore", f.Q, strings.Join(f.Tags, ","), f.PriceBand, turnaround, near}, "|")
	return s.rankedPage(ctx, p, fingerprint, cursor, limit, func(tx pgx.Tx) ([]string, error) {
		var home *model.Location
		if f.NearMe {
			a, err := repository.GetAccount(ctx, tx, p.AccountID)
			if err != nil {
				return nil, err
			}
			home = a.ProfileLocation
		}
		return repository.ExploreIDs(ctx, tx, p.AccountID, f, home, rankDepth)
	})
}

func (s *Services) Post(ctx context.Context, p *Principal, id string) (*model.Post, error) {
	var out *model.Post
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		out, err = repository.GetPost(ctx, tx, p.AccountID, id, s.mediaURL)
		return err
	})
	return out, err
}

// PostInput is POST /posts. Media items name uploaded media by id, or by
// the URL a media batch returned (the mock's {url, alt_text} shape).
type PostInput struct {
	Caption        string   `json:"caption"`
	StyleTags      []string `json:"style_tags"`
	BasePriceCents *int64   `json:"base_price_cents"`
	TurnaroundDays *int     `json:"turnaround_days"`
	Media          []struct {
		MediaID string `json:"media_id"`
		URL     string `json:"url"`
		AltText string `json:"alt_text"`
	} `json:"media"`
}

// CreatePost publishes a designer's post from uploaded media. Posting is
// allowed before KYC; accepting requests is not (flows/designer.md §1).
func (s *Services) CreatePost(ctx context.Context, p *Principal, in PostInput) (*model.Post, error) {
	designerID, err := requireDesigner(p, "Enable a designer profile to post")
	if err != nil {
		return nil, err
	}
	if err := active(p); err != nil {
		return nil, err
	}
	in.Caption = strings.TrimSpace(in.Caption)
	if in.Caption == "" || len([]rune(in.Caption)) > 500 {
		return nil, invalid("Caption must be 1-500 characters")
	}
	if len(in.Media) == 0 || len(in.Media) > 10 {
		return nil, invalid("Posts carry 1-10 images")
	}
	turnaround := 14
	if in.TurnaroundDays != nil {
		turnaround = *in.TurnaroundDays
	}
	if turnaround < 1 || turnaround > 365 {
		return nil, invalid("turnaround_days must be 1-365")
	}
	if in.BasePriceCents != nil && *in.BasePriceCents <= 0 {
		return nil, invalid("base_price_cents must be positive or null")
	}
	tags := make([]string, 0, len(in.StyleTags))
	for _, t := range in.StyleTags {
		if t = strings.ToLower(strings.TrimSpace(t)); t != "" && len(tags) < 10 {
			tags = append(tags, t)
		}
	}
	ids := make([]string, len(in.Media))
	for i, m := range in.Media {
		ids[i] = m.MediaID
		if ids[i] == "" {
			ids[i] = mediaIDFromURL(m.URL)
		}
	}
	var postID string
	var moves [][2]string
	err = s.as(ctx, p, func(tx pgx.Tx) error {
		n, err := repository.CountPostsToday(ctx, tx, designerID)
		if err != nil {
			return err
		}
		if n >= s.Config.Limits.PostsPerDay {
			return rateLimited(time.Hour, "You've posted the most for today")
		}
		media, err := repository.GetMedia(ctx, tx, ids)
		if err != nil {
			return err
		}
		byID := map[string]repository.MediaRow{}
		for _, m := range media {
			byID[m.ID] = m
		}
		display, err := repository.DesignerByID(ctx, tx, designerID)
		if err != nil {
			return err
		}
		items := make([]repository.NewPostMedia, len(ids))
		for i, id := range ids {
			m, ok := byID[id]
			if !ok || m.AccountID != p.AccountID || m.Kind != "post_media" || m.Stage != "tmp" {
				return invalid("Every image must be one you uploaded for this post")
			}
			alt := strings.TrimSpace(in.Media[i].AltText)
			if alt == "" {
				alt = "Outfit by " + display.DisplayName // design.md §5 default
			}
			items[i] = repository.NewPostMedia{Key: m.Key, AltText: alt, Width: m.Width, Height: m.Height}
		}
		postID, err = repository.InsertPost(ctx, tx, repository.NewPost{
			DesignerID: designerID, Caption: in.Caption, StyleTags: tags, BasePriceCents: in.BasePriceCents, TurnaroundDays: turnaround,
		}, items)
		if err != nil {
			return err
		}
		// Published images move to the public media/ prefix (§5.1).
		for i, id := range ids {
			dst := fmt.Sprintf("%s/media/%s/%d.jpg", s.Store.Prefix(), postID, i)
			moves = append(moves, [2]string{items[i].Key, dst})
			if err := s.Store.Copy(ctx, items[i].Key, dst); err != nil {
				return err
			}
			if err := repository.ConfirmMedia(ctx, tx, id, dst); err != nil {
				return err
			}
			if _, err := tx.Exec(ctx, `UPDATE post_media SET object_key = $3 WHERE post_id = $1 AND position = $2`, postID, i, dst); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	for _, m := range moves {
		_ = s.Store.Delete(ctx, m[0])
	}
	return s.Post(ctx, p, postID)
}

// mediaIDFromURL accepts .../media/{id} as the mock's composer returns it.
func mediaIDFromURL(u string) string {
	u = strings.TrimRight(u, "/")
	return u[strings.LastIndex(u, "/")+1:]
}

func (s *Services) DeletePost(ctx context.Context, p *Principal, id string) error {
	var keys []string
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		designerID, k, err := repository.PostOwner(ctx, tx, id)
		if err != nil {
			return err
		}
		if p.DesignerID == nil || *p.DesignerID != designerID {
			return newErr(403, "forbidden", "Only the author can delete")
		}
		keys = k
		return repository.DeletePost(ctx, tx, id)
	})
	if err == nil {
		for _, k := range keys {
			_ = s.Store.Delete(ctx, k)
		}
	}
	return err
}

// SetLike and SetSave are idempotent toggles (MI-18).
func (s *Services) SetLike(ctx context.Context, p *Principal, postID string, on bool) error {
	if err := s.take(ctx, p, ratelimit.Rule{Name: "social", Max: int64(s.Config.Limits.SocialPerMin), Window: time.Minute}); err != nil {
		return nil // over the limit, idempotent toggles are absorbed silently (engineering.md §3)
	}
	return s.as(ctx, p, func(tx pgx.Tx) error {
		author, err := s.visiblePost(ctx, tx, p, postID)
		if err != nil {
			return err
		}
		changed, err := repository.SetLike(ctx, tx, postID, p.AccountID, on)
		if err != nil || !changed || !on || author.AccountID == p.AccountID {
			return err
		}
		return notify(ctx, tx, note{To: author.AccountID, Kind: "like", PayloadRef: postID, RefKind: "post",
			Text: p.Username + " liked your post", Actor: s.actor(ctx, tx, p), ThumbURL: s.thumb(author.ThumbKey)})
	})
}

func (s *Services) SetSave(ctx context.Context, p *Principal, postID string, on bool) error {
	if err := s.take(ctx, p, ratelimit.Rule{Name: "social", Max: int64(s.Config.Limits.SocialPerMin), Window: time.Minute}); err != nil {
		return nil
	}
	return s.as(ctx, p, func(tx pgx.Tx) error {
		if _, err := s.visiblePost(ctx, tx, p, postID); err != nil {
			return err
		}
		return repository.SetSave(ctx, tx, postID, p.AccountID, on)
	})
}

// visiblePost returns a post's author, or not_found when the post is gone
// or a block stands between the caller and its author.
func (s *Services) visiblePost(ctx context.Context, tx pgx.Tx, p *Principal, postID string) (*repository.PostAuthor, error) {
	author, err := repository.GetPostAuthor(ctx, tx, postID)
	if err != nil {
		return nil, err
	}
	blocked, err := repository.Blocked(ctx, tx, p.AccountID, author.AccountID)
	if err != nil {
		return nil, err
	}
	if blocked {
		return nil, repository.ErrNotFound
	}
	return author, nil
}

func (s *Services) Comments(ctx context.Context, p *Principal, postID string, pg Paging) (any, error) {
	var list []model.Comment
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if _, err := s.visiblePost(ctx, tx, p, postID); err != nil {
			return err
		}
		var err error
		list, err = repository.ListComments(ctx, tx, p.AccountID, postID, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

func (s *Services) AddComment(ctx context.Context, p *Principal, postID, body string) (*model.Comment, error) {
	body = strings.TrimSpace(body)
	if body == "" || len([]rune(body)) > 500 {
		return nil, invalid("Comment body must be 1-500 characters")
	}
	if err := active(p); err != nil {
		return nil, err
	}
	if err := s.take(ctx, p, ratelimit.Rule{Name: "comment", Max: int64(s.Config.Limits.CommentsPerMin), Window: time.Minute}); err != nil {
		return nil, err
	}
	var out *model.Comment
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		author, err := s.visiblePost(ctx, tx, p, postID)
		if err != nil {
			return err
		}
		if out, err = repository.InsertComment(ctx, tx, postID, p.AccountID, body); err != nil {
			return err
		}
		if author.AccountID == p.AccountID {
			return nil
		}
		return notify(ctx, tx, note{To: author.AccountID, Kind: "comment", PayloadRef: postID, RefKind: "post",
			Text: p.Username + " commented on your post", Actor: s.actor(ctx, tx, p), ThumbURL: s.thumb(author.ThumbKey)})
	})
	return out, err
}

// ── Profiles and follows (pages.md B6, B2) ──────────────────────────────

func (s *Services) Profile(ctx context.Context, p *Principal, username string) (*model.PublicProfile, error) {
	var out *model.PublicProfile
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByUsername(ctx, tx, username)
		if err == nil {
			if err := hidden(repository.Blocked(ctx, tx, p.AccountID, d.AccountID)); err != nil {
				return err
			}
			follows, err := repository.Follows(ctx, tx, p.AccountID, d.ID)
			if err != nil {
				return err
			}
			profile := publicDesigner(d)
			out = &model.PublicProfile{Kind: "designer", Designer: &profile, ViewerFollows: &follows, ViewerIsSelf: d.AccountID == p.AccountID}
			return nil
		}
		if !errors.Is(err, repository.ErrNotFound) {
			return err
		}
		id, acc, err := repository.PublicAccount(ctx, tx, username)
		if err != nil {
			return err
		}
		if err := hidden(repository.Blocked(ctx, tx, p.AccountID, id)); err != nil {
			return err
		}
		out = &model.PublicProfile{Kind: "user", Account: &acc, ViewerIsSelf: id == p.AccountID}
		return nil
	})
	return out, err
}

// publicDesigner hides the payout details of someone else's profile.
func publicDesigner(d *repository.DesignerRow) model.DesignerProfile {
	out := d.DesignerProfile
	out.PayoutAccount = model.PayoutAccount{KYCState: d.PayoutAccount.KYCState}
	return out
}

func (s *Services) ProfilePosts(ctx context.Context, p *Principal, username string, pg Paging) (any, error) {
	var list []model.Post
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByUsername(ctx, tx, username)
		if errors.Is(err, repository.ErrNotFound) {
			// A regular user has no posts, but exists.
			_, _, err = repository.PublicAccount(ctx, tx, username)
			return err
		}
		if err != nil {
			return err
		}
		list, err = repository.PostsByDesigner(ctx, tx, p.AccountID, d.ID, pg.Offset, pg.Limit+1, s.mediaURL)
		return err
	})
	return page(list, pg), err
}

func (s *Services) SavedPosts(ctx context.Context, p *Principal, pg Paging) (any, error) {
	var list []model.Post
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		list, err = repository.SavedPosts(ctx, tx, p.AccountID, pg.Offset, pg.Limit+1, s.mediaURL)
		return err
	})
	return page(list, pg), err
}

func (s *Services) Followers(ctx context.Context, p *Principal, username string, pg Paging) (any, error) {
	var list []model.UserSummary
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByUsername(ctx, tx, username)
		if err != nil {
			return err
		}
		list, err = repository.FollowersOf(ctx, tx, p.AccountID, d.ID, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

func (s *Services) Following(ctx context.Context, p *Principal, username string, pg Paging) (any, error) {
	var list []model.UserSummary
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		id, err := repository.AccountByUsername(ctx, tx, username)
		if err != nil {
			return err
		}
		list, err = repository.FollowingOf(ctx, tx, p.AccountID, id, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

func (s *Services) SuggestedDesigners(ctx context.Context, p *Principal, pg Paging) (any, error) {
	var list []model.UserSummary
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		list, err = repository.SuggestedDesigners(ctx, tx, p.AccountID, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

func (s *Services) SearchDesigners(ctx context.Context, p *Principal, q string, pg Paging) (any, error) {
	var list []model.UserSummary
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		var err error
		list, err = repository.SearchDesigners(ctx, tx, p.AccountID, q, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

// SetFollow toggles a follow (MI-7). Blocked pairs can't follow.
func (s *Services) SetFollow(ctx context.Context, p *Principal, username string, on bool) error {
	if err := s.take(ctx, p, ratelimit.Rule{Name: "social", Max: int64(s.Config.Limits.SocialPerMin), Window: time.Minute}); err != nil {
		return nil
	}
	return s.as(ctx, p, func(tx pgx.Tx) error {
		d, err := repository.DesignerByUsername(ctx, tx, username)
		if err != nil {
			return err
		}
		if on {
			if err := hidden(repository.Blocked(ctx, tx, p.AccountID, d.AccountID)); err != nil {
				return err
			}
			if d.AccountID == p.AccountID {
				return invalid("You can't follow yourself")
			}
		}
		changed, err := repository.SetFollow(ctx, tx, p.AccountID, d.ID, on)
		if err != nil || !changed || !on {
			return err
		}
		return notify(ctx, tx, note{To: d.AccountID, Kind: "follow", PayloadRef: p.Username, RefKind: "account",
			Text: p.Username + " started following you", Actor: s.actor(ctx, tx, p)})
	})
}

// SetBlock is silent (data-model.md §6.2): no notification. Blocking also
// drops follows in both directions.
func (s *Services) SetBlock(ctx context.Context, p *Principal, username string, on bool) error {
	return s.as(ctx, p, func(tx pgx.Tx) error {
		id, err := repository.AccountByUsername(ctx, tx, username)
		if err != nil {
			return err
		}
		if id == p.AccountID {
			return invalid("You can't block yourself")
		}
		if err := repository.SetBlock(ctx, tx, p.AccountID, id, on); err != nil || !on {
			return err
		}
		_, err = tx.Exec(ctx, `DELETE FROM follow f USING designer_profile d WHERE f.designer_id = d.id AND
			((f.follower_id = $1 AND d.account_id = $2) OR (f.follower_id = $2 AND d.account_id = $1))`, p.AccountID, id)
		return err
	})
}

func (s *Services) actor(ctx context.Context, tx pgx.Tx, p *Principal) *model.Actor {
	a, err := repository.LoadAccountNotify(ctx, tx, p.AccountID)
	if err != nil {
		return &model.Actor{Username: p.Username}
	}
	return &model.Actor{Username: a.Username, AvatarURL: a.AvatarURL}
}

func (s *Services) thumb(key *string) *string {
	if key == nil {
		return nil
	}
	u := s.mediaURL(*key)
	return &u
}

// ── Media batches (create-then-upload for post media and attachments) ──

// StartPostMedia reserves a batch for the composer's images and returns its
// upload ticket (system-design.md §6.1).
func (s *Services) StartPostMedia(ctx context.Context, p *Principal, count int) (*model.MediaBatch, error) {
	if _, err := requireDesigner(p, "Enable a designer profile to post"); err != nil {
		return nil, err
	}
	if count < 1 || count > 10 {
		return nil, invalid("count must be 1-10")
	}
	return s.startBatch(ctx, p, "post_media", nil, count)
}

func (s *Services) startBatch(ctx context.Context, p *Principal, kind string, requestID *string, count int) (*model.MediaBatch, error) {
	if err := active(p); err != nil {
		return nil, err
	}
	var out *model.MediaBatch
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		if err := s.checkQuota(ctx, tx, p); err != nil {
			return err
		}
		id, err := repository.InsertMediaBatch(ctx, tx, p.AccountID, kind, requestID)
		if err != nil {
			return err
		}
		upload, err := s.issueTicket(ctx, tx, ticketRequest(p.AccountID, kind, id, count, s.Config.Limits.ImageMaxBytes))
		if err != nil {
			return err
		}
		out = &model.MediaBatch{ID: id, Kind: kind, Status: "awaiting_upload", Items: []model.MediaItem{}, Upload: upload}
		return nil
	})
	return out, err
}

// MediaBatch is polled by the client after its upload.
func (s *Services) MediaBatch(ctx context.Context, p *Principal, id string) (*model.MediaBatch, error) {
	var out *model.MediaBatch
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		b, err := repository.GetMediaBatch(ctx, tx, id)
		if err != nil {
			return err
		}
		if b.AccountID != p.AccountID {
			return repository.ErrNotFound
		}
		out = &model.MediaBatch{ID: b.ID, Kind: b.Kind, Status: b.Status, Items: []model.MediaItem{}}
		for _, m := range b.Items {
			url, err := s.Store.SignedURL(ctx, m.Key, time.Hour)
			if err != nil {
				return err
			}
			out.Items = append(out.Items, model.MediaItem{ID: m.ID, URL: url, Width: m.Width, Height: m.Height})
		}
		return nil
	})
	return out, err
}

// OnMediaUploaded stores a batch's images (media.uploaded).
func (s *Services) OnMediaUploaded(ctx context.Context, raw json.RawMessage) error {
	var msg struct {
		TicketID  string `json:"ticket_id"`
		AccountID string `json:"account_id"`
		Target    struct {
			Kind string `json:"kind"`
			ID   string `json:"id"`
		} `json:"target"`
		Images []imageRef `json:"images"`
	}
	if err := jsonUnmarshal(raw, &msg); err != nil {
		return err
	}
	return s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		t, err := repository.UseTicket(ctx, tx, msg.TicketID)
		if errors.Is(err, repository.ErrNotFound) {
			return nil
		}
		if err != nil {
			return err
		}
		if t.TargetID != msg.Target.ID || t.AccountID != msg.AccountID || t.TargetKind != msg.Target.Kind {
			return nil
		}
		rows := make([]repository.MediaRow, len(msg.Images))
		for i, img := range msg.Images {
			rows[i] = repository.MediaRow{AccountID: msg.AccountID, Kind: msg.Target.Kind, Key: img.Object.Key,
				Width: img.Width, Height: img.Height, Size: img.Object.Size}
		}
		_, err = repository.FillMediaBatch(ctx, tx, msg.Target.ID, rows)
		return err
	})
}
