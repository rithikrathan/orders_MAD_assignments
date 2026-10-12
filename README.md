# Campus Bites - College Canteen Food Ordering App 🍔📱

> **Mobile Application Development (MAD) Project**  
> A cross-platform food ordering system designed for college canteens to eliminate queues, streamline meal prep, and provide real-time digital pickup tokens.

---

## 🎨 Theme & UI Design
* **Color Palette:** Premium **Red & Black Theme** (Matte Obsidian `#0F0F11`, Card Charcoal `#1B1C22`, Crimson Red `#E50914`, Gold `#FFB800`, Emerald `#00E676`).
* **Design System:** Material 3 with rounded cards, category icons, veg/non-veg tags, floating cart summary bar, and responsive mobile layout.

---

## 🛠️ Full-Stack Technology Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile Frontend** | **Flutter 3.47+ (Dart 3.13+)** | Cross-platform UI for Android, iOS, Linux desktop, and Web. |
| **State Management** | **Provider** | Reactive state handling for cart calculations, authentication, and live orders. |
| **Backend REST API** | **Go (Golang 1.23+) & Gin** | High-throughput compiled REST API with CORS and JWT auth. |
| **Database** | **SQLite (canteen.db)** | Embedded relational database with pre-seeded campus food items. |
| **Payment Simulator** | **In-App Mock Gateway** | Instant UPI (Google Pay, PhonePe, Paytm) with 4-digit PIN dialog, Student Meal Card balance debit, Card, and Cash. |

---

## 🚀 Key Features

1. **Student Registration & Login:**
   - Sign up with College Roll No (`CS2026-042`) and password.
   - Auto-credited with **₹500 demo Canteen Wallet Balance**.
2. **Dynamic Categorized Menu:**
   - Categories: Breakfast, Lunch, Snacks, Beverages, Desserts.
   - Live Search by dish name / ingredients.
   - One-tap **Pure Veg toggle filter**.
3. **Item Customization & Detail View:**
   - Calories, prep time, customer rating, and cooking instructions (e.g. *Less spicy*, *Extra chutney*).
4. **Smart Cart & Bill Calculation:**
   - Real-time Subtotal, 5% GST Campus Tax, Packaging Fee, and Grand Total.
   - Promo Coupon code support (`CANTEEN20` for 15% discount).
5. **Mock Payment Gateway:**
   - Simulated UPI Apps + interactive 4-digit keypad PIN dialog.
   - College Meal Card wallet balance debit with live balance check.
6. **Digital Token Generation & Order Confirmation:**
   - Instant token issuance (e.g. **#C-248**).
   - Estimated pickup time breakdown.
7. **Live Order Tracking (Kitchen Stepper):**
   - *Order Placed ➔ Kitchen Cooking ➔ Ready for Counter Pickup ➔ Collected*.
   - Manual state simulator for viva / presentation demonstration.
8. **Student Profile & Pass:**
   - Digital student ID pass, meal balance, and operating hours schedule.
9. **Canteen Customer Care & Dispute Desk:**
   - Student can submit inquiries from Profile or directly from live order tokens.
   - Real-time resolution, staff reply tracking, and automatic wallet credit/refund.
10. **Kitchen Display System (KDS) & Admin Portal:**
    - Live React dashboard at `http://localhost:8080/admin/`.
    - Live token order management, instant one-click stock toggles, dish creation, and student wallet adjustments.
11. **Digital Kiosk & TV Menu Board Slideshow:**
    - Live kiosk display at `http://localhost:8080/kiosk/`.
    - Auto-rotating showcase of available dishes, live pricing, digital clock, and complete price board for canteen TV screens.

---

## ⚡ How to Run

### Method 1: All-in-One Launcher (Linux Desktop Mobile Frame)
```bash
./run_app.sh
```

### Method 2: Interactive Launcher (Mobile App, Admin Portal, or Kiosk)
```bash
./start.sh
```

### Method 3: Direct Web Dashboards
1. Start the Go Backend:
   ```bash
   cd backend
   go run cmd/server/main.go
   ```
2. **Kitchen & Admin Portal:** Open `http://localhost:8080/admin/`
3. **Canteen Kiosk TV Board:** Open `http://localhost:8080/kiosk/`

---

## 📡 Backend API Endpoints

### 📱 Student Mobile Endpoints
- `POST /api/auth/register` - Student registration
- `POST /api/auth/login` - Student login (JWT token)
- `GET  /api/auth/me` - Authenticated student profile
- `GET  /api/menu` - Categorized food menu
- `GET  /api/menu/categories` - Menu categories with count
- `POST /api/orders` - Place order from cart items
- `GET  /api/orders` - View student order history
- `POST /api/orders/:id/pay` - Process mock payment
- `POST /api/support` - Submit student inquiry / dispute
- `GET  /api/support` - View student inquiries & staff replies

### 👑 Kitchen & Admin Management Endpoints
- `GET   /api/admin/stats` - Kitchen & revenue performance metrics
- `GET   /api/admin/orders` - View all campus orders with filters
- `PATCH /api/admin/orders/:id/status` - Advance kitchen preparation status
- `POST  /api/admin/menu` - Create new canteen dish
- `PUT   /api/admin/menu/:id` - Edit dish details and price
- `DELETE /api/admin/menu/:id` - Remove dish from catalog
- `PATCH /api/admin/menu/:id/toggle` - Instant In-Stock / Out-of-Stock switch
- `GET   /api/admin/support` - View all student disputes and queries
- `PATCH /api/admin/support/:id` - Reply to student and update status
- `GET   /api/admin/students` - Directory of registered students
- `POST  /api/admin/students/wallet` - Credit or refund student canteen wallet

