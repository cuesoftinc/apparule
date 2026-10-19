package service

import (
	"context"
	"net/http"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/cuesoftinc/apparule/api/common/internal/model"
	"github.com/cuesoftinc/apparule/api/common/internal/repository"
)

var reportKinds = map[string]bool{"post": true, "comment": true, "account": true}
var reportReasons = map[string]bool{"spam": true, "inappropriate": true, "counterfeit": true, "harassment": true, "other": true}

// FileReport records a report on a post, comment or account (SOC-009, A-6).
func (s *Services) FileReport(ctx context.Context, p *Principal, kind, subjectID, reason string, detail *string) (*model.Report, error) {
	if !reportKinds[kind] || subjectID == "" || !reportReasons[reason] {
		return nil, invalid("subject_kind, subject_id and reason are required")
	}
	if detail != nil && len(*detail) > 1000 {
		return nil, invalid("detail is at most 1000 characters")
	}
	var out *model.Report
	err := s.as(ctx, p, func(tx pgx.Tx) error {
		preview, thumbKey, _, err := repository.ReportSubject(ctx, tx, kind, subjectID)
		if err != nil {
			return err
		}
		preview.ThumbURL = s.thumb(thumbKey)
		out, err = repository.InsertReport(ctx, tx, p.AccountID, kind, subjectID, reason, detail, preview)
		return err
	})
	return out, err
}

func requireStaff(p *Principal) error {
	if !p.IsStaff {
		return newErr(http.StatusForbidden, "forbidden", "Moderation is staff-only")
	}
	return nil
}

// ModerationQueue is pages.md B7a (staff only).
func (s *Services) ModerationQueue(ctx context.Context, p *Principal, pg Paging) (any, error) {
	if err := requireStaff(p); err != nil {
		return nil, err
	}
	var list []model.Report
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		var err error
		list, err = repository.ModerationQueue(ctx, tx, pg.Offset, pg.Limit+1)
		return err
	})
	return page(list, pg), err
}

// ActOnReport hides a post or comment, suspends an account, or dismisses
// the report; the row keeps who did it and when (A-6 audit).
func (s *Services) ActOnReport(ctx context.Context, p *Principal, id, action string) (*model.Report, error) {
	if err := requireStaff(p); err != nil {
		return nil, err
	}
	if action != "hide_post" && action != "suspend_account" && action != "dismiss" {
		return nil, invalid("action must be hide_post, suspend_account or dismiss")
	}
	var out *model.Report
	err := s.DB.AsSystem(ctx, func(tx pgx.Tx) error {
		r, err := repository.GetReport(ctx, tx, id)
		if err != nil {
			return err
		}
		switch {
		case action == "hide_post" && r.SubjectKind == "post":
			err = repository.HidePost(ctx, tx, r.SubjectID)
		case action == "hide_post" && r.SubjectKind == "comment":
			err = repository.HideComment(ctx, tx, r.SubjectID)
		case action == "suspend_account":
			var authorID *string
			_, _, authorID, err = repository.ReportSubject(ctx, tx, r.SubjectKind, r.SubjectID)
			if err == nil && authorID != nil {
				err = repository.SuspendAccount(ctx, tx, *authorID)
			}
		}
		if err != nil {
			return err
		}
		if err := repository.ActOnReport(ctx, tx, id, action, p.AccountID); err != nil {
			return err
		}
		out, err = repository.GetReport(ctx, tx, id)
		return err
	})
	return out, err
}

// ExploreFilter parses explore's query (api.md §5).
func ExploreFilter(q, tags, band, turnaround, near string) repository.ExploreFilter {
	f := repository.ExploreFilter{Q: strings.TrimSpace(q)}
	for _, t := range strings.Split(tags, ",") {
		if t = strings.ToLower(strings.TrimSpace(t)); t != "" {
			f.Tags = append(f.Tags, t)
		}
	}
	if band == "budget" || band == "mid" || band == "premium" {
		f.PriceBand = band
	}
	if n := atoiPositive(turnaround); n > 0 {
		f.MaxTurnaroundDays = n
	}
	f.NearMe = near == "1" || near == "true"
	return f
}

func atoiPositive(s string) int {
	n := 0
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0
		}
		n = n*10 + int(r-'0')
		if n > 100_000 {
			return 0
		}
	}
	return n
}
