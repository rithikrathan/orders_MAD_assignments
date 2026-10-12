#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

echo "================================================================"
echo "    🍽️  CAMPUS BITES - COLLEGE CANTEEN FOOD ORDERING SYSTEM     "
echo "    Stack: Flutter (Dart) + Go (Golang) + SQLite (canteen.db)   "
echo "    Theme: Dark Red & Black Theme                               "
echo "================================================================"
echo ""

# Function to clean up background processes on script exit
cleanup() {
    echo ""
    echo "🛑 Shutting down backend & web servers..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
    if [ ! -z "$WEB_PID" ]; then
        kill "$WEB_PID" 2>/dev/null || true
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

# 1. Check / Build / Start Backend
echo "1️⃣  Checking Go + SQLite Backend..."
if [ ! -f "$BACKEND_DIR/bin/server" ]; then
    echo "   🔨 Compiling Go backend binary..."
    (cd "$BACKEND_DIR" && go build -o bin/server cmd/server/main.go)
fi

# Check if backend is already responding
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "   ✓ Go Backend is already running on http://localhost:8080"
else
    echo "   🚀 Starting Go REST API Server on port 8080..."
    (cd "$BACKEND_DIR" && ./bin/server) > /tmp/canteen_backend.log 2>&1 &
    BACKEND_PID=$!
    
    # Wait for backend to be healthy
    for i in {1..10}; do
        if curl -s http://localhost:8080/health > /dev/null 2>&1; then
            break
        fi
        sleep 0.5
    done
    echo "   ✓ Backend is LIVE at http://localhost:8080 (PID: $BACKEND_PID)"
    echo "   👑 Kitchen & Admin Portal is LIVE at http://localhost:8080/admin/"
    echo "   📺 Kiosk TV Menu Board is LIVE at http://localhost:8080/kiosk/"
fi

echo ""
echo "2️⃣  Starting Interface..."
echo "   Select how you would like to run:"
echo "   [1] Mobile App: Native Linux Desktop Window (Phone Aspect Ratio - Recommended)"
echo "   [2] Mobile App: Web Browser (http://localhost:3000 via Firefox)"
echo "   [3] Kitchen & Admin Portal in Browser (http://localhost:8080/admin/)"
echo "   [4] Kiosk TV Menu Board in Browser (http://localhost:8080/kiosk/)"
echo ""

# Check if running interactively
if [ -t 0 ]; then
    read -p "   Enter choice [1, 2, 3, or 4, default: 1]: " CHOICE
else
    CHOICE="1"
fi

CHOICE=${CHOICE:-1}

if [ "$CHOICE" = "4" ]; then
    echo ""
    echo "   📺 Opening Kiosk TV Menu Board at http://localhost:8080/kiosk/ ..."
    if which xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:8080/kiosk/ &
    elif which firefox > /dev/null 2>&1; then
        firefox http://localhost:8080/kiosk/ &
    fi
    echo "   Press Ctrl+C anytime to stop backend server."
    wait $BACKEND_PID
elif [ "$CHOICE" = "3" ]; then
    echo ""
    echo "   👑 Opening Kitchen & Admin Management Portal at http://localhost:8080/admin/ ..."
    if which xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:8080/admin/ &
    elif which firefox > /dev/null 2>&1; then
        firefox http://localhost:8080/admin/ &
    fi
    echo "   Press Ctrl+C anytime to stop backend server."
    wait $BACKEND_PID
elif [ "$CHOICE" = "2" ]; then
    echo ""
    echo "   🌐 Serving Flutter Web Build on http://localhost:3000..."
    if [ ! -d "$FRONTEND_DIR/build/web" ]; then
        echo "   🔨 Building web distribution..."
        (cd "$FRONTEND_DIR" && flutter build web --release)
    fi
    (cd "$FRONTEND_DIR" && python3 -m http.server 3000 --directory build/web) > /tmp/canteen_web.log 2>&1 &
    WEB_PID=$!
    echo "   ✓ Web App is LIVE at http://localhost:3000"
    
    # Attempt to open browser
    if which xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:3000 &
    elif which firefox > /dev/null 2>&1; then
        firefox http://localhost:3000 &
    fi
    
    echo ""
    echo "   📱 Press Ctrl+C anytime to stop all servers."
    wait $WEB_PID
else
    echo ""
    echo "   📱 Launching Flutter Native Desktop App in mobile phone dimensions..."
    cd "$FRONTEND_DIR"
    flutter run -d linux
fi
