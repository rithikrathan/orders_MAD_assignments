package main

import (
	"log"
	"os"

	"canteen-backend/internal/database"
	"canteen-backend/internal/handlers"
	"canteen-backend/internal/middleware"
	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize SQLite Database
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "canteen.db"
	}
	_, err := database.InitDB(dbPath)
	if err != nil {
		log.Fatalf("Database initialization failed: %v", err)
	}

	router := gin.Default()
	router.Use(middleware.CORSMiddleware())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "canteen-backend"})
	})

	api := router.Group("/api")
	{
		// Public Auth Endpoints
		auth := api.Group("/auth")
		{
			auth.POST("/register", handlers.Register)
			auth.POST("/login", handlers.Login)
		}

		// Public Menu Endpoints
		menu := api.Group("/menu")
		{
			menu.GET("", handlers.GetMenu)
			menu.GET("/categories", handlers.GetCategories)
			menu.GET("/:id", handlers.GetMenuItem)
		}

		// Protected Routes (Require JWT)
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware())
		{
			protected.GET("/auth/me", handlers.GetProfile)

			// Orders
			protected.POST("/orders", handlers.CreateOrder)
			protected.GET("/orders", handlers.GetOrders)
			protected.GET("/orders/:id", handlers.GetOrderByID)
			protected.POST("/orders/:id/pay", handlers.ProcessPayment)

			// Customer Care / Support (Student)
			protected.POST("/support", handlers.CreateSupportTicket)
			protected.GET("/support", handlers.GetStudentSupportTickets)
		}

		// Admin / Kitchen Simulation Endpoint
		api.PATCH("/orders/:id/status", handlers.UpdateOrderStatus)

		// Full Admin Management API
		admin := api.Group("/admin")
		{
			admin.GET("/stats", handlers.GetAdminStats)
			admin.GET("/orders", handlers.GetAdminOrders)
			admin.PATCH("/orders/:id/status", handlers.UpdateOrderStatus)
			admin.POST("/menu", handlers.CreateFoodItem)
			admin.PUT("/menu/:id", handlers.UpdateFoodItem)
			admin.DELETE("/menu/:id", handlers.DeleteFoodItem)
			admin.PATCH("/menu/:id/toggle", handlers.ToggleFoodItemAvailability)
			admin.GET("/support", handlers.GetAdminSupportTickets)
			admin.PATCH("/support/:id", handlers.UpdateAdminSupportTicket)
			admin.GET("/students", handlers.GetAdminStudents)
			admin.POST("/students/wallet", handlers.AdjustStudentWallet)
		}
	}

	// Serve React Admin Web Portal from top-level admin/ directory
	adminDir := "./admin"
	if _, err := os.Stat(adminDir); os.IsNotExist(err) {
		adminDir = "../admin"
	}
	if _, err := os.Stat(adminDir); err == nil {
		router.Static("/admin", adminDir)
	}

	// Serve Kiosk Slideshow Display from top-level kiosk/ directory
	kioskDir := "./kiosk"
	if _, err := os.Stat(kioskDir); os.IsNotExist(err) {
		kioskDir = "../kiosk"
	}
	if _, err := os.Stat(kioskDir); err == nil {
		router.Static("/kiosk", kioskDir)
	}



	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Canteen REST API Server running on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
