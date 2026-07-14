// Package handler holds thin HTTP handlers that delegate to services.
package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Health responds with a liveness payload (migrated from the original /health).
func Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"message": "Apparule Backend Core running smoothly",
	})
}

// Ready responds with a readiness payload.
func Ready(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ready"})
}
