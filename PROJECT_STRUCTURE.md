# 📁 Project Structure Overview

```
dyslexia-app/
│
├── 📱 frontend/                          # Flutter Mobile Application
│   ├── lib/
│   │   ├── main.dart                    # App entry point
│   │   ├── screens/                     # UI Screens
│   │   │   ├── home_screen.dart         # Main menu
│   │   │   ├── fluency_game_screen.dart # Reading fluency game
│   │   │   ├── pronunciation_game_screen.dart # Pronunciation practice
│   │   │   └── vocabulary_game_screen.dart    # Vocabulary builder
│   │   ├── services/                    # Backend Communication
│   │   │   └── api_service.dart         # API client
│   │   └── widgets/                     # Reusable Components
│   │       ├── score_card.dart          # Score display widget
│   │       └── feedback_dialog.dart     # Feedback popup
│   ├── android/
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml      # Android permissions
│   └── pubspec.yaml                     # Flutter dependencies
│
├── 🔧 backend/                           # Python FastAPI Server
│   ├── main.py                          # API server entry point
│   ├── models/                          # AI/ML Models
│   │   ├── __init__.py
│   │   ├── speech_recognition_model.py  # Speech-to-text engine
│   │   ├── fluency_checker.py           # Reading fluency analysis
│   │   ├── pronunciation_checker.py     # Pronunciation verification
│   │   └── vocabulary_generator.py      # Question generation
│   ├── requirements.txt                 # Python dependencies
│   ├── .env.example                     # Configuration template
│   ├── run.sh                           # Linux/Mac startup script
│   └── run.bat                          # Windows startup script
│
├── 📚 Documentation
│   ├── README.md                        # Main project documentation
│   ├── SETUP_GUIDE.md                   # Detailed setup instructions
│   ├── TROUBLESHOOTING.md               # Common issues and solutions
│   ├── RESEARCH_TEMPLATE.md             # Research documentation template
│   └── PROJECT_STRUCTURE.md             # This file
│
└── 🎯 Quick Start Files
    ├── backend/run.sh                   # Start backend (Unix)
    └── backend/run.bat                  # Start backend (Windows)
```

## 📊 File Statistics

### Frontend (Flutter)
- **Total Dart files**: 8
- **Lines of code**: ~1,500+
- **Screens**: 4 (Home, Fluency, Pronunciation, Vocabulary)
- **Services**: 1 (API Service)
- **Widgets**: 2 (ScoreCard, FeedbackDialog)

### Backend (Python)
- **Total Python files**: 5
- **Lines of code**: ~800+
- **API endpoints**: 7
- **AI Models**: 4

### Documentation
- **README**: Comprehensive project overview
- **SETUP_GUIDE**: Step-by-step installation
- **TROUBLESHOOTING**: Common issues and fixes
- **RESEARCH_TEMPLATE**: Academic documentation

## 🎨 Component Descriptions

### Frontend Components

#### **Screens**
1. **home_screen.dart**
   - Main menu with 3 game cards
   - Server connection status
   - Navigation to games

2. **fluency_game_screen.dart**
   - Sentence display
   - Audio recording (hold to speak)
   - Word-by-word feedback (green/red)
   - Score tracking

3. **pronunciation_game_screen.dart**
   - Single word display with hints
   - Audio recording
   - Instant accuracy feedback
   - Statistics tracking

4. **vocabulary_game_screen.dart**
   - AI-generated questions
   - Multiple-choice interface
   - Difficulty levels
   - Score tracking

#### **Services**
- **api_service.dart**: HTTP client for backend communication

#### **Widgets**
- **score_card.dart**: Visual score display with colors
- **feedback_dialog.dart**: Success/failure popup

### Backend Components

#### **Models**
1. **speech_recognition_model.py**
   - Whisper integration
   - Google Speech Recognition
   - Confidence scoring

2. **fluency_checker.py**
   - Text similarity analysis
   - Word-by-word comparison
   - Levenshtein distance

