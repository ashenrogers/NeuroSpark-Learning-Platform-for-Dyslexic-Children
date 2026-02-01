#!/bin/bash

# Dyslexia App Backend Startup Script

echo "🚀 Starting Dyslexia Support App Backend..."
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run: python -m venv venv"
    exit 1
fi

# Activate virtual environment
echo "📦 Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# Check if requirements are installed
echo "🔍 Checking dependencies..."
python -c "import fastapi" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Dependencies not installed!"
    echo "Installing requirements..."
    pip install -r requirements.txt
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found, using defaults"
    echo "Consider copying .env.example to .env"
fi

echo ""
echo "✅ All checks passed!"
echo "🎯 Starting FastAPI server..."
echo "📡 API will be available at: http://localhost:8000"
echo "📚 API documentation at: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Run the application
python main.py
