@echo off
REM Dyslexia App Backend Startup Script for Windows

echo 🚀 Starting Dyslexia Support App Backend...
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo ❌ Virtual environment not found!
    echo Please run: python -m venv venv
    exit /b 1
)

REM Activate virtual environment
echo 📦 Activating virtual environment...
call venv\Scripts\activate

REM Check if requirements are installed
echo 🔍 Checking dependencies...
python -c "import fastapi" 2>nul
if errorlevel 1 (
    echo ❌ Dependencies not installed!
    echo Installing requirements...
    pip install -r requirements.txt
)

REM Check if .env exists
if not exist ".env" (
    echo ⚠️  .env file not found, using defaults
    echo Consider copying .env.example to .env
)

echo.
echo ✅ All checks passed!
echo 🎯 Starting FastAPI server...
echo 📡 API will be available at: http://localhost:8000
echo 📚 API documentation at: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo.

REM Run the application
python main.py
