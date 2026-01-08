import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../widgets/feedback_dialog.dart';

class VocabularyGameScreen extends StatefulWidget {
  const VocabularyGameScreen({super.key});

  @override
  State<VocabularyGameScreen> createState() => _VocabularyGameScreenState();
}

class _VocabularyGameScreenState extends State<VocabularyGameScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isLoading = false;
  Map<String, dynamic>? _currentQuestion;
  String? _selectedAnswer;
  int _correctCount = 0;
  int _totalAttempts = 0;
  String _difficulty = 'easy';
  bool _isPlayingAudio = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadQuestion();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.4); // Slower for children
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1); // Slightly higher pitch for friendliness
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _selectedAnswer = null;
    });

    try {
      final question = await _apiService.getVocabularyQuestion(
        difficulty: _difficulty,
      );
      setState(() => _currentQuestion = question);
    } catch (e) {
      _showErrorDialog('Failed to load question: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _speakText(String text) async {
    if (_isPlayingAudio) {
      await _flutterTts.stop();
      setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() => _isPlayingAudio = true);
    _animationController.repeat(reverse: true);

    await _flutterTts.speak(text);

    // Wait for speech to complete
    await Future.delayed(Duration(milliseconds: text.length * 50));

    setState(() => _isPlayingAudio = false);
    _animationController.reset();
  }

  Future<void> _checkAnswer() async {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkVocabularyAnswer(
        questionId: _currentQuestion!['question_id'],
        answer: _selectedAnswer!,
      );

      final isCorrect = result['is_correct'] ?? false;
      final correctAnswer = result['correct_answer'] ?? '';
      final explanation = result['explanation'] ?? '';

      setState(() {
        _totalAttempts++;
        if (isCorrect) _correctCount++;
      });

      if (mounted) {
        FeedbackDialog.show(
          context,
          isCorrect: isCorrect,
          message: isCorrect
              ? 'Awesome! You got it right! 🎉'
              : 'Good try! The correct answer is: $correctAnswer',
          details: explanation,
          onContinue: _loadQuestion,
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to check answer: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops!'),
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

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '⭐ Easy';
      case 'medium':
        return '⭐⭐ Medium';
      case 'hard':
        return '⭐⭐⭐ Hard';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
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
              _buildDifficultySelector(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingView()
                    : _currentQuestion == null
                        ? _buildErrorView()
                        : _buildQuestionView(),
              ),
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
        color: Colors.white.withValues(alpha: 0.9),
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
          const Text(
            '📚 Word Learning',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✓ $_correctCount / $_totalAttempts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎯 Choose Your Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['easy', 'medium', 'hard'].map((level) {
              final isSelected = _difficulty == level;
              final color = _getDifficultyColor(level);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _difficulty = level);
                      _loadQuestion();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: color,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Text(
                        _getDifficultyLabel(level).split(' ')[1],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
            child: const CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '✨ Loading your question...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadQuestion,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    final question = _currentQuestion!['question'] ?? '';
    final options = _currentQuestion!['options'] as List? ?? [];
    final questionType = _currentQuestion!['question_type'] ?? 'standard';
    final sentenceContext = _currentQuestion!['sentence_context'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio button for context-based questions
          if (sentenceContext != null) _buildAudioCard(sentenceContext),

          const SizedBox(height: 16),

          // Question card
          _buildQuestionCard(question, questionType),

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    questionType == 'confusing_pair'
                        ? 'Pick the correct word for the sentence'
                        : 'Tap the answer that fits best',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value.toString();
            final labels = ['A', 'B', 'C', 'D'];
            final isSelected = _selectedAnswer == option;
            final colors = [
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple
            ];
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedAnswer = option),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 4 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: isSelected ? 15 : 5,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : color,
                          border: Border.all(
                            color: color,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? color : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _selectedAnswer != null ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
              elevation: 8,
            ),
            child: const Text('✓ Submit Answer'),
          ),

          const SizedBox(height: 12),

          // Skip button
          OutlinedButton.icon(
            onPressed: _loadQuestion,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade400, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(String sentence) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.blue.shade300],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '🎧 Listen to the sentence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _speakText(sentence),
              icon: Icon(_isPlayingAudio ? Icons.stop : Icons.volume_up),
              label: Text(_isPlayingAudio ? 'Stop Audio' : 'Play Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question, String questionType) {
    IconData icon;
    Color iconColor;
    String title;

    if (questionType == 'confusing_pair') {
      icon = Icons.compare_arrows;
      iconColor = Colors.orange;
      title = '🔤 Choose the Right Word';
    } else {
      icon = Icons.help_outline;
      iconColor = Colors.purple;
      title = '❓ Question';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 56,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
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
            '✓ Correct',
            _correctCount.toString(),
            Colors.green,
          ),
          _buildStatCard(
            '📊 Total',
            _totalAttempts.toString(),
            Colors.blue,
          ),
          _buildStatCard(
            '⭐ Score',
            _totalAttempts > 0
                ? '${(_correctCount / _totalAttempts * 100).round()}%'
                : '0%',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
