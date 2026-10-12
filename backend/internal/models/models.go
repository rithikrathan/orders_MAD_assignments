package models

import (
	"time"
)

type User struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	StudentID    string    `gorm:"uniqueIndex;size:50;not null" json:"student_id"`
	Name         string    `gorm:"size:100;not null" json:"name"`
	Email        string    `gorm:"uniqueIndex;size:100;not null" json:"email"`
	PasswordHash string    `gorm:"not null" json:"-"`
	WalletBalance float64  `gorm:"default:500.00" json:"wallet_balance"` // Demo balance for student card
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type FoodItem struct {
	ID              uint      `gorm:"primaryKey" json:"id"`
	Name            string    `gorm:"size:100;not null" json:"name"`
	Category        string    `gorm:"size:50;not null" json:"category"` // Breakfast, Lunch, Snacks, Beverages, Combos, Desserts
	Price           float64   `gorm:"not null" json:"price"`
	IsVeg           bool      `gorm:"default:true" json:"is_veg"`
	IsAvailable     bool      `gorm:"default:true" json:"is_available"`
	Description     string    `gorm:"type:text" json:"description"`
	Rating          float64   `gorm:"default:4.5" json:"rating"`
	PrepTimeMinutes int       `gorm:"default:10" json:"prep_time_minutes"`
	ImageURL        string    `gorm:"size:255" json:"image_url"`
	Calories        int       `gorm:"default:250" json:"calories"`
	CreatedAt       time.Time `json:"created_at"`
}

type OrderStatus string

const (
	StatusPending   OrderStatus = "PENDING"
	StatusPaid      OrderStatus = "PAID"
	StatusPreparing OrderStatus = "PREPARING"
	StatusReady     OrderStatus = "READY_FOR_PICKUP"
	StatusCompleted OrderStatus = "COMPLETED"
	StatusCancelled OrderStatus = "CANCELLED"
)

type Order struct {
	ID            uint        `gorm:"primaryKey" json:"id"`
	UserID        uint        `gorm:"not null;index" json:"user_id"`
	User          User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	TokenNumber   string      `gorm:"size:20;not null" json:"token_number"` // e.g. #C-102
	Subtotal      float64     `gorm:"not null" json:"subtotal"`
	Tax           float64     `gorm:"not null" json:"tax"` // 5% GST
	PackagingFee  float64     `gorm:"default:10.0" json:"packaging_fee"`
	Discount      float64     `gorm:"default:0.0" json:"discount"`
	TotalAmount   float64     `gorm:"not null" json:"total_amount"`
	Status        OrderStatus `gorm:"size:30;default:'PENDING'" json:"status"`
	PaymentMethod string      `gorm:"size:50;default:'UPI'" json:"payment_method"`
	PaymentStatus string      `gorm:"size:30;default:'UNPAID'" json:"payment_status"`
	SpecialNotes  string      `gorm:"size:255" json:"special_notes"`
	Items         []OrderItem `gorm:"foreignKey:OrderID" json:"items"`
	Payment       *Payment    `gorm:"foreignKey:OrderID" json:"payment,omitempty"`
	CreatedAt     time.Time   `json:"created_at"`
	UpdatedAt     time.Time   `json:"updated_at"`
}

type OrderItem struct {
	ID         uint     `gorm:"primaryKey" json:"id"`
	OrderID    uint     `gorm:"not null;index" json:"order_id"`
	FoodItemID uint     `gorm:"not null" json:"food_item_id"`
	FoodItem   FoodItem `gorm:"foreignKey:FoodItemID" json:"food_item,omitempty"`
	FoodName   string   `gorm:"size:100;not null" json:"food_name"`
	Quantity   int      `gorm:"not null" json:"quantity"`
	UnitPrice  float64  `gorm:"not null" json:"unit_price"`
	TotalPrice float64  `gorm:"not null" json:"total_price"`
}

