package handlers

import (
	"net/http"
	"strings"

	"canteen-backend/internal/database"
	"canteen-backend/internal/models"
	"github.com/gin-gonic/gin"
)

func GetMenu(c *gin.Context) {
	category := c.Query("category")
	search := c.Query("search")
	vegOnly := c.Query("veg_only")

	query := database.DB.Model(&models.FoodItem{})

	if category != "" && strings.ToLower(category) != "all" {
		query = query.Where("LOWER(category) = ?", strings.ToLower(category))
	}

	if search != "" {
		searchTerm := "%" + strings.ToLower(search) + "%"
		query = query.Where("LOWER(name) LIKE ? OR LOWER(description) LIKE ?", searchTerm, searchTerm)
	}

	if vegOnly == "true" {
		query = query.Where("is_veg = ?", true)
	}

	var foodItems []models.FoodItem
	if err := query.Find(&foodItems).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch menu items"})
		return
	}

	c.JSON(http.StatusOK, foodItems)
}

func GetMenuItem(c *gin.Context) {
	id := c.Param("id")

	var item models.FoodItem
	if err := database.DB.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Food item not found"})
		return
	}

	c.JSON(http.StatusOK, item)
}

func GetCategories(c *gin.Context) {
	type CategoryCount struct {
		Category string `json:"category"`
		Count    int    `json:"count"`
	}

	var results []CategoryCount
	database.DB.Model(&models.FoodItem{}).Select("category, count(*) as count").Group("category").Scan(&results)

	c.JSON(http.StatusOK, results)
}
