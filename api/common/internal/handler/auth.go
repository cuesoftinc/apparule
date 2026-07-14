package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/cuesoftinc/apparule/api/common/internal/auth"
)

// AuthHandler exposes authentication endpoints backed by the auth service.
type AuthHandler struct {
	auth *auth.Service
}

// NewAuthHandler wires an AuthHandler to the auth service.
func NewAuthHandler(a *auth.Service) *AuthHandler { return &AuthHandler{auth: a} }

type googleAuthRequest struct {
	IDToken string `json:"id_token"`
}

type emailAuthRequest struct {
	Email string `json:"email"`
}

// Google handles POST /api/auth/google (migrated from handleGoogleLogin).
func (h *AuthHandler) Google(c *gin.Context) {
	var req googleAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.IDToken == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing valid id_token payload"})
		return
	}

	token, err := h.auth.GoogleLogin(req.IDToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to issue backend security token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Validated through cloud configuration pipeline",
		"project": h.auth.ProjectID(),
		"token":   token,
	})
}

// Email handles POST /api/auth/email (migrated from handleEmailLogin).
func (h *AuthHandler) Email(c *gin.Context) {
	var req emailAuthRequest
	if err := c.ShouldBindJSON(&req); err != nil || req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "A valid email address is required"})
		return
	}

	h.auth.EmailLogin(req.Email)

	c.JSON(http.StatusOK, gin.H{
		"message": "Authentication link routed through cloud instance gateway",
		"email":   req.Email,
		"scope":   h.auth.ProjectID(),
	})
}
