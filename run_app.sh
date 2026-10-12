#!/usr/bin/env bash
set -e

echo "==========================================================="
echo "   Campus Bites - College Canteen Mobile App (MAD Project) "
echo "   Stack: Flutter (Dart) + Go (Golang) + SQLite            "
echo "==========================================================="

# 1. Check/Start Backend
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "⚙️ Starting Go + SQLite Backend on port 8080..."
    (cd backend && ./bin/server) &
    sleep 1
    echo "✓ Backend server is LIVE at http://localhost:8080"
else
    echo "✓ Go Backend is already running at http://localhost:8080"
fi

# 2. Launch Flutter App
echo "📱 Launching Flutter App on Linux Desktop (Phone Frame)..."
cd frontend
flutter run -d linux
