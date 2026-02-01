# 🔧 Troubleshooting Guide

Common issues and solutions for the Dyslexia Support App.

## Table of Contents
1. [Backend Issues](#backend-issues)
2. [Frontend Issues](#frontend-issues)
3. [Network Issues](#network-issues)
4. [Audio Recording Issues](#audio-recording-issues)
5. [Performance Issues](#performance-issues)

---

## Backend Issues

### Issue 1: "ModuleNotFoundError"

**Error:**
```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution:**
```bash
# Activate virtual environment first
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### Issue 2: "FFmpeg not found"

**Error:**
```
FileNotFoundError: [Errno 2] No such file or directory: 'ffmpeg'
```

**Solution:**

**Windows:**
1. Download FFmpeg from https://ffmpeg.org
2. Extract to `C:\ffmpeg`
3. Add `C:\ffmpeg\bin` to System PATH
4. Restart terminal

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
sudo apt install ffmpeg
```

### Issue 3: "Port already in use"

**Error:**
```
OSError: [Errno 98] Address already in use
```

**Solution:**

**Windows:**
```bash
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

**macOS/Linux:**
```bash
lsof -ti:8000 | xargs kill -9
```

Or change the port in `.env`:
```env
API_PORT=8001
```

### Issue 4: "Whisper model download fails"

**Error:**
```
ConnectionError: Failed to download model
```

**Solution:**
1. Check internet connection
2. Try smaller model first:
   ```python
   # In speech_recognition_model.py
   self.whisper_model = whisper.load_model("tiny")  # Instead of "base"
   ```
3. Manual download:
   ```bash
   python -c "import whisper; whisper.load_model('base')"
   ```

### Issue 5: "CUDA/GPU errors"

**Error:**
```
RuntimeError: CUDA out of memory
```

**Solution:**
```bash
# Install CPU-only PyTorch
pip uninstall torch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

Or disable Whisper:
```python
# In main.py
speech_model = SpeechRecognitionModel(use_whisper=False)
```

---

## Frontend Issues

### Issue 1: "SDK licenses not accepted"

**Error:**
```
Error: Android sdkmanager tool was found, but failed to run
```

**Solution:**
```bash
flutter doctor --android-licenses
# Accept all licenses by typing 'y'
```

### Issue 2: "Microphone permission denied"

**Symptoms:**
- App crashes when recording
- No audio recorded

**Solution:**
1. Check `AndroidManifest.xml` has permissions:
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   ```

2. Grant permissions manually:
   - Device Settings → Apps → Dyslexia Support
   - Permissions → Enable Microphone and Storage

3. Request permissions in code (already implemented):
   ```dart
   await Permission.microphone.request();
   ```

### Issue 3: "Cannot connect to backend"

**Error in logs:**
```
DioError [DioErrorType.connectTimeout]: Connecting timed out
```

**Solution:**

**For Android Emulator:**
```dart
// In api_service.dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**For Physical Device:**
1. Find your computer's local IP:
   ```bash
   # Windows
   ipconfig
   
   # macOS/Linux
   ifconfig
   ```

2. Update API URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:8000';
   ```

3. Ensure both devices on same WiFi network

4. Check firewall allows connections on port 8000

### Issue 4: "Build failed - Gradle error"

**Error:**
```
FAILURE: Build failed with an exception
```

**Solution:**
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Clear Gradle cache
cd android
./gradlew clean

# Try build again
cd ..
flutter run
```

### Issue 5: "Hot reload not working"

**Solution:**
```bash
# Full restart instead of hot reload
# Press 'R' in terminal (capital R)

# Or stop and restart
flutter run
```

---

## Network Issues

### Issue 1: "Connection refused"

**Symptoms:**
- "Connection refused" error
- Cannot reach backend

**Checklist:**
- ✅ Backend server is running
- ✅ Correct IP address in `api_service.dart`
- ✅ Firewall allows connections
- ✅ Both devices on same network (for physical device)
- ✅ Using `http://` not `https://`

**Test connection:**
```bash
# From your device/emulator browser, visit:
http://10.0.2.2:8000/health  # Emulator
http://YOUR_IP:8000/health   # Physical device
```

### Issue 2: "Timeout errors"

**Solution:**
1. Increase timeout in `api_service.dart`:
   ```dart
   BaseOptions(
     baseUrl: baseUrl,
     connectTimeout: const Duration(seconds: 60),  // Increase
     receiveTimeout: const Duration(seconds: 60),  // Increase
   )
   ```

2. Check network speed
3. Try smaller audio files

---

## Audio Recording Issues

### Issue 1: "No audio recorded"

**Checklist:**
- ✅ Microphone permission granted
- ✅ Device has working microphone
- ✅ Not muted
- ✅ Record package installed: `flutter pub get`

**Test microphone:**
1. Use another recording app to verify hardware works
2. Check Flutter logs for errors:
   ```bash
   flutter logs
   ```

### Issue 2: "Poor audio quality"

**Solution:**
1. Speak clearly and close to microphone
2. Reduce background noise
3. Adjust recording config in code:
   ```dart
   await _audioRecorder.start(
     RecordConfig(
       encoder: AudioEncoder.wav,
       bitRate: 128000,  // Higher quality
       sampleRate: 44100,
     ),
     path: _audioPath!,
   );
   ```

### Issue 3: "Audio file too large"

**Solution:**
1. Use shorter recordings
2. Change encoder:
   ```dart
   encoder: AudioEncoder.aacLc,  // More compressed
   ```

---

## Performance Issues

### Issue 1: "Backend slow to respond"

**Solutions:**
1. Use smaller Whisper model:
   ```python
   self.whisper_model = whisper.load_model("tiny")
   ```

2. Disable Whisper, use Google only:
   ```python
   speech_model = SpeechRecognitionModel(use_whisper=False)
   ```

3. Optimize server hardware (more RAM/CPU)

### Issue 2: "App laggy or slow"

**Solutions:**
1. Enable release mode:
   ```bash
   flutter run --release
   ```

2. Reduce animations
3. Test on better device
4. Check for memory leaks in logs

### Issue 3: "App crashes"

**Solution:**
1. Check logs:
   ```bash
   flutter logs
   adb logcat  # Android
   ```

2. Add error handling:
   ```dart
   try {
     // Your code
   } catch (e) {
     print('Error: $e');
   }
   ```

3. Check memory usage:
   ```bash
   flutter run --profile
   ```

---

## Debug Tips

### Enable Verbose Logging

**Backend:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Frontend:**
```bash
flutter run --verbose
```

### Test API Independently

```bash
# Test with cURL
curl -X POST http://localhost:8000/api/pronunciation/check \
  -F "audio=@test.wav" \
  -F "word=hello"
```

### Monitor Network Traffic

Use tools like:
- Postman for API testing
- Charles Proxy for network monitoring
- Android Studio Network Profiler

### Check Resource Usage

```bash
# Backend CPU/Memory
top  # Linux/Mac
taskmgr  # Windows

# Frontend
flutter run --profile
```

---

## Still Having Issues?

If problems persist:

1. **Review logs carefully** - They usually indicate the exact issue
2. **Search error messages** - Many issues are documented online
3. **Check versions** - Ensure all dependencies are compatible
4. **Try simple test first** - Test each component independently
5. **Ask for help** - Include error logs and steps to reproduce

### Useful Resources

- Flutter Documentation: https://docs.flutter.dev
- FastAPI Documentation: https://fastapi.tiangolo.com
- Whisper GitHub: https://github.com/openai/whisper
- Stack Overflow: Tag your questions with `flutter`, `fastapi`, `speech-recognition`

---

**Remember**: Most issues have simple solutions. Start with the basics: permissions, network, and dependencies. 🎯
