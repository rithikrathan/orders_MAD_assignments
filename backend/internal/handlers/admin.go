package handlers

import (
	"fmt"
	"net/http"
	"strings"

	"canteen-backend/internal/database"
	"canteen-backend/internal/models"
	"github.com/gin-gonic/gin"
)

// GetAdminOrders returns all orders across all students with filters
func GetAdminOrders(c *gin.Context) {
	status := c.Query("status")
	search := strings.TrimSpace(c.Query("search"))

	query := database.DB.Model(&models.Order{}).
		Preload("Items").
		Preload("User").
		Preload("Payment").
		Order("created_at desc")

	if status != "" && strings.ToUpper(status) != "ALL" {
		query = query.Where("status = ?", strings.ToUpper(status))
	}

	if search != "" {
		searchTerm := "%" + strings.ToLower(search) + "%"
		// Join User to search by roll no / student name or token number
		query = query.Joins("LEFT JOIN users ON users.id = orders.user_id").
			Where("LOWER(orders.token_number) LIKE ? OR LOWER(users.name) LIKE ? OR LOWER(users.student_id) LIKE ?", searchTerm, searchTerm, searchTerm)
	}

	var orders []models.Order
	if err := query.Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch orders"})
		return
	}

	c.JSON(http.StatusOK, orders)
}

// GetAdminStats returns aggregated dashboard metrics for kitchen & manager
func GetAdminStats(c *gin.Context) {
	var totalOrders int64
	var activeOrders int64
	var completedOrders int64
	var totalStudents int64
	var totalMenuItems int64
	var openTickets int64

	database.DB.Model(&models.Order{}).Count(&totalOrders)
	database.DB.Model(&models.Order{}).Where("status IN ?", []string{"PENDING", "PAID", "PREPARING", "READY_FOR_PICKUP"}).Count(&activeOrders)
	database.DB.Model(&models.Order{}).Where("status = ?", "COMPLETED").Count(&completedOrders)
	database.DB.Model(&models.User{}).Count(&totalStudents)
	database.DB.Model(&models.FoodItem{}).Count(&totalMenuItems)
	database.DB.Model(&models.SupportTicket{}).Where("status IN ?", []string{"OPEN", "IN_PROGRESS"}).Count(&openTickets)

	// Revenue sum for paid/completed orders
	var totalRevenue float64
	row := database.DB.Model(&models.Order{}).Where("payment_status = ?", "PAID").Select("COALESCE(SUM(total_amount), 0)").Row()
	_ = row.Scan(&totalRevenue)

	// Category counts
	type CatCount struct {
		Category string
		Count    int
	}
	var catResults []CatCount
	database.DB.Model(&models.FoodItem{}).Select("category, count(*) as count").Group("category").Scan(&catResults)
	catMap := make(map[string]int)
	for _, cr := range catResults {
		catMap[cr.Category] = cr.Count
	}

	c.JSON(http.StatusOK, models.AdminStatsResponse{
		TotalRevenue:    totalRevenue,
		TotalOrders:     totalOrders,
		ActiveOrders:    activeOrders,
		CompletedOrders: completedOrders,
		TotalStudents:   totalStudents,
		TotalMenuItems:  totalMenuItems,
		OpenTickets:     openTickets,
		CategoryCounts:  catMap,
	})
}

// CreateFoodItem adds a new dish to the menu
func CreateFoodItem(c *gin.Context) {
	var req models.SaveFoodItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.ImageURL == "" {
		req.ImageURL = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop"
	}
	if req.Rating == 0 {
		req.Rating = 4.5
	}
	if req.PrepTimeMinutes == 0 {
		req.PrepTimeMinutes = 10
	}

	item := models.FoodItem{
		Name:            strings.TrimSpace(req.Name),
		Category:        strings.TrimSpace(req.Category),
		Price:           req.Price,
		IsVeg:           req.IsVeg,
		IsAvailable:     req.IsAvailable,
		Description:     strings.TrimSpace(req.Description),
		Rating:          req.Rating,
		PrepTimeMinutes: req.PrepTimeMinutes,
		ImageURL:        req.ImageURL,
		Calories:        req.Calories,
	}

	if err := database.DB.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create food item"})
		return
	}

	c.JSON(http.StatusCreated, item)
}

