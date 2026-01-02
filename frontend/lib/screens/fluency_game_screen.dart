import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../widgets/score_card.dart';

class FluencyGameScreen extends StatefulWidget {
  const FluencyGameScreen({super.key});

  @override
  State<FluencyGameScreen> createState() => _FluencyGameScreenState();
}

class _FluencyGameScreenState extends State<FluencyGameScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  // Sample sentences for practice
  final List<String> _sentences = [
    'The quick brown fox jumps over the lazy dog.',
    'Reading helps us learn new things every day.',
    'I love to play with my friends at school.',
    'The sun shines bright in the clear blue sky.',
    'Practice makes perfect when learning to read.',
  ];

  int _currentSentenceIndex = 0;
  Map<String, dynamic>? _result;
  int _totalScore = 0;
  int _totalAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _audioRecorder.openRecorder();
  }

  Future<void> _startRecording() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      _audioPath = '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

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
    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final audioFile = File(_audioPath!);
      final response = await _apiService.checkFluency(
        audioFile: audioFile,
        expectedText: _sentences[_currentSentenceIndex],
      );

      setState(() {
        _result = response;
        _totalAttempts++;
        if (response['score'] != null) {
          _totalScore += (response['score'] as num).round().toInt();
        }
      });
    } catch (e) {
      _showErrorDialog('Failed to process recording: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _nextSentence() {
    setState(() {
      _currentSentenceIndex =
          (_currentSentenceIndex + 1) % _sentences.length;
      _result = null;
      _audioPath = null;
    });
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 10),
            const Text('How to Play'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Read the sentence shown clearly',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '2. Press and hold the microphone button',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '3. Release when finished speaking',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              '4. Get instant AI feedback on your reading',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: Colors.blue.shade600)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Fluency'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade200,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.menu_book,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reading Fluency',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Practice reading with AI feedback',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                          onPressed: () => _showInstructions(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              if (_totalAttempts > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: Colors.blue.withValues(alpha: 0.3),
                    child: ScoreCard(
                      score: _totalScore,
                      total: _totalAttempts * 100,
                      title: 'Overall Progress',
                    ),
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enhanced Sentence Display
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            AnimatedTextKit(
                              animatedTexts: [
                                TyperAnimatedText(
                                  _sentences[_currentSentenceIndex],
                                  textStyle: const TextStyle(
                                    fontSize: 26,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                  speed: const Duration(milliseconds: 50),
                                ),
                              ],
                              totalRepeatCount: 1,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Enhanced Recording Button
                      _buildEnhancedRecordButton(),
                      
                      if (_isProcessing)
                        Container(
                          margin: const EdgeInsets.only(top: 30),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              const SizedBox(height: 20),
                              Shimmer.fromColors(
                                baseColor: Colors.grey,
                                highlightColor: Colors.blue,
                                child: const Text(
                                  'Analyzing your recording...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (_result != null) _buildResultWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRecordButton() {
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : Colors.blue)
                      .withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isRecording
                        ? [Colors.red.shade600, Colors.red.shade400]
                        : [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue)
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: _isRecording ? 10 : 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isRecording)
                      Positioned(
                        top: 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 60,
                      color: Colors.white,
                    ),
                    if (_isRecording)
                      Positioned(
                        bottom: 25,
                        child: Shimmer.fromColors(
                          baseColor: Colors.white,
                          highlightColor: Colors.red.withValues(alpha: 0.5),
                          child: const Text(
                            'Recording',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRecording ? 'Release to stop' : 'Press and hold to record',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return 'Excellent reading!';
    if (score >= 60) return 'Good job!';
    if (score >= 40) return 'Keep practicing!';
    return 'Try again!';
  }

  Widget _buildResultWidget() {
    final score = (_result!['score'] ?? 0).toDouble();
    final transcription = _result!['transcription'] ?? '';
    final feedback = _result!['feedback'] ?? [];

    return Column(
      children: [
        const SizedBox(height: 24),
        // Enhanced Score Display
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getScoreColor(score).withValues(alpha: 0.8),
                _getScoreColor(score).withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getScoreColor(score).withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Your Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${score.round()}/100',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _getScoreMessage(score),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Transcription Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.record_voice_over,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'What you said:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  transcription.isNotEmpty ? transcription : 'No speech detected',
                  style: TextStyle(
                    fontSize: 16,
                    color: transcription.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Feedback Display
        if (feedback.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.feedback,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Word Analysis:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: feedback.map<Widget>((item) {
                    final word = item['word'] ?? '';
                    final isCorrect = item['correct'] ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isCorrect ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCorrect ? Icons.check : Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            word,
                            style: TextStyle(
                              fontSize: 16,
                              color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 30),
        
        // Enhanced Next Button
        Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _nextSentence,
              borderRadius: BorderRadius.circular(30),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Next Sentence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
