import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';

class FluencyGameScreen extends StatefulWidget {
  const FluencyGameScreen({super.key});

  @override
  State<FluencyGameScreen> createState() => _FluencyGameScreenState();
}

class _FluencyGameScreenState extends State<FluencyGameScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _audioPath;

  // Sample sentences for practice
  final List<String> _sentences = [
    'Reading helps us learn new things every day.',
    'My favorite story is about a brave little mouse.',
    'I love to play with my friends at school.',
    'The sun shines bright in the clear blue sky.',
    'Practice makes perfect when learning to read.',
    'Every child can learn to read with practice.',
    'Books open doors to wonderful new worlds.',
    'Listening carefully helps improve pronunciation.',
  ];

  int _currentSentenceIndex = 0;
  Map<String, dynamic>? _result;
  int _totalScore = 0;
  int _totalAttempts = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
          '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
      });
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
        if (response['final_score'] != null) {
          _totalScore += (response['final_score'] as num).round().toInt();
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
      _currentSentenceIndex = (_currentSentenceIndex + 1) % _sentences.length;
      _result = null;
      _audioPath = null;
    });
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('How to Play', style: TextStyle(fontSize: 22)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep('1', Icons.visibility, 'Read the sentence shown clearly'),
              const SizedBox(height: 16),
              _buildInstructionStep('2', Icons.mic, 'Press and hold the microphone button'),
              const SizedBox(height: 16),
              _buildInstructionStep('3', Icons.stop_circle, 'Release when finished speaking'),
              const SizedBox(height: 16),
              _buildInstructionStep('4', Icons.auto_awesome, 'Get instant AI feedback'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Try to read clearly and at a comfortable pace!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Got it! Let\'s Start!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 10),
            Text('Oops!'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade100,
              Colors.blue.shade100,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_totalAttempts > 0) _buildOverallProgressCard(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSentenceCard(),
                      const SizedBox(height: 30),
                      _buildRecordButton(),
                      if (_isProcessing) _buildProcessingCard(),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📖 Reading Fluency',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  'Practice makes perfect!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.purple, size: 28),
            onPressed: _showInstructions,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildProgressStat(
              '🎯',
              'Attempts',
              _totalAttempts.toString(),
            ),
            Container(width: 2, height: 40, color: Colors.white.withValues(alpha: 0.3)),
            _buildProgressStat(
              '⭐',
              'Avg Score',
              _totalAttempts > 0
                  ? '${(_totalScore / _totalAttempts).round()}%'
                  : '0%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSentenceCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.menu_book, size: 48, color: Colors.purple),
          const SizedBox(height: 16),
          AnimatedTextKit(
            key: ValueKey(_currentSentenceIndex),
            animatedTexts: [
              TyperAnimatedText(
                _sentences[_currentSentenceIndex],
                textStyle: const TextStyle(
                  fontSize: 24,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
                speed: const Duration(milliseconds: 40),
              ),
            ],
            totalRepeatCount: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return Center(
      child: Column(
        children: [
          ScaleTransition(
            scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : Colors.blue)
                        .withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: GestureDetector(
                onTapDown: (_) => _startRecording(),
                onTapUp: (_) => _stopRecording(),
                onTapCancel: () => _stopRecording(),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isRecording
                          ? [Colors.red.shade600, Colors.red.shade800]
                          : [Colors.blue.shade600, Colors.blue.shade800],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic,
                        size: 80,
                        color: Colors.white,
                      ),
                      if (_isRecording)
                        Positioned(
                          bottom: 30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Recording...',
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
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              _isRecording ? '🔴 Release to stop' : '🎤 Press and hold to record',
              style: TextStyle(
                fontSize: 16,
                color: _isRecording ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.2),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade600,
            highlightColor: Colors.purple,
            child: const Text(
              '✨ Analyzing your reading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Checking pronunciation and speed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultWidget() {
    final finalScore = (_result!['final_score'] ?? 0).toDouble();
    final pronunciationScore = (_result!['pronunciation_score'] ?? 0).toDouble();
    final speedMetrics = _result!['speed_metrics'] ?? {};
    final wpm = speedMetrics['wpm'] ?? 0;
    final speedRating = speedMetrics['speed_rating'] ?? '';
    final duration = speedMetrics['duration'] ?? 0;
    final overallRating = _result!['overall_rating'] ?? '';
    final transcription = _result!['transcription'] ?? '';
    final feedback = _result!['feedback'] ?? [];

    return Column(
      children: [
        const SizedBox(height: 30),

        // Overall Score Card
        _buildScoreCard(
          title: '🎯 Final Score',
          score: finalScore,
          subtitle: overallRating,
          gradient: _getScoreGradient(finalScore),
        ),

        const SizedBox(height: 16),

        // Speed & Pronunciation Breakdown
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed,
                title: 'Reading Speed',
                value: '${wpm.round()} WPM',
                subtitle: speedRating,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.record_voice_over,
                title: 'Pronunciation',
                value: '${pronunciationScore.round()}%',
                subtitle: _getPronunciationRating(pronunciationScore),
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Duration Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              Text(
                'Time taken: ${duration.toStringAsFixed(1)}s',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Transcription
        _buildTranscriptionCard(transcription),

        const SizedBox(height: 20),

        // Word Feedback
        if (feedback.isNotEmpty) _buildWordFeedbackCard(feedback),

        const SizedBox(height: 24),

        // Next Button
        _buildNextButton(),
      ],
    );
  }

  Widget _buildScoreCard({
    required String title,
    required double score,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${score.round()}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
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
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionCard(String transcription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hearing,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'What you said:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              transcription.isNotEmpty
                  ? transcription
                  : 'No speech detected',
              style: TextStyle(
                fontSize: 16,
                color: transcription.isNotEmpty
                    ? Colors.black87
                    : Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordFeedbackCard(List feedback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Word by Word:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: feedback.map<Widget>((item) {
              final word = item['word'] ?? '';
              final isCorrect = item['correct'] ?? false;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCorrect ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check : Icons.close,
                      size: 18,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      word,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
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
    );
  }

  Widget _buildNextButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextSentence,
          borderRadius: BorderRadius.circular(30),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.skip_next, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Next Sentence',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getScoreGradient(double score) {
    if (score >= 80) return [Colors.green.shade400, Colors.green.shade600];
    if (score >= 60) return [Colors.orange.shade400, Colors.orange.shade600];
    return [Colors.red.shade400, Colors.red.shade600];
  }

  String _getPronunciationRating(double score) {
    if (score >= 90) return 'Perfect! 🌟';
    if (score >= 80) return 'Excellent! 🎉';
    if (score >= 70) return 'Great! 👍';
    if (score >= 60) return 'Good! 😊';
    return 'Keep trying! 💪';
  }
}
