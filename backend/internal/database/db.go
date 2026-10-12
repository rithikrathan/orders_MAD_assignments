package database

import (
	"fmt"
	"log"

	"canteen-backend/internal/models"
	"github.com/glebarez/sqlite"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func InitDB(dbPath string) (*gorm.DB, error) {
	if dbPath == "" {
		dbPath = "canteen.db"
	}

	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.User{},
		&models.FoodItem{},
		&models.Order{},
		&models.OrderItem{},
		&models.Payment{},
		&models.SupportTicket{},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to auto migrate database: %w", err)
	}

	DB = db
	SeedInitialData(db)

	return db, nil
}

func SeedInitialData(db *gorm.DB) {
	// Seed demo student user if not exists
	var userCount int64
	db.Model(&models.User{}).Count(&userCount)
	if userCount == 0 {
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("student123"), bcrypt.DefaultCost)
		demoUser := models.User{
			StudentID:     "CS2026-042",
			Name:          "Rithik Student",
			Email:         "rithik@college.edu",
			PasswordHash:  string(hashedPassword),
			WalletBalance: 850.00,
		}
		db.Create(&demoUser)
		log.Println("Seeded demo student user (rithik@college.edu / student123)")
	}

	// Seed food items if empty
	var foodCount int64
	db.Model(&models.FoodItem{}).Count(&foodCount)
	if foodCount == 0 {
		foodItems := []models.FoodItem{
			// Breakfast
			{
				Name:            "Masala Dosa with Chutney & Sambar",
				Category:        "Breakfast",
				Price:           60.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Crispy golden crepe filled with spiced mashed potato, served with coconut chutney & hot sambar.",
				Rating:          4.8,
				PrepTimeMinutes: 8,
				Calories:        320,
				ImageURL:        "https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Steamed Idli (2 Pcs) & Vada",
				Category:        "Breakfast",
				Price:           50.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Soft, fluffy steamed rice cakes with 1 crispy medu vada and South Indian chutneys.",
				Rating:          4.6,
				PrepTimeMinutes: 5,
				Calories:        240,
				ImageURL:        "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Aloo Paratha with Curd & Butter",
				Category:        "Breakfast",
				Price:           70.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Whole wheat flatbread stuffed with spiced potato filling, served with fresh curd and pickle.",
				Rating:          4.7,
				PrepTimeMinutes: 10,
				Calories:        380,
				ImageURL:        "https://images.unsplash.com/photo-1626074353765-517a681e40be?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Classic Egg Omelette Toast",
				Category:        "Breakfast",
				Price:           55.00,
				IsVeg:           false,
				IsAvailable:     true,
				Description:     "Fluffy double egg masala omelette served with 2 slices of butter toasted bread.",
				Rating:          4.5,
				PrepTimeMinutes: 7,
				Calories:        310,
				ImageURL:        "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop",
			},

			// Lunch
			{
				Name:            "Paneer Butter Masala Meal Combo",
				Category:        "Lunch",
				Price:           130.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Rich creamy paneer butter masala, 2 butter rotis, jeera rice, salad and gulab jamun.",
				Rating:          4.9,
				PrepTimeMinutes: 12,
				Calories:        650,
				ImageURL:        "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Dum Chicken Biryani with Raita",
				Category:        "Lunch",
				Price:           160.00,
				IsVeg:           false,
				IsAvailable:     true,
				Description:     "Fragrant basmati rice slow cooked with marinated tender chicken pieces and aromatic spices.",
				Rating:          4.9,
				PrepTimeMinutes: 10,
				Calories:        720,
				ImageURL:        "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop",
			},
			{
				Name:            "North Indian Veg Thali",
				Category:        "Lunch",
				Price:           110.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Dal Tadka, Mix Veg Sabzi, 3 Rotis, Steamed Basmati Rice, Papad, Pickle & Sweet.",
				Rating:          4.7,
				PrepTimeMinutes: 10,
				Calories:        580,
				ImageURL:        "https://images.unsplash.com/photo-1610057099431-d73a1c9d2f2f?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Schezwan Veg Fried Rice & Manchurian",
				Category:        "Lunch",
				Price:           120.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Spicy wok-tossed Schezwan rice paired with crispy vegetable Manchurian balls in rich gravy.",
				Rating:          4.6,
				PrepTimeMinutes: 12,
				Calories:        540,
				ImageURL:        "https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&auto=format&fit=crop",
			},

			// Snacks
			{
				Name:            "Crispy Samosa (2 Pcs) with Chutneys",
				Category:        "Snacks",
				Price:           30.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Golden crispy pastry shells filled with spiced potato and peas, with mint & tamarind dips.",
				Rating:          4.8,
				PrepTimeMinutes: 3,
				Calories:        260,
				ImageURL:        "https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Grilled Cheese & Veggie Sandwich",
				Category:        "Snacks",
				Price:           75.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Toasted triple-decker sandwich loaded with melted cheddar, capsicum, corn and green chutney.",
				Rating:          4.7,
				PrepTimeMinutes: 8,
				Calories:        360,
				ImageURL:        "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Crispy French Fries (Peri-Peri)",
				Category:        "Snacks",
				Price:           65.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Freshly fried potato strips tossed in zesty peri-peri seasoning with garlic mayo dip.",
				Rating:          4.5,
				PrepTimeMinutes: 6,
				Calories:        310,
				ImageURL:        "https://images.unsplash.com/photo-1576107232684-1279f3908594?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Chicken Crispy Burger",
				Category:        "Snacks",
				Price:           110.00,
				IsVeg:           false,
				IsAvailable:     true,
				Description:     "Crunchy fried chicken patty topped with fresh lettuce, cheese slice and chipotle sauce in a sesame bun.",
				Rating:          4.8,
				PrepTimeMinutes: 10,
				Calories:        480,
				ImageURL:        "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop",
			},

			// Beverages
			{
				Name:            "Special Filter Coffee",
				Category:        "Beverages",
				Price:           25.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Authentic South Indian degree filter coffee brewed with freshly roasted chicory blend.",
				Rating:          4.9,
				PrepTimeMinutes: 3,
				Calories:        90,
				ImageURL:        "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Masala Chai (Ginger & Cardamom)",
				Category:        "Beverages",
				Price:           20.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Hot steaming milk tea infused with freshly pounded ginger and aromatic cardamom pods.",
				Rating:          4.9,
				PrepTimeMinutes: 3,
				Calories:        80,
				ImageURL:        "https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Cold Coffee with Chocolate Ice Cream",
				Category:        "Beverages",
				Price:           70.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Thick blended espresso shake topped with a generous scoop of Belgian chocolate ice cream.",
				Rating:          4.8,
				PrepTimeMinutes: 5,
				Calories:        290,
				ImageURL:        "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Fresh Sweet Lime (Mosambi) Juice",
				Category:        "Beverages",
				Price:           50.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "100% freshly pressed sweet lime juice with black salt and mint garnish.",
				Rating:          4.6,
				PrepTimeMinutes: 4,
				Calories:        120,
				ImageURL:        "https://images.unsplash.com/photo-1613478223719-2ab802602423?w=600&auto=format&fit=crop",
			},

			// Desserts
			{
				Name:            "Warm Chocolate Lava Cake",
				Category:        "Desserts",
				Price:           85.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Decadent warm dark chocolate sponge cake with a molten chocolate center.",
				Rating:          4.9,
				PrepTimeMinutes: 6,
				Calories:        380,
				ImageURL:        "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop",
			},
			{
				Name:            "Gulab Jamun (2 Pcs)",
				Category:        "Desserts",
				Price:           40.00,
				IsVeg:           true,
				IsAvailable:     true,
				Description:     "Soft golden milk solids dumplings soaked in rose and cardamom flavored warm sugar syrup.",
				Rating:          4.7,
				PrepTimeMinutes: 2,
				Calories:        210,
				ImageURL:        "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop",
			},
		}

		db.Create(&foodItems)
		log.Printf("Seeded %d canteen menu items successfully!", len(foodItems))
	}

	// Seed demo orders if empty
	var orderCount int64
	db.Model(&models.Order{}).Count(&orderCount)
	if orderCount == 0 {
		var user models.User
		if err := db.First(&user).Error; err == nil {
			var dosa models.FoodItem
			var chai models.FoodItem
			db.Where("name LIKE ?", "%Dosa%").First(&dosa)
			db.Where("name LIKE ?", "%Chai%").First(&chai)

			if dosa.ID > 0 && chai.ID > 0 {
				demoOrder := models.Order{
					UserID:        user.ID,
					TokenNumber:   "#C-142",
					Subtotal:      dosa.Price + chai.Price,
					Tax:           (dosa.Price + chai.Price) * 0.05,
					PackagingFee:  10.00,
					Discount:      0.0,
					TotalAmount:   (dosa.Price + chai.Price)*1.05 + 10.00,
					Status:        models.StatusPreparing,
					PaymentMethod: "UPI",
					PaymentStatus: "PAID",
					SpecialNotes:  "Extra crispy dosa, less sugar in chai",
					Items: []models.OrderItem{
						{FoodItemID: dosa.ID, FoodName: dosa.Name, Quantity: 1, UnitPrice: dosa.Price, TotalPrice: dosa.Price},
						{FoodItemID: chai.ID, FoodName: chai.Name, Quantity: 1, UnitPrice: chai.Price, TotalPrice: chai.Price},
					},
					Payment: &models.Payment{
						PaymentMethod: "UPI",
						TransactionID: "TXN-DEMO-101",
						Amount:        (dosa.Price + chai.Price)*1.05 + 10.00,
						Status:        "SUCCESS",
					},
				}
				db.Create(&demoOrder)
				log.Println("Seeded demo canteen order (#C-142)")
			}
		}
	}

	// Seed demo customer care ticket if empty
	var ticketCount int64
	db.Model(&models.SupportTicket{}).Count(&ticketCount)
	if ticketCount == 0 {
		var user models.User
		if err := db.First(&user).Error; err == nil {
			demoTickets := []models.SupportTicket{
				{
					UserID:      user.ID,
					TokenNumber: "#C-142",
					Category:    "Order Delay",
					Subject:     "Token #C-142 taking more than 15 mins",
					Message:     "Hi canteen staff, my lecture begins in 10 minutes. Can you please check if my dosa and chai order is almost ready?",
					AdminReply:  "Chef is plating your hot dosa right now. Counter pickup ready in 2 mins!",
					Status:      "IN_PROGRESS",
				},
				{
					UserID:      user.ID,
					TokenNumber: "#C-098",
					Category:    "Payment / Refund",
					Subject:     "Double charged for cold coffee via UPI",
					Message:     "I scanned the QR code twice because first attempt showed pending. ₹70 was deducted twice from my bank account.",
					AdminReply:  "Verified with bank gateway. Credited ₹70 back to your Canteen Wallet balance.",
					Status:      "RESOLVED",
				},
			}
			db.Create(&demoTickets)
			log.Println("Seeded demo customer care support tickets")
		}
	}
}

