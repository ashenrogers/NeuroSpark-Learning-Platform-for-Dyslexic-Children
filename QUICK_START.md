# 🚀 Quick Start Guide

Get your Dyslexia Support App running in 10 minutes!

## ⚡ Prerequisites Check

Before starting, ensure you have:
- [ ] Python 3.9+ installed
- [ ] Flutter SDK installed
- [ ] Android Studio or VS Code
- [ ] An Android device or emulator
- [ ] Internet connection

## 📥 Step 1: Get the Code

```bash
# If you haven't already, extract the project files
cd dyslexia-app
```

## 🔧 Step 2: Setup Backend (5 minutes)

```bash
# Navigate to backend
cd backend

# Create virtual environment
python -m venv venv

# Activate it
source venv/bin/activate  # Mac/Linux
# OR
venv\Scripts\activate     # Windows

# Install dependencies (this may take a few minutes)
pip install -r requirements.txt

# Run the server
python main.py
```

✅ **Success check**: Visit http://localhost:8000/health
You should see: `{"status": "healthy", "message": "API is running"}`

## 📱 Step 3: Setup Frontend (5 minutes)

Open a **new terminal** (keep backend running):

```bash
# Navigate to frontend
cd frontend

# Install dependencies
flutter pub get

# Update API URL in lib/services/api_service.dart
# For emulator: http://10.0.2.2:8000
# For device: http://YOUR_LOCAL_IP:8000

# Run the app
flutter run
```

Select your device when prompted.

✅ **Success check**: App opens and shows "Dyslexia Support App" with three game cards

## 🎮 Step 4: Test the App

1. **Grant Permissions**: 
   - Allow microphone access when prompted
   - Allow storage access

2. **Try Reading Fluency**:
   - Tap "Reading Fluency"
   - Read the sentence aloud
   - Hold the microphone button while speaking
   - See your score!

3. **Try Pronunciation**:
   - Tap "Pronunciation Practice"
   - Say the word shown
   - Get instant feedback

4. **Try Vocabulary**:
   - Tap "Vocabulary Builder"
   - Answer the question
   - Learn from explanations

## 🎯 Common Quick Fixes

### Backend won't start?
```bash
# Check Python version
python --version  # Should be 3.9+

# Install FFmpeg
# Mac: brew install ffmpeg
# Ubuntu: sudo apt install ffmpeg
# Windows: Download from ffmpeg.org
```

### Frontend won't connect?
```bash
# Check backend is running
curl http://localhost:8000/health

# For physical device, use your computer's IP
# Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)
```

### Microphone not working?
- Check permissions in device settings
- Verify AndroidManifest.xml has RECORD_AUDIO permission
- Try another recording app to test hardware

## 📊 Quick Architecture Overview

```
Your Device/Emulator          Your Computer
┌─────────────────┐          ┌─────────────────┐
│  Flutter App    │  ----→   │  FastAPI Server │
│  (Frontend)     │  ←----   │  (Backend)      │
└─────────────────┘          └─────────────────┘
      ↓ Records                     ↓ Processes
   Audio file                    AI Models
```

## 🎓 For Your Research

To collect data for your Bachelor's thesis:

1. **Track Metrics**:
   - Reading fluency scores
   - Pronunciation accuracy
   - Time spent per game
   - User engagement

2. **Gather Feedback**:
   - User surveys
   - Observation notes
   - Parent/teacher interviews

3. **Analyze Results**:
   - Compare pre/post scores
   - Identify patterns
   - Document improvements

## 📚 Next Steps

- ✅ App is running
- 📖 Read README.md for full documentation
- 🔧 Check SETUP_GUIDE.md for detailed instructions
- 🐛 See TROUBLESHOOTING.md if you have issues
- 📊 Use RESEARCH_TEMPLATE.md for your thesis

## 🆘 Need Help?

1. **Check the logs**:
   - Backend: Look at terminal where `python main.py` is running
   - Frontend: Run `flutter logs`

2. **Common issues**: See TROUBLESHOOTING.md

3. **Still stuck?**: 
   - Review error messages carefully
   - Search the error online
   - Check Flutter/FastAPI documentation

## 🎉 You're All Set!

Your dyslexia support app is now running! 

Time to:
- 🎮 Test all features
- 📝 Customize for your needs
- 🔬 Conduct research
- 📊 Collect data
- 🎓 Write your thesis

**Good luck with your project! 🚀**

---

## Quick Reference Commands

```bash
# Start Backend
cd backend
source venv/bin/activate  # or venv\Scripts\activate on Windows
python main.py

# Start Frontend (new terminal)
cd frontend
flutter run

# Check Backend Health
curl http://localhost:8000/health

# View API Docs
# Open browser: http://localhost:8000/docs

# Flutter Logs
flutter logs

# Clean Build (if issues)
flutter clean && flutter pub get
```
