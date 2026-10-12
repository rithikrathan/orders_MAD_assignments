package handlers

import (
	"fmt"
	"math"
	"math/rand"
	"net/http"
	"time"

	"canteen-backend/internal/database"
	"canteen-backend/internal/models"
	"github.com/gin-gonic/gin"
)

func generateTokenNumber() string {
	// e.g. #C-348
	randNum := rand.Intn(900) + 100
	return fmt.Sprintf("#C-%d", randNum)
}

func CreateOrder(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)

	var req models.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if len(req.Items) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order must contain at least one item"})
		return
	}

	// Fetch food items and compute totals
	var subtotal float64
	var orderItems []models.OrderItem

	for _, itemInput := range req.Items {
		var foodItem models.FoodItem
		if err := database.DB.First(&foodItem, itemInput.FoodItemID).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Food item with ID %d not found", itemInput.FoodItemID)})
			return
		}

		if !foodItem.IsAvailable {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("'%s' is currently unavailable", foodItem.Name)})
			return
		}

		itemTotal := foodItem.Price * float64(itemInput.Quantity)
		subtotal += itemTotal

		orderItems = append(orderItems, models.OrderItem{
			FoodItemID: foodItem.ID,
			FoodName:   foodItem.Name,
			Quantity:   itemInput.Quantity,
			UnitPrice:  foodItem.Price,
			TotalPrice: itemTotal,
		})
	}

	tax := math.Round((subtotal*0.05)*100) / 100 // 5% GST
	packagingFee := 10.00
	discount := 0.00
	totalAmount := subtotal + tax + packagingFee - discount

	order := models.Order{
		UserID:        userID,
		TokenNumber:   generateTokenNumber(),
		Subtotal:      subtotal,
		Tax:           tax,
		PackagingFee:  packagingFee,
		Discount:      discount,
		TotalAmount:   totalAmount,
		Status:        models.StatusPending,
		PaymentMethod: req.PaymentMethod,
		PaymentStatus: "UNPAID",
		SpecialNotes:  req.SpecialNotes,
		Items:         orderItems,
	}

	if err := database.DB.Create(&order).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create order"})
		return
	}

	// Preload items and return
	database.DB.Preload("Items").Preload("Payment").First(&order, order.ID)
	c.JSON(http.StatusCreated, order)
}

func GetOrders(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)

	var orders []models.Order
	if err := database.DB.Where("user_id = ?", userID).Preload("Items").Preload("Payment").Order("created_at desc").Find(&orders).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch orders"})
		return
	}

	c.JSON(http.StatusOK, orders)
}

func GetOrderByID(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)
	orderID := c.Param("id")

	var order models.Order
	if err := database.DB.Where("id = ? AND user_id = ?", orderID, userID).Preload("Items").Preload("Payment").First(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	c.JSON(http.StatusOK, order)
}

func ProcessPayment(c *gin.Context) {
	userIDVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	userID := userIDVal.(uint)
	orderID := c.Param("id")

	var req models.PaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.Where("id = ? AND user_id = ?", orderID, userID).First(&order).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	if order.PaymentStatus == "PAID" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Order is already paid"})
		return
	}

	// If paying with Student Wallet, verify balance and deduct
	if req.PaymentMethod == "WALLET" {
		var user models.User
		if err := database.DB.First(&user, userID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			return
		}

		if user.WalletBalance < order.TotalAmount {
			c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Insufficient wallet balance (Available: ₹%.2f, Required: ₹%.2f)", user.WalletBalance, order.TotalAmount)})
			return
		}

		user.WalletBalance -= order.TotalAmount
		database.DB.Save(&user)
	}

	// Generate realistic Mock Transaction ID
	txnID := fmt.Sprintf("TXN-CAN-%d-%d", order.ID, time.Now().Unix())

	payment := models.Payment{
		OrderID:       order.ID,
		PaymentMethod: req.PaymentMethod,
		TransactionID: txnID,
		Amount:        order.TotalAmount,
		Status:        "SUCCESS",
	}

	if err := database.DB.Create(&payment).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record payment"})
		return
	}

	// Update order
	order.PaymentStatus = "PAID"
	order.Status = models.StatusPreparing // Kitchen receives order immediately
	order.PaymentMethod = req.PaymentMethod
	database.DB.Save(&order)

	database.DB.Preload("Items").Preload("Payment").First(&order, order.ID)
	c.JSON(http.StatusOK, gin.H{
		"message": "Payment successful",
		"payment": payment,
		"order":   order,
	})
}

func UpdateOrderStatus(c *gin.Context) {
	orderID := c.Param("id")
	var req struct {
		Status models.OrderStatus `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var order models.Order
	if err := database.DB.First(&order, orderID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Order not found"})
		return
	}

	order.Status = req.Status
	database.DB.Save(&order)

	database.DB.Preload("Items").Preload("Payment").First(&order, order.ID)
	c.JSON(http.StatusOK, order)
}
