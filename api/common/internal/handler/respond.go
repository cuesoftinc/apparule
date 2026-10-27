// Package handler holds thin HTTP handlers: decode, call a service, encode.
package handler

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/cuesoftinc/apparule/api/common/internal/repository"
	"github.com/cuesoftinc/apparule/api/common/internal/service"
)

// writeJSON encodes v with status.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// writeError writes the ecosystem envelope {"error": {code, message, details}}.
func writeError(w http.ResponseWriter, status int, code, message string, details map[string]any) {
	if details == nil {
		details = map[string]any{}
	}
	writeJSON(w, status, map[string]any{"error": map[string]any{"code": code, "message": message, "details": details}})
}

// fail maps service and repository errors onto HTTP responses.
func fail(w http.ResponseWriter, r *http.Request, err error) {
	var apiErr *service.Error
	switch {
	case errors.As(err, &apiErr):
		if apiErr.RetryAfter > 0 {
			w.Header().Set("Retry-After", strconv.Itoa(max(1, int(apiErr.RetryAfter/time.Second))))
		}
		writeError(w, apiErr.Status, apiErr.Code, apiErr.Message, apiErr.Details)
	case errors.Is(err, repository.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found", "Not found", nil)
	case errors.Is(err, repository.ErrConflict):
		writeError(w, http.StatusConflict, "conflict", "That already exists", nil)
	default:
		slog.ErrorContext(r.Context(), "request failed", "path", r.URL.Path, "error", err)
		writeError(w, http.StatusInternalServerError, "internal", "Something went wrong", nil)
	}
}

// decode reads a JSON body into v. Unknown fields are ignored: the web and
// app send the mock's shapes, which can carry presentation-only fields.
func decode(w http.ResponseWriter, r *http.Request, v any) bool {
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20))
	if err := dec.Decode(v); err != nil {
		writeError(w, http.StatusUnprocessableEntity, "validation_failed", "Body must be JSON for this endpoint", nil)
		return false
	}
	return true
}

// paging reads ?cursor= and ?limit= (api.md §4: default 50, max 100).
func paging(r *http.Request) service.Paging {
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil || limit <= 0 {
		limit = 50
	}
	return service.Paging{Offset: service.DecodeOffset(r.URL.Query().Get("cursor")), Limit: min(limit, 100)}
}

func respond(w http.ResponseWriter, r *http.Request, status int, v any, err error) {
	if err != nil {
		fail(w, r, err)
		return
	}
	writeJSON(w, status, v)
}

func noContent(w http.ResponseWriter, r *http.Request, err error) {
	if err != nil {
		fail(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
