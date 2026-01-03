import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../widgets/feedback_dialog.dart';

class PronunciationGameScreen extends StatefulWidget {
  const PronunciationGameScreen({super.key});

  @override
  State<PronunciationGameScreen> createState() =>
      _PronunciationGameScreenState();
}

class _PronunciationGameScreenState extends State<PronunciationGameScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  // Sample words for practice
  final List<Map<String, String>> _words = [
    {'word': 'elephant', 'hint': 'A large animal with a trunk'},
    {'word': 'beautiful', 'hint': 'Very pretty or attractive'},
    {'word': 'chocolate', 'hint': 'A sweet brown treat'},
    {'word': 'butterfly', 'hint': 'A colorful flying insect'},
    {'word': 'dinosaur', 'hint': 'An extinct prehistoric animal'},
    {'word': 'rainbow', 'hint': 'Colorful arc in the sky after rain'},
    {'word': 'adventure', 'hint': 'An exciting journey or experience'},
    {'word': 'wonderful', 'hint': 'Extremely good or pleasant'},
  ];

  int _currentWordIndex = 0;
  int _correctCount = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _words.shuffle(); // Randomize word order
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _audioRecorder.openRecorder();
  }

  
  Future<void> _startRecording() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      _audioPath =
          '${appDir.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
      );

      setState(() => _isRecording = true);
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);

      if (_audioPath != null) {
        _processRecording();
      }
    } catch (e) {
      _showErrorDialog('Failed to stop recording: $e');
    }
  }

  Future<void> _processRecording() async {
    setState(() => _isProcessing = true);

    try {
      final audioFile = File(_audioPath!);
      final response = await _apiService.checkPronunciation(
        audioFile: audioFile,
        word: _words[_currentWordIndex]['word']!,
      );

      final isCorrect = response['is_correct'] ?? false;
      final confidence = response['confidence'] ?? 0.0;
      final transcription = response['transcription'] ?? '';
      final analysisMethod = response['analysis_method'] ?? 'Unknown';
      final phonemeAccuracy = response['phoneme_accuracy'] ?? 0.0;
      final modelUsed = response['model_used'] ?? 'Unknown';

      setState(() => _totalAttempts++);

      if (isCorrect) {
        setState(() => _correctCount++);
      }

      if (mounted) {
        FeedbackDialog.show(
          context,
          isCorrect: isCorrect,
          message: isCorrect
              ? 'Perfect pronunciation!'
              : 'Try again! Your pronunciation needs improvement.',
          details: _buildPronunciationDetails(
            confidence,
            transcription,
            analysisMethod,
            phonemeAccuracy,
            modelUsed,
          ),
          onContinue: () {
            Navigator.pop(context);
            _nextWord();
          },
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to check pronunciation: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _buildPronunciationDetails(
    double confidence,
    String transcription,
    String analysisMethod,
    double phonemeAccuracy,
    String modelUsed,
  ) {
    String details = 'Overall Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n\n';
    
    if (transcription.isNotEmpty) {
      details += '🎤 What you said: "$transcription"\n\n';
    }
    
    if (phonemeAccuracy > 0) {
      details += '🔊 Phoneme Accuracy: ${(phonemeAccuracy * 100).toStringAsFixed(1)}%\n\n';
    }
    
    details += '🧠 Analysis Method: $analysisMethod\n';
    details += '🤖 Model Used: $modelUsed';
    
    return details;
  }

  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _words.length;
      _audioPath = null;
    });
  }

  void _skipWord() {
    _nextWord();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = _words[_currentWordIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Practice'),
        backgroundColor: Colors.green,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '$_correctCount / $_totalAttempts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Say this word:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.3),
                                spreadRadius: 3,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            currentWord['word']!,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  currentWord['hint']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        if (_isProcessing)
                          const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Checking pronunciation...'),
                            ],
                          )
                        else
                          _buildRecordButton(),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: _skipWord,
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Skip Word'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Correct',
                      _correctCount.toString(),
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Attempts',
                      _totalAttempts.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Accuracy',
                      _totalAttempts > 0
                          ? '${(_correctCount / _totalAttempts * 100).round()}%'
                          : '0%',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) => _stopRecording(),
      onTapCancel: () => _stopRecording(),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : Colors.green,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : Colors.green)
                      .withValues(alpha: 0.5),
                  spreadRadius: _isRecording ? 10 : 5,
                  blurRadius: 15,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? 'Release to stop'
                : 'Hold to record',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isRecording ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
