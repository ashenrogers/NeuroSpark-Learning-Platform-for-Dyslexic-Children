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
    _LevelConfig(3, 90, 350, 0.6),
    _LevelConfig(4, 80, 300, 0.7),
    _LevelConfig(5, 70, 250, 0.75),
    _LevelConfig(6, 60, 200, 0.8),
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
        title: const Text("Heart Rate Monitor Not Connected"),
        content: const Text(
          "You can continue playing. "
          "Stress data will not be recorded for this session.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Proceed"),
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
    backgroundColor: const Color(0xFFF6F7F9),
    appBar: AppBar(
      title: const Text("Morph Memory Game"),
    ),
    body: Stack(
      children: [
        // ===== MAIN CONTENT =====
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // INTRO CARD
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "How this activity works",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "You will see a sequence of shapes smoothly changing "
                        "from one form to another.\n\n"
                        "Watch carefully and remember the order in which the "
                        "shapes appear.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // DIFFICULTY CARD
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Difficulty progression",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "• The activity starts with a short sequence.\n"
                        "• As you remember more correctly, the sequence becomes longer.\n"
                        "• The shapes will change slightly faster at higher levels.\n\n"
                        "There is no time pressure — just try your best.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // HEART RATE INFO
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.favorite, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "If a heart-rate sensor is connected, the app will "
                          "observe changes in heart rate during the activity.\n\n"
                          "This helps us understand effort and focus. "
                          "If the device is not connected, the game will still work normally.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // START BUTTON
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    "Start Activity",
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: _playNextLevel,
                ),
              ),
            ],
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
