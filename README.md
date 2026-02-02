# 📱 Dyslexia Support Mobile Application

A comprehensive mobile application designed to help children with dyslexia improve their reading, pronunciation, and vocabulary skills using AI-powered speech recognition and natural language processing.

## 🎯 Project Overview

This application is part of a Bachelor's degree research component, focusing on leveraging AI/ML technology to support children with learning difficulties. The app provide interactive game:

1. Handwritting - handwriting practice enhance


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
  - CNN model for handwriting image analysis
  - LSTM / RNN for stroke sequence learning
  - Motor-coordination classification model
  - Correct vs Wrong handwriting classifier
  - Similarity scoring using reference handwriting patterns
  - Handwriting Processing
  - Image preprocessing (resize, normalization)
  - Stroke data processing (x, y, pressure, time)
  - Feature extraction (speed, pressure, direction)
  - Error detection (reversal, misalignment, spacing)   
- **Key Features**:
  - RESTful API for handwriting evaluation
  - Image upload & processing
  - Stroke data analysis
  - Real-time handwriting feedback
  - Motor coordination scoring
  - Corrective suggestion generation
  - Progress tracking for each child

## 📂 Project Structure

```
dyslexia-app/
├── frontend/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── handwriting.dart   
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
    │   ├── correct_side_letters_recognition.py
    │   ├── wrong_side_letters_recognition.py
    ├── requirements.txt      # Python dependencies
    └── .env.example         # Configuration template
    │   └── vocabulary_generator.py
    ├── requirements.txt      # Python dependencies
    └── .env.example         # Configuration