3. **pronunciation_checker.py**
   - Single word verification
   - Phonetic matching
   - Accuracy calculation

4. **vocabulary_generator.py**
   - Question bank management
   - Random question selection
   - AI integration ready

## 🔄 Data Flow

```
User speaks → Flutter records audio → Sends to FastAPI
                                            ↓
                               AI models process audio
                                            ↓
                          Speech recognition (Whisper/Google)
                                            ↓
                             Text analysis & scoring
                                            ↓
                         Response sent back to Flutter
                                            ↓
                              UI displays feedback
```

## 🎯 Key Features

### ✅ Implemented
- ✅ Audio recording and processing
- ✅ Real-time speech recognition
- ✅ Word-by-word feedback
- ✅ Multiple difficulty levels
- ✅ Score tracking
- ✅ Visual feedback (colors)
- ✅ Three different game modes
- ✅ Error handling

### 🔮 Future Enhancements
- [ ] User authentication
- [ ] Progress persistence
- [ ] Offline mode
- [ ] Multiple languages
- [ ] Teacher dashboard
- [ ] Advanced analytics
- [ ] Social features
- [ ] Cloud storage integration

## 📦 Dependencies

### Frontend (Flutter)
```yaml
- record: ^5.0.4              # Audio recording
- dio: ^5.4.0                 # HTTP client
- http: ^1.1.0                # HTTP requests
- permission_handler: ^11.1.0 # Permissions
- path_provider: ^2.1.1       # File paths
- provider: ^6.1.1            # State management
```

### Backend (Python)
```
- fastapi==0.109.0           # Web framework
- uvicorn==0.27.0            # ASGI server
- openai-whisper             # Speech recognition
- SpeechRecognition          # Google SR
- pydub==0.25.1              # Audio processing
- nltk==3.8.1                # NLP tools
- Levenshtein==0.23.0        # Text similarity
```

## 🎨 Design Patterns

### Frontend
- **Repository Pattern**: API service abstraction
- **Widget Composition**: Reusable UI components
- **State Management**: StatefulWidgets
- **Async/Await**: For API calls

### Backend
- **Dependency Injection**: Model initialization
- **Repository Pattern**: Model separation
- **RESTful API**: Standard HTTP methods
- **Error Handling**: Try-catch blocks

## 🔐 Security Considerations

### Current Implementation
- ✅ CORS configured
- ✅ File validation
- ✅ Error handling
- ✅ Temporary file cleanup

### Production Recommendations
- [ ] Add API authentication (JWT)
- [ ] Rate limiting
- [ ] Input sanitization
- [ ] HTTPS only
- [ ] Database for persistence
- [ ] User session management

## 📈 Performance Metrics

### Expected Performance
- **API Response Time**: < 2 seconds
- **Speech Recognition**: 85-95% accuracy
- **App Size**: ~50MB
- **Memory Usage**: ~100MB
- **Battery Impact**: Low

## 🧪 Testing Strategy

### Frontend Testing
```bash
flutter test                  # Unit tests
flutter run --debug          # Debug mode
flutter run --release        # Release mode
```

### Backend Testing
- API endpoint testing with Postman
- Unit tests for models
- Integration tests for workflows
- Load testing for scalability

## 📝 Development Workflow

1. **Setup**: Install dependencies
2. **Development**: Code and test locally
3. **Testing**: Run tests and debug
4. **Documentation**: Update docs
5. **Deployment**: Build and release

## 🎓 Research Integration

This project structure supports:
- Easy data collection
- Performance monitoring
- User testing
- A/B testing
- Analytics integration

## 📞 Support

For questions about the structure:
1. Check README.md for overview
2. Read SETUP_GUIDE.md for installation
3. See TROUBLESHOOTING.md for issues
4. Review code comments for details

---

**This structure is designed for:**
- 🎯 Easy understanding
- 🔧 Simple maintenance
- 📈 Scalability
- 🎓 Research documentation
- 👥 Collaboration

**Happy coding! 🚀**