type Payment struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	OrderID       uint      `gorm:"uniqueIndex;not null" json:"order_id"`
	PaymentMethod string    `gorm:"size:50;not null" json:"payment_method"` // UPI, CARD, WALLET, CASH
	TransactionID string    `gorm:"size:100;not null" json:"transaction_id"`
	Amount        float64   `gorm:"not null" json:"amount"`
	Status        string    `gorm:"size:30;default:'SUCCESS'" json:"status"`
	CreatedAt     time.Time `json:"created_at"`
}

// Request & Response DTOs

type RegisterRequest struct {
	StudentID string `json:"student_id" binding:"required"`
	Name      string `json:"name" binding:"required"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=6"`
}

type LoginRequest struct {
	StudentIDOrEmail string `json:"student_id_or_email" binding:"required"`
	Password         string `json:"password" binding:"required"`
}

type AuthResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type OrderItemInput struct {
	FoodItemID uint `json:"food_item_id" binding:"required"`
	Quantity   int  `json:"quantity" binding:"required,min=1"`
}

type CreateOrderRequest struct {
	Items         []OrderItemInput `json:"items" binding:"required,min=1"`
	SpecialNotes  string           `json:"special_notes"`
	PaymentMethod string           `json:"payment_method" binding:"required"` // UPI, CARD, WALLET, CASH
}

type PaymentRequest struct {
	PaymentMethod string  `json:"payment_method" binding:"required"` // UPI, CARD, WALLET, CASH
	UPIId         string  `json:"upi_id"`
	CardNumber    string  `json:"card_number"`
	Amount        float64 `json:"amount" binding:"required"`
}

type SupportTicket struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"not null;index" json:"user_id"`
	User        User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	OrderID     *uint     `json:"order_id"`
	TokenNumber string    `gorm:"size:20" json:"token_number"`
	Category    string    `gorm:"size:50;not null" json:"category"` // Order Delay, Payment/Refund, Wrong Food, Food Quality, General
	Subject     string    `gorm:"size:150;not null" json:"subject"`
	Message     string    `gorm:"type:text;not null" json:"message"`
	AdminReply  string    `gorm:"type:text" json:"admin_reply"`
	Status      string    `gorm:"size:30;default:'OPEN'" json:"status"` // OPEN, IN_PROGRESS, RESOLVED
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type CreateTicketRequest struct {
	OrderID     *uint  `json:"order_id"`
	TokenNumber string `json:"token_number"`
	Category    string `json:"category" binding:"required"`
	Subject     string `json:"subject" binding:"required"`
	Message     string `json:"message" binding:"required"`
}

type UpdateTicketRequest struct {
	AdminReply string `json:"admin_reply"`
	Status     string `json:"status" binding:"required"`
}

type AdjustWalletRequest struct {
	StudentIDOrEmail string  `json:"student_id_or_email" binding:"required"`
	Amount           float64 `json:"amount" binding:"required"`
	Reason           string  `json:"reason"`
}

type SaveFoodItemRequest struct {
	Name            string  `json:"name" binding:"required"`
	Category        string  `json:"category" binding:"required"`
	Price           float64 `json:"price" binding:"required"`
	IsVeg           bool    `json:"is_veg"`
	IsAvailable     bool    `json:"is_available"`
	Description     string  `json:"description"`
	Rating          float64 `json:"rating"`
	PrepTimeMinutes int     `json:"prep_time_minutes"`
	ImageURL        string  `json:"image_url"`
	Calories        int     `json:"calories"`
}

type AdminStatsResponse struct {
	TotalRevenue    float64        `json:"total_revenue"`
	TotalOrders     int64          `json:"total_orders"`
	ActiveOrders    int64          `json:"active_orders"`
	CompletedOrders int64          `json:"completed_orders"`
	TotalStudents   int64          `json:"total_students"`
	TotalMenuItems  int64          `json:"total_menu_items"`
	OpenTickets     int64          `json:"open_tickets"`
	CategoryCounts  map[string]int `json:"category_counts"`
}

