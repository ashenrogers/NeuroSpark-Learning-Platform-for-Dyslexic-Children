# 🔧 Detailed Setup Guide

This guide will help you set up the Dyslexia Support Mobile Application step-by-step.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Backend Setup](#backend-setup)
3. [Frontend Setup](#frontend-setup)
4. [Common Issues](#common-issues)
5. [Testing](#testing)

## System Requirements

### For Backend Development
- **Operating System**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 20.04+)
- **Python**: Version 3.9 or higher
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: At least 2GB free space
- **Internet**: Required for initial setup

### For Frontend Development
- **Operating System**: Windows 10+, macOS 10.15+, or Linux
- **Flutter SDK**: Latest stable version
- **Android Studio**: 2021.1 or higher (or VS Code with Flutter extension)
- **Android SDK**: API Level 21 or higher
- **RAM**: Minimum 8GB recommended
- **Storage**: At least 10GB free space

## Backend Setup

### Step 1: Install Python

**Windows:**
1. Download Python from https://www.python.org/downloads/
2. Run installer and check "Add Python to PATH"
3. Verify installation:
   ```bash
   python --version
   ```

**macOS:**
```bash
brew install python@3.9
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3.9 python3-pip python3-venv
```

### Step 2: Install FFmpeg

FFmpeg is required for audio processing.

**Windows:**
1. Download from https://ffmpeg.org/download.html
2. Extract to `C:\ffmpeg`
3. Add `C:\ffmpeg\bin` to System PATH
4. Verify: `ffmpeg -version`

**macOS:**
```bash
brew install ffmpeg
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install ffmpeg
```

### Step 3: Set Up Python Environment

1. **Navigate to backend directory:**
   ```bash
   cd dyslexia-app/backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   
   **Windows:**
   ```bash
   venv\Scripts\activate
   ```
   
   **macOS/Linux:**
   ```bash
   source venv/bin/activate
   ```

4. **Upgrade pip:**
   ```bash
   pip install --upgrade pip
   ```

### Step 4: Install Python Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- FastAPI - Web framework
- Uvicorn - ASGI server
- SpeechRecognition - Speech-to-text
- Whisper - OpenAI's speech recognition model
- NLTK - Natural language processing
- And other dependencies...

**Note**: Installing Whisper and PyTorch may take 5-10 minutes depending on your internet connection.

### Step 5: Download AI Models

The first time you run the application, it will download the Whisper model (~150MB for base model):

```bash
python -c "import whisper; whisper.load_model('base')"
```

### Step 6: Configure Environment

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit .env file** (optional):
   ```env
   USE_WHISPER=True
   WHISPER_MODEL=base
   API_PORT=8000
   ```

### Step 7: Run Backend Server

```bash
python main.py
```

You should see:
```
INFO:     Started server process
INFO:     Waiting for application startup.
Loading AI models...
Whisper model loaded!
Models loaded successfully!
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 8: Test Backend

Open your browser and visit:
- API Health: http://localhost:8000/health
- API Docs: http://localhost:8000/docs

You should see the interactive API documentation.

## Frontend Setup

### Step 1: Install Flutter

**Windows:**
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to PATH
4. Run: `flutter doctor`

**macOS:**
```bash
brew install --cask flutter
flutter doctor
```

**Linux:**
```bash
sudo snap install flutter --classic
flutter doctor
```

### Step 2: Set Up Android Development

1. **Install Android Studio:**
   - Download from https://developer.android.com/studio
   - Install with default settings

2. **Install Android SDK:**
   - Open Android Studio
   - Go to Tools → SDK Manager
   - Install Android SDK Platform 21 or higher
   - Install Android SDK Build-Tools

3. **Accept Android Licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

### Step 3: Set Up Android Emulator (Optional)

1. Open Android Studio
2. Tools → Device Manager
3. Create Virtual Device
4. Select a device (e.g., Pixel 4)
5. Download a system image (e.g., Android 11)
6. Finish setup and launch emulator

### Step 4: Configure Flutter Project

1. **Navigate to frontend directory:**
   ```bash
   cd dyslexia-app/frontend
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API URL:**
   
   Open `lib/services/api_service.dart` and update:
   
   **For Android Emulator:**
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8000';
   ```
   
   **For Physical Device:**
   ```dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:8000';
   ```
   
   To find your local IP:
   - Windows: `ipconfig`
   - macOS/Linux: `ifconfig`

### Step 5: Run Flutter App

1. **Check connected devices:**
   ```bash
   flutter devices
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```
   
   Or if multiple devices:
   ```bash
   flutter run -d <device-id>
   ```

## Common Issues

### Backend Issues

**Issue: "ModuleNotFoundError: No module named 'whisper'"**
```bash
pip install openai-whisper
```

**Issue: "FFmpeg not found"**
- Ensure FFmpeg is installed and in PATH
- Restart terminal after installation

**Issue: "Port 8000 already in use"**
```bash
# Find and kill process using port 8000
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# macOS/Linux:
lsof -ti:8000 | xargs kill -9
```

**Issue: "CUDA/GPU errors with PyTorch"**
```bash
# Install CPU-only version
pip uninstall torch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

### Frontend Issues

**Issue: "Flutter doctor shows errors"**
- Run `flutter doctor -v` for detailed diagnostics
- Follow the suggested fixes

**Issue: "Permission denied for microphone"**
- Check AndroidManifest.xml has:
  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```
- Grant permission on device: Settings → Apps → Dyslexia Support → Permissions

**Issue: "Cannot connect to backend"**
- Ensure backend is running
- Check firewall settings
- Verify API URL is correct
- Use `http://` not `https://` for local development

**Issue: "Build failed - SDK not found"**
```bash
flutter config --android-sdk <path-to-android-sdk>
```

## Testing

### Test Backend API

**1. Health Check:**
```bash
curl http://localhost:8000/health
```

**2. Test with Postman:**
- Import the API from http://localhost:8000/docs
- Test each endpoint with sample data

**3. Test Speech Recognition:**
```bash
# Use a sample WAV file
curl -X POST http://localhost:8000/api/pronunciation/check \
  -F "audio=@sample.wav" \
  -F "word=hello"
```

### Test Frontend

**1. Hot Reload:**
- Make changes to Dart files
- Press `r` in terminal for hot reload
- Press `R` for hot restart

**2. Debug Mode:**
```bash
flutter run --debug
```

**3. Check Logs:**
```bash
flutter logs
```

## Production Deployment

### Backend Deployment

For production, consider:
- Use Gunicorn with Uvicorn workers
- Set up HTTPS with SSL certificates
- Use environment variables for configuration
- Deploy to cloud services (AWS, GCP, Azure)
- Set up database for persistent storage
- Implement rate limiting and authentication

### Frontend Deployment

To build release APK:
```bash
flutter build apk --release
```

The APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

## Next Steps

1. ✅ Backend is running on http://localhost:8000
2. ✅ Frontend is running on your device/emulator
3. 📝 Start using the app and testing features
4. 🔧 Customize for your research needs
5. 📊 Collect data and analyze results

## Getting Help

If you encounter issues:
1. Check the logs: Backend terminal and `flutter logs`
2. Review error messages carefully
3. Search for similar issues online
4. Check Flutter and FastAPI documentation
5. Open an issue on GitHub (if applicable)

---

**Happy Coding! 🚀**
