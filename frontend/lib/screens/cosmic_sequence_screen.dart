// lib/screens/cosmic_sequence_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/bpm_manager.dart';

class CosmicSequenceScreen extends StatefulWidget {
  const CosmicSequenceScreen({Key? key}) : super(key: key);

  @override
  _CosmicSequenceScreenState createState() => _CosmicSequenceScreenState();
}

class _CosmicSequenceScreenState extends State<CosmicSequenceScreen> {
  // Premium, dyslexic-friendly palette with high contrast and distinct hues
  final List<Color> colors = [
    Color(0xFFE74C3C), // Warm red
    Color(0xFF3498DB), // Clear blue
    Color(0xFF2ECC71), // Fresh green
    Color(0xFFF39C12), // Amber/gold
    Color(0xFF9B59B6), // Royal purple
    Color(0xFFE67E22), // Burnt orange
    Color(0xFF1ABC9C), // Teal/turquoise
    Color(0xFFEC407A), // Rose pink
  ];

  List<int> sequence = [];
  List<int> playerInput = [];

  bool showingSequence = false;
  bool gameStarted = false;
  int? activeIndex;
  int score = 0;
  int highScore = 0;
  int level = 1;

  // timing
  DateTime? gameStart;
  DateTime? levelStart; // when player should begin input for current level
  double totalTime = 0.0;
  List<double> levelDurations = [];

  // UX state
  bool saving = false;

  @override
  void dispose() {
    super.dispose();
  }

  void startGame() {
    setState(() {
      sequence.clear();
      playerInput.clear();
      score = 0;
      level = 1;
      totalTime = 0.0;
      levelDurations.clear();
      gameStarted = true;
      gameStart = DateTime.now();
    });
    _startLevel();
  }

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!BpmManager.instance.hasValidHrData) {
      _showHeartRateWarning();
    }
  });
}
  void _showHeartRateWarning() {
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

  Future<void> _startLevel() async {
    // create sequence for the current level (length == level)
    playerInput.clear();
    sequence = List.generate(level, (_) => Random().nextInt(colors.length));

    // show sequence to player
    setState(() => showingSequence = true);
    await _showSequenceVisual();
    setState(() {
      showingSequence = false;
      activeIndex = null;
    });

    // start timing for player's input
    levelStart = DateTime.now();
  }

  Future<void> _showSequenceVisual() async {
    // flash each tile in sequence with a short pause
    for (int idx in sequence) {
      setState(() => activeIndex = idx);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => activeIndex = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // small pause before allowing input
    await Future.delayed(const Duration(milliseconds: 150));
  }

  Future<void> _handleTap(int index) async {
    if (showingSequence || !gameStarted) return;

    // register input
    playerInput.add(index);

    // quick visual feedback
    setState(() => activeIndex = index);
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => activeIndex = null);

    // check correctness
    int pos = playerInput.length - 1;
    if (sequence[pos] != playerInput[pos]) {
      // wrong -> game over
      await _endGameAndSave();
      return;
    }

    // if level completed
    if (playerInput.length == sequence.length) {
      // compute level duration (seconds)
      final now = DateTime.now();
      final lvlDuration = levelStart != null ? now.difference(levelStart!).inMilliseconds / 1000.0 : 0.0;
      levelDurations.add(lvlDuration);
      totalTime += lvlDuration;

      setState(() {
        score += 1;
        level += 1;
      });

      // small success pause
      await Future.delayed(const Duration(milliseconds: 400));

      // start next level
      await _startLevel();
    }
  }

  Future<void> _endGameAndSave() async {
    setState(() => saving = true);
    final finish = DateTime.now();
    final totalElapsed = gameStart != null ? finish.difference(gameStart!).inMilliseconds / 1000.0 : totalTime;
    // ensure levelDurations includes current incomplete level if started
    // (we won't count partial level unless the player completed it)

    // Save to backend (if user logged in)
    await ApiService.saveScore(
      game: "Cosmic Sequence",
      score: score,
      totalTime: totalElapsed,
      levelDurations: levelDurations,
      levelReached: level - 1, // last fully completed level
    );

    // update local
    if (score > highScore) highScore = score;
    setState(() {
      gameStarted = false;
      saving = false;
    });

    // show dialog
    _showGameOverDialog(totalElapsed);
  }

  void _showGameOverDialog(double totalElapsed) {
    String levelDetails = "";
    for (int i = 0; i < levelDurations.length; i++) {
      levelDetails += "Level ${i + 1}: ${levelDurations[i].toStringAsFixed(2)}s\n";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(
          "Score: $score\nHigh Score: $highScore\nTotal time: ${totalElapsed.toStringAsFixed(2)}s\n\nPer-level:\n$levelDetails",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: const Text("Play Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int i) {
    final bool active = activeIndex == i;
    return GestureDetector(
      onTap: () => _handleTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: active ? colors[i] : colors[i].withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.white : colors[i].withOpacity(0.3),
            width: active ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[i].withOpacity(active ? 0.5 : 0.25),
              blurRadius: active ? 20 : 10,
              spreadRadius: active ? 2 : 0,
              offset: Offset(0, active ? 8 : 4),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topBar = AppBar(
      title: const Text("Cosmic Sequence"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: topBar,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Level: $level",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Text("Score: $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: List.generate(colors.length, (i) => _buildTile(i)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!gameStarted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(saving ? "Saving..." : "Start Game", style: const TextStyle(fontSize: 16)),
                ),
              ),
            const SizedBox(height: 6),
            if (gameStarted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // manual end (save score so far)
                    await _endGameAndSave();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Quit & Save", style: TextStyle(color: Colors.black87)),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}