// UpdateFoodItem edits an existing menu dish
func UpdateFoodItem(c *gin.Context) {
	id := c.Param("id")
	var item models.FoodItem
	if err := database.DB.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Food item not found"})
		return
	}

	var req models.SaveFoodItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	item.Name = strings.TrimSpace(req.Name)
	item.Category = strings.TrimSpace(req.Category)
	item.Price = req.Price
	item.IsVeg = req.IsVeg
	item.IsAvailable = req.IsAvailable
	item.Description = strings.TrimSpace(req.Description)
	if req.Rating > 0 {
		item.Rating = req.Rating
	}
	if req.PrepTimeMinutes > 0 {
		item.PrepTimeMinutes = req.PrepTimeMinutes
	}
	if req.ImageURL != "" {
		item.ImageURL = req.ImageURL
	}
	if req.Calories > 0 {
		item.Calories = req.Calories
	}

	if err := database.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update food item"})
		return
	}

	c.JSON(http.StatusOK, item)
}

// DeleteFoodItem deletes a dish from the menu
func DeleteFoodItem(c *gin.Context) {
	id := c.Param("id")
	var item models.FoodItem
	if err := database.DB.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Food item not found"})
		return
	}

	if err := database.DB.Delete(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete food item"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("'%s' was deleted successfully", item.Name)})
}

// ToggleFoodItemAvailability toggles between in-stock and out-of-stock
func ToggleFoodItemAvailability(c *gin.Context) {
	id := c.Param("id")
	var item models.FoodItem
	if err := database.DB.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Food item not found"})
		return
	}

	item.IsAvailable = !item.IsAvailable
	if err := database.DB.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update availability"})
		return
	}

	c.JSON(http.StatusOK, item)
}

// GetAdminSupportTickets returns all student customer care queries
func GetAdminSupportTickets(c *gin.Context) {
	status := c.Query("status")
	query := database.DB.Model(&models.SupportTicket{}).Preload("User").Order("created_at desc")

	if status != "" && strings.ToUpper(status) != "ALL" {
		query = query.Where("status = ?", strings.ToUpper(status))
	}

	var tickets []models.SupportTicket
	if err := query.Find(&tickets).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch support tickets"})
		return
	}

	c.JSON(http.StatusOK, tickets)
}

// UpdateAdminSupportTicket responds to a student and updates status
func UpdateAdminSupportTicket(c *gin.Context) {
	id := c.Param("id")
	var ticket models.SupportTicket
	if err := database.DB.First(&ticket, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Support ticket not found"})
		return
	}

	var req models.UpdateTicketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.AdminReply != "" {
		ticket.AdminReply = req.AdminReply
	}
	if req.Status != "" {
		ticket.Status = strings.ToUpper(req.Status)
	}

	if err := database.DB.Save(&ticket).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update support ticket"})
		return
	}

	database.DB.Preload("User").First(&ticket, ticket.ID)
	c.JSON(http.StatusOK, ticket)
}

// GetAdminStudents returns registered students and their meal card balances
func GetAdminStudents(c *gin.Context) {
	var users []models.User
	if err := database.DB.Order("name asc").Find(&users).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch students"})
		return
	}

	c.JSON(http.StatusOK, users)
}

// AdjustStudentWallet credits or refunds a student's canteen wallet
func AdjustStudentWallet(c *gin.Context) {
	var req models.AdjustWalletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ident := strings.TrimSpace(req.StudentIDOrEmail)
	var user models.User
	if err := database.DB.Where("LOWER(email) = ? OR UPPER(student_id) = ?", strings.ToLower(ident), strings.ToUpper(ident)).First(&user).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Student not found with specified Roll No or Email"})
		return
	}

	user.WalletBalance += req.Amount
	if user.WalletBalance < 0 {
		user.WalletBalance = 0
	}

	if err := database.DB.Save(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update wallet balance"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": fmt.Sprintf("Successfully adjusted ₹%.2f to %s's wallet", req.Amount, user.Name),
		"user":    user,
		"reason":  req.Reason,
	})
}
