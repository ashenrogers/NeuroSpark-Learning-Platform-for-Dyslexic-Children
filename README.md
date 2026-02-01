
# NeuroSpark-Learning-Platform-for-Dyslexic-Children
Mobile and Simulation-based Approach to Reduce Dyslexia in Children with Learning Disabilities 

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
```

## 🚀 Getting Started

### Prerequisites

**For Backend:**
- Python 3.9 or higher
- pip (Python package manager)
- FFmpeg (for audio processing)

**For Frontend:**
- Flutter SDK (latest stable)
- Android Studio / VS Code
- Android SDK
- An Android device or emulator

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Install FFmpeg:**
   - **Ubuntu/Debian:** `sudo apt-get install ffmpeg`
   - **macOS:** `brew install ffmpeg`
   - **Windows:** Download from https://ffmpeg.org/download.html

5. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

6. **Run the server:**
   ```bash
   python main.py
   ```
   
   The API will be available at `http://localhost:8000`

7. **Test the API:**
   Visit `http://localhost:8000/docs` for interactive API documentation

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API URL:**
   - Open `lib/services/api_service.dart`
   - Update `baseUrl` with your backend server URL
   - For Android emulator: `http://10.0.2.2:8000`
   - For physical device: `http://YOUR_LOCAL_IP:8000`

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🎮 How to Use

### Reading Fluency Game
1. Read the displayed sentence aloud
2. Hold the microphone button while speaking
3. Release to stop recording
4. View your score and word-by-word feedback
5. Green words = correct, Red words = incorrect

### Pronunciation Practice
1. View the word and its hint
2. Hold the microphone button and pronounce the word
3. Release to check pronunciation
4. Get instant feedback on accuracy
5. Track your progress over time

### Vocabulary Builder
1. Select difficulty level (easy/medium/hard)
2. Read the AI-generated question
3. Choose from multiple-choice answers
4. Submit your answer
5. Learn from detailed explanations

## 🔧 Configuration

### Backend Configuration (.env)
```env
USE_WHISPER=True              # Use Whisper for speech recognition
WHISPER_MODEL=base            # Model size (tiny/base/small/medium/large)
PRONUNCIATION_THRESHOLD=0.75  # Minimum accuracy for correct pronunciation
FLUENCY_THRESHOLD=0.60        # Minimum score for fluent reading
```

### Frontend Configuration
- Audio recording quality: WAV format
- Supported languages: English (US)
- Minimum Android version: 21 (Lollipop)

## 📊 API Endpoints

### Health Check
```
GET /health
Response: {"status": "healthy", "message": "API is running"}
```

### Reading Fluency
```
POST /api/fluency/check
Body: 
  - audio: File (WAV/MP3)
  - expected_text: String
Response: {
  "transcription": "...",
  "score": 85,
  "feedback": [...]
}
```

### Pronunciation
```
POST /api/pronunciation/check
Body:
  - audio: File (WAV/MP3)
  - word: String
Response: {
  "is_correct": true,
  "confidence": 0.92,
  "transcription": "..."
}
```

### Vocabulary
```
GET /api/vocabulary/question?difficulty=easy
Response: {
  "question_id": "uuid",
  "question": "...",
  "options": [...]
}

POST /api/vocabulary/check
Body: {
  "question_id": "uuid",
  "answer": "..."
}
Response: {
  "is_correct": true,
  "correct_answer": "...",
  "explanation": "..."
}
```

## 🧪 Testing

### Backend Testing
```bash
# Run with test mode
python main.py

# Test endpoints manually
curl http://localhost:8000/health
```

### Frontend Testing
```bash
# Run tests
flutter test

# Run in debug mode
flutter run --debug
```

## 🎯 Research Component

This application serves as a research component for a Bachelor's degree, focusing on:

1. **AI-Powered Learning Support**: Using machine learning models to provide personalized feedback
2. **Speech Recognition Accuracy**: Comparing different speech recognition engines for children's voices
3. **User Experience**: Designing intuitive interfaces for children with learning difficulties
4. **Accessibility**: Making educational technology accessible to all learners

### Research Questions
- How effective is AI speech recognition for children with dyslexia?
- Can real-time feedback improve reading fluency?
- What UI/UX patterns work best for educational apps?

## 🔐 Privacy & Security

- No user data is stored permanently
- Audio files are processed and immediately deleted
- All communication uses HTTPS (in production)
- No personal information is collected

## 🚀 Future Enhancements

- [ ] Integration with OpenAI/Claude for dynamic question generation
- [ ] Progress tracking with charts and statistics
- [ ] Multiplayer mode for collaborative learning
- [ ] Parent/teacher dashboard
- [ ] Support for multiple languages
- [ ] Offline mode
- [ ] Text-to-speech for question reading
- [ ] Gamification with rewards and achievements

## 📝 License

This project is developed for educational purposes as part of a Bachelor's degree research component.

## 👥 Contributors

- [Your Name] - Research & Development

## 🙏 Acknowledgments

- Whisper by OpenAI for speech recognition
- Flutter team for the amazing framework
- FastAPI for the backend framework
- All researchers working on dyslexia support technology

## 📞 Support

For questions or issues:
- Open an issue in the repository
- Contact: [your-email@example.com]

---

**Note**: This is a research project. For production deployment, additional security, scalability, and compliance measures should be implemented.

