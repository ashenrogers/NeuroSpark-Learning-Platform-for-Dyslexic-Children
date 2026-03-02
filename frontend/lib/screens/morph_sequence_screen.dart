import 'package:flutter/material.dart';
import 'morph_playback_screen.dart';
import 'morph_recall_screen.dart';
import '../services/api_service.dart';
import '../services/bpm_manager.dart';

class MorphSequenceScreen extends StatefulWidget {
  const MorphSequenceScreen({super.key});

  @override
  State<MorphSequenceScreen> createState() => _MorphSequenceScreenState();
}

class _MorphSequenceScreenState extends State<MorphSequenceScreen> {
  int _currentLevelIndex = 0;
  int _totalScore = 0;
  int _highestLevelReached = 1;
  DateTime? _sessionStart;

  static const List<List<String>> allPairs = [
    ["triangle", "square"],
    ["square", "circle"],
    ["circle", "bird"],
    ["bird", "airplane"],
    ["airplane", "car"],
    ["car", "bus"],
    ["bus", "triangle"],
    ["bus", "airplane"],
  ];

  static const List<_LevelConfig> levels = [
    _LevelConfig(1, 90, 450, 0.5),   // Level 1: 1 transition (2 shapes)
    _LevelConfig(2, 85, 400, 0.6),   // Level 2: 2 transitions (3 shapes)
    _LevelConfig(3, 80, 350, 0.6),   // Level 3: 3 transitions (4 shapes)
    _LevelConfig(4, 75, 300, 0.7),   // Level 4: 4 transitions (5 shapes)
    _LevelConfig(5, 70, 250, 0.75),  // Level 5: 5 transitions (6 shapes)
    _LevelConfig(6, 60, 200, 0.8),   // Level 6: 6 transitions (7 shapes)
  ];

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!BpmManager.instance.hasValidHrData) {
        _showHrWarning();
      }
    });
  }

  void _showHrWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFAF9F6),
        title: const Text(
          "No Heart Sensor?",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        content: const Text(
          "You can still play without it!\n\nWe just won't record your heart rate.",
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLevelCompleteDialog({
  required int levelNumber,
  required int correct,
  required int total,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text("Level $levelNumber Complete"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Well done!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You remembered $correct out of $total shapes correctly.",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                "The next level will be a little more challenging.\n"
                "Take a moment and continue when you are ready.",
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Continue"),
            ),
          ],
        ),
      ) ??
      false;
}


  Future<void> _playNextLevel() async {
    if (_currentLevelIndex >= levels.length) {
      await _endSession();
      return;
    }

    final cfg = levels[_currentLevelIndex];
    final pairs = allPairs.take(cfg.transitions).toList();

    final seenSequence = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MorphPlaybackScreen(
          pairs: pairs,
          framesPerMorph: 31,
          frameDurationMs: cfg.frameMs,
          pauseBetweenMorphsMs: cfg.pauseMs,
        ),
      ),
    );

    if (!mounted || seenSequence == null) return;

    final childOrder = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => MorphRecallScreen(
          correctOrder: seenSequence,
          iconAssetForLabel: (l) => "assets/icons/$l.png",
        ),
      ),
    );

    if (!mounted || childOrder == null) return;

    final correct = _scoreExactPositions(seenSequence, childOrder);
    final accuracy = correct / seenSequence.length;

    _totalScore += correct;

    if (accuracy >= cfg.passAccuracy) {
  final proceed = await _showLevelCompleteDialog(
    levelNumber: _currentLevelIndex + 1,
    correct: correct,
    total: seenSequence.length,
  );

  if (!mounted || !proceed) return;

  _currentLevelIndex++;
  _highestLevelReached = _currentLevelIndex + 1;

  await _playNextLevel();
} else {
  await _showLevelFailedDialog(
    levelNumber: _currentLevelIndex + 1,
    correct: correct,
    total: seenSequence.length,
  );

  await _endSession();
}

  }

  Future<void> _showLevelFailedDialog({
  required int levelNumber,
  required int correct,
  required int total,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text("Level $levelNumber Completed"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Good effort!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You remembered $correct out of $total shapes correctly.",
          ),
          const SizedBox(height: 12),
          const Text(
            "This activity will now end.\n"
            "You can try again later when you feel ready.",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Finish"),
        ),
      ],
    ),
  );
}


  Future<void> _endSession() async {
    final totalTime = DateTime.now()
            .difference(_sessionStart!)
            .inMilliseconds /
        1000.0;

    await ApiService.saveScore(
      game: "morph_memory",
      score: _totalScore,
      totalTime: totalTime,
      levelDurations: const [],
      levelReached: _highestLevelReached,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Session Complete"),
        content: Text(
          "Total Score: $_totalScore\n"
          "Highest Level Reached: $_highestLevelReached",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Soft, low-glare background
      appBar: AppBar(
        title: const Text(
          "Morph Memory",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "How to Play",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3142),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),

              // Very simple, clear visual steps
              _buildStepCard(
                icon: Icons.change_circle_rounded,
                iconColor: Colors.blueAccent,
                text: "1. Watch the shapes change.",
              ),
              _buildStepCard(
                icon: Icons.visibility_rounded,
                iconColor: Colors.purpleAccent,
                text: "2. Remember their order.",
              ),
              _buildStepCard(
                icon: Icons.ads_click_rounded,
                iconColor: Colors.orangeAccent,
                text: "3. Put them back in place!",
              ),

              const Spacer(),

              // Large, clear, contrasting play button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50), // Friendly Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _playNextLevel,
                child: const Text(
                  "Start Game",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withOpacity(0.3), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0.5,
                color: Color(0xFF2D3142),
              ),
            ),
          ),
        ],
      ),
    );
  }


  int _scoreExactPositions(List<String> correct, List<String> child) {
    int s = 0;
    for (int i = 0; i < correct.length; i++) {
      if (i < child.length && child[i] == correct[i]) s++;
    }
    return s;
  }
}

class _LevelConfig {
  final int transitions;
  final int frameMs;
  final int pauseMs;
  final double passAccuracy;

  const _LevelConfig(
      this.transitions, this.frameMs, this.pauseMs, this.passAccuracy);
}
