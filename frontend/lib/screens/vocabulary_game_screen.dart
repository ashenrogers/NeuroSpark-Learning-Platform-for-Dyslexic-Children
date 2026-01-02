import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/feedback_dialog.dart';

class VocabularyGameScreen extends StatefulWidget {
  const VocabularyGameScreen({super.key});

  @override
  State<VocabularyGameScreen> createState() => _VocabularyGameScreenState();
}

class _VocabularyGameScreenState extends State<VocabularyGameScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _currentQuestion;
  String? _selectedAnswer;
  int _correctCount = 0;
  int _totalAttempts = 0;
  String _difficulty = 'easy';

  @override
  void initState() {
    super.initState();
    _loadQuestion();
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
              ? 'Excellent! You got it right!'
              : 'Not quite. The correct answer is: $correctAnswer',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Builder'),
        backgroundColor: Colors.orange,
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
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Difficulty selector
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Difficulty: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _difficulty,
                      underline: Container(),
                      items: ['easy', 'medium', 'hard']
                          .map((level) => DropdownMenuItem(
                                value: level,
                                child: Text(
                                  level.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _difficulty = value);
                          _loadQuestion();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading question...'),
                          ],
                        ),
                      )
                    : _currentQuestion == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 16),
                                const Text('Failed to load question'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadQuestion,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : _buildQuestionView(),
              ),
              // Stats bar
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
                      'Total',
                      _totalAttempts.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Score',
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

  Widget _buildQuestionView() {
    final question = _currentQuestion!['question'] ?? '';
    final options = _currentQuestion!['options'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Choose your answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value.toString();
            final labels = ['A', 'B', 'C', 'D'];
            final isSelected = _selectedAnswer == option;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedAnswer = option),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.orange : Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black54,
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
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedAnswer != null ? _checkAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('Submit Answer'),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadQuestion,
            icon: const Icon(Icons.skip_next),
            label: const Text('Skip Question'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
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
