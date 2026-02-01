# 📱 Dyslexia Support Mobile Application

A comprehensive mobile application designed to help children with dyslexia improve their reading, pronunciation, and vocabulary skills using AI-powered speech recognition and natural language processing.

## 🎯 Project Overview

This application is part of a Bachelor's degree research component, focusing on leveraging AI/ML technology to support children with learning difficulties. The app provides three interactive games:

1. **Reading Fluency Game** - Practice reading sentences with real-time feedback
2. **Pronunciation Practice** - Learn correct word pronunciation with AI verification
3. **Vocabulary Builder** - Expand vocabulary through AI-generated questions

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter (latest stable)
- **Language**: Dart (null-safe)
- **Platform**: Android (with iOS compatibility)
- **Key Features**:
  - Audio recording and playback
  - Real-time speech recognition
  - Interactive UI with visual feedback
  - Progress tracking

### Backend (Python FastAPI)
- **Framework**: FastAPI
- **Language**: Python 3.9+
- **AI/ML Models**:
  - Whisper (speech recognition)
  - Google Speech Recognition
  - Custom NLP models for text analysis
  - Levenshtein distance for similarity
- **Key Features**:
  - RESTful API
  - Audio file processing
  - Real-time transcription
  - AI-powered question generation

## 📂 Project Structure

```
dyslexia-app/
├── frontend/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── fluency_game_screen.dart
│   │   │   ├── pronunciation_game_screen.dart
│   │   │   └── vocabulary_game_screen.dart
│   │   ├── services/          # API services
│   │   │   └── api_service.dart
│   │   └── widgets/           # Reusable widgets
│   │       ├── score_card.dart
│   │       └── feedback_dialog.dart
│   ├── android/               # Android-specific files
│   └── pubspec.yaml          # Flutter dependencies
│
└── backend/                   # Python FastAPI server
    ├── main.py               # API entry point
    ├── models/               # AI/ML models
    │   ├── speech_recognition_model.py
    │   ├── fluency_checker.py
    │   ├── pronunciation_checker.py
    │   └── vocabulary_generator.py
    ├── requirements.txt      # Python dependencies
    └── .env.example         # Configuration template



