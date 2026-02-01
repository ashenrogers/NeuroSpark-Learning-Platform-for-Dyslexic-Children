import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

class PronunciationGameScreen extends StatefulWidget {
  const PronunciationGameScreen({super.key});

  @override
  State<PronunciationGameScreen> createState() =>
      _PronunciationGameScreenState();
}

class _PronunciationGameScreenState extends State<PronunciationGameScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;
  late AnimationController _pulseController;

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
    _initializeTts();
    _words.shuffle(); // Randomize word order

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _audioRecorder.openRecorder();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Slower speed for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakWord(String word) async {
    await _flutterTts.speak(word);
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
      } else {
        // Play correct pronunciation if the answer is wrong
        await _speakWord(_words[_currentWordIndex]['word']!);
      }

      if (mounted) {
        _showResultDialog(
          isCorrect: isCorrect,
          confidence: confidence,
          transcription: transcription,
          analysisMethod: analysisMethod,
          phonemeAccuracy: phonemeAccuracy,
          modelUsed: modelUsed,
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to check pronunciation: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showResultDialog({
    required bool isCorrect,
    required double confidence,
    required String transcription,
    required String analysisMethod,
    required double phonemeAccuracy,
    required String modelUsed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCorrect
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.orange.shade50, Colors.orange.shade100],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Result Icon with Animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCorrect ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle : Icons.volume_up,
                  size: 60,
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                isCorrect ? '🌟 Perfect Pronunciation!' : '🔊 Listen & Try Again!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Details Cards
              if (transcription.isNotEmpty) ...[
                _buildDetailCard(
                  icon: Icons.mic,
                  title: 'What you said',
                  value: '"$transcription"',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
              ],

              _buildDetailCard(
                icon: Icons.trending_up,
                title: 'Confidence',
                value: '${(confidence * 100).toStringAsFixed(1)}%',
                color: _getConfidenceColor(confidence),
              ),

              if (phonemeAccuracy > 0) ...[
                const SizedBox(height: 12),
                _buildDetailCard(
                  icon: Icons.graphic_eq,
                  title: 'Sound Accuracy',
                  value: '${(phonemeAccuracy * 100).toStringAsFixed(1)}%',
                  color: Colors.purple,
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (!isCorrect) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _speakWord(_words[_currentWordIndex]['word']!);
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Hear Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _nextWord();
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(isCorrect ? 'Next Word' : 'Skip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCorrect ? Colors.green : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
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
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = _words[_currentWordIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade300,
              Colors.teal.shade200,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Instruction Text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🎤 Say this word clearly!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Word Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          currentWord['word']!,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hint Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade200,
                              Colors.yellow.shade200
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb,
                              color: Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currentWord['hint']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Processing or Record Button
                      if (_isProcessing)
                        _buildProcessingIndicator()
                      else
                        _buildRecordButton(),

                      const SizedBox(height: 24),

                      // Skip Button
                      TextButton.icon(
                        onPressed: _skipWord,
                        icon: const Icon(Icons.skip_next, size: 24),
                        label: const Text(
                          'Skip Word',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Bar
              _buildStatsBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.pop(context),
            color: Colors.green,
          ),
          const Expanded(
            child: Text(
              '🗣️ Pronunciation Practice',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_correctCount / $_totalAttempts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 20),
          Text(
            'Checking...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
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
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isRecording
                        ? [Colors.red.shade400, Colors.red.shade700]
                        : [Colors.green.shade400, Colors.green.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.green)
                          .withValues(alpha: 0.6),
                      spreadRadius: _isRecording ? 15 : 10,
                      blurRadius: 20 + (_pulseController.value * 10),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 80,
                  color: Colors.white,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _isRecording
                  ? Colors.red.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.green,
                width: 2,
              ),
            ),
            child: Text(
              _isRecording ? '🔴 Release to Stop' : '🎤 Hold to Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isRecording ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final accuracy = _totalAttempts > 0
        ? ((_correctCount / _totalAttempts) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            icon: Icons.check_circle,
            label: 'Correct',
            value: _correctCount.toString(),
            color: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.format_list_numbered,
            label: 'Attempts',
            value: _totalAttempts.toString(),
            color: Colors.blue,
          ),
          _buildStatCard(
            icon: Icons.percent,
            label: 'Accuracy',
            value: '$accuracy%',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
