package handlers

import (
	"net/http"

	"canteen-backend/internal/database"
	"canteen-backend/internal/models"
	"github.com/gin-gonic/gin"
)

// CreateSupportTicket allows a student to raise a customer care query
func CreateSupportTicket(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)

	var req models.CreateTicketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ticket := models.SupportTicket{
		UserID:      userID,
		OrderID:     req.OrderID,
		TokenNumber: req.TokenNumber,
		Category:    req.Category,
		Subject:     req.Subject,
		Message:     req.Message,
		Status:      "OPEN",
	}

	if err := database.DB.Create(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to submit support ticket"})
		return
	}

	database.DB.Preload("User").First(&ticket, ticket.ID)
	c.JSON(http.StatusCreated, ticket)
}

// GetStudentSupportTickets returns all support tickets submitted by the logged in student
func GetStudentSupportTickets(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)

	var tickets []models.SupportTicket
	if err := database.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch support tickets"})
		return
	}

	c.JSON(http.StatusOK, tickets)
}
