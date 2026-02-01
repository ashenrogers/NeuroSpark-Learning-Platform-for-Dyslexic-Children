import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'emotion_service.dart';

enum GameState { intro, playing, paused, finished }

class ColorSequenceGamePage extends StatefulWidget {
  const ColorSequenceGamePage({super.key});

  @override
  State<ColorSequenceGamePage> createState() => _ColorSequenceGamePageState();
}

class _ColorSequenceGamePageState extends State<ColorSequenceGamePage>
    with SingleTickerProviderStateMixin {
  // ---------------- STATE ----------------
  GameState gameState = GameState.intro;

  final Random _random = Random();
  final EmotionService _emotionService = EmotionService();

  // ---------------- DIFFICULTY ----------------
  int currentDifficulty = 1; // controls number of options

  // ---------------- SCORE ----------------
  int roundsPlayed = 0;
  int roundsSuccessful = 0;

  // ---------------- EMOTION ----------------
  String currentEmotion = 'neutral';

  // 🧠 EMOTION MEMORY (DYSLEXIA SAFE)
  final List<String> _emotionHistory = [];

  void _storeEmotion(String emotion) {
    _emotionHistory.add(emotion);
    if (_emotionHistory.length > 3) {
      _emotionHistory.removeAt(0);
    }
  }

  String _getDominantEmotion() {
    if (_emotionHistory.isEmpty) return 'neutral';

    final Map<String, int> count = {};
    for (final e in _emotionHistory) {
      count[e] = (count[e] ?? 0) + 1;
    }

    return count.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // ---------------- CAMERA ----------------
  CameraController? _cameraController;
  Timer? _emotionTimer;
  bool _emotionBusy = false;

  // ---------------- GAME TIMER ----------------
  Timer? _gameTimer;

  // ---------------- ANIMATION ----------------
  late AnimationController _emotionAnim;

  // ---------------- GAME DATA ----------------
  final List<_ColourOption> allColours = const [
    _ColourOption('RED', Colors.red),
    _ColourOption('BLUE', Colors.blue),
    _ColourOption('GREEN', Colors.green),
    _ColourOption('YELLOW', Colors.yellow),
    _ColourOption('ORANGE', Colors.orange),
    _ColourOption('PURPLE', Colors.purple),
  ];

  late _ColourOption targetColour;
  List<_ColourOption> options = [];

  @override
  void initState() {
    super.initState();
    _emotionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    await _emotionService.loadModel();
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.low,
      enableAudio: false,
    );
    await _cameraController!.initialize();
  }

  // ---------------- GAME FLOW ----------------
  void _startGame() {
    roundsPlayed = 0;
    roundsSuccessful = 0;
    currentDifficulty = 1;
    _emotionHistory.clear();

    _generateRound();

    gameState = GameState.playing;
    _gameTimer = Timer(const Duration(minutes: 3), _endGame);

    _emotionTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => _detectEmotion(),
    );

    setState(() {});
  }

  void _endGame() {
    _gameTimer?.cancel();
    _emotionTimer?.cancel();
    gameState = GameState.finished;
    setState(() {});
  }

  // ---------------- EMOTION (UNCHANGED) ----------------
  Future<void> _detectEmotion() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _emotionBusy ||
        gameState != GameState.playing) return;

    _emotionBusy = true;

    final file = await _cameraController!.takePicture();
    final bytes = await file.readAsBytes();

    final emotion = await _emotionService.predictFromBytes(bytes);
    _storeEmotion(emotion);

    currentEmotion = _getDominantEmotion();
    _emotionAnim.forward(from: 0);

    _updateDifficulty();
    setState(() {});
    _emotionBusy = false;
  }

  // ---------------- DIFFICULTY (UNCHANGED LOGIC) ----------------
  void _updateDifficulty() {
    final successRate =
        roundsPlayed == 0 ? 0.0 : roundsSuccessful / roundsPlayed;

    final sadCount =
        _emotionHistory.where((e) => e == 'sad' || e == 'angry').length;
    final happyCount =
        _emotionHistory.where((e) => e == 'happy').length;

    if (sadCount >= 2 && successRate < 0.6) {
      if (currentDifficulty > 1) currentDifficulty--;
    } else if (happyCount >= 2 && successRate > 0.8) {
      if (currentDifficulty < 3) currentDifficulty++;
    }

    _generateRound();
  }

  // ---------------- GAME LOGIC (NEW EASY GAME) ----------------
  void _generateRound() {
    final optionCount = 2 + currentDifficulty;

    final shuffled = List<_ColourOption>.from(allColours)..shuffle(_random);
    targetColour = shuffled.first;

    options = shuffled.take(optionCount).toList();
    if (!options.contains(targetColour)) {
      options[0] = targetColour;
    }
    options.shuffle(_random);

    setState(() {});
  }

  void _handleTap(_ColourOption selected) {
    roundsPlayed++;

    if (selected.name == targetColour.name) {
      roundsSuccessful++;
    }

    _generateRound();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (gameState == GameState.intro) return _intro();
    if (gameState == GameState.finished) return _end();
    return _game();
  }

  Widget _game() {
    final progress =
        roundsPlayed == 0 ? 0.0 : roundsSuccessful / roundsPlayed;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan.shade100,
              Colors.blue.shade100,
              Colors.purple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // SCORE + EMOTION BAR
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Score container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '$roundsSuccessful / $roundsPlayed',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Emotion container
                    ScaleTransition(
                      scale: Tween(begin: 0.8, end: 1.2).animate(
                        CurvedAnimation(parent: _emotionAnim, curve: Curves.elasticOut),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _safeMoodLabel(currentEmotion),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PROGRESS BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                      minHeight: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // INSTRUCTION TEXT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      '👆',
                      style: TextStyle(fontSize: 28),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Find the matching colour!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TARGET COLOUR with glow effect
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: targetColour.color.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: targetColour.color,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white,
                      width: 6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Arrow pointing down
              const Text(
                '⬇️',
                style: TextStyle(fontSize: 40),
              ),

              const SizedBox(height: 20),

              // OPTIONS GRID
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: options.map((c) {
                      return _MatchColorButton(
                        option: c,
                        onTap: () => _handleTap(c),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.cyan.shade200,
                Colors.blue.shade200,
                Colors.indigo.shade200,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fun title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🔍',
                          style: TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Same Colour',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Find matching colours!',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Start button
                  GestureDetector(
                    onTap: _startGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade400],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                          SizedBox(width: 12),
                          Text(
                            'START GAME',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Back button
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white),
                    label: const Text(
                      'Back',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _end() {
    int stars = roundsPlayed == 0
        ? 1
        : (roundsSuccessful / roundsPlayed > 0.8
            ? 3
            : roundsSuccessful / roundsPlayed > 0.5
                ? 2
                : 1);

    final accuracy = roundsPlayed == 0 ? 0.0 : roundsSuccessful / roundsPlayed;
    final encouragement = accuracy > 0.8
        ? 'Fantastic! 🎉'
        : accuracy > 0.5
            ? 'Well Done! 👏'
            : 'Keep Going! 💪';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.yellow.shade200,
              Colors.amber.shade200,
              Colors.orange.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        encouragement,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          stars,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star, size: 50, color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              '$roundsSuccessful / $roundsPlayed',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade400],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🔄 Play Again',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      '🏠 Back to Home',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _safeMoodLabel(String e) {
    switch (e) {
      case 'happy':
        return '😊 Happy';
      case 'sad':
      case 'angry':
        return '🙂 Trying';
      default:
        return '😐 Focused';
    }
  }

  @override
  void dispose() {
    _emotionAnim.dispose();
    _cameraController?.dispose();
    _emotionTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }
}

// Match color button widget with animation
class _MatchColorButton extends StatefulWidget {
  final _ColourOption option;
  final VoidCallback onTap;

  const _MatchColorButton({
    required this.option,
    required this.onTap,
  });

  @override
  State<_MatchColorButton> createState() => _MatchColorButtonState();
}

class _MatchColorButtonState extends State<_MatchColorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: widget.option.color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.option.color.withOpacity(0.6),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 6,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColourOption {
  final String name;
  final Color color;
  const _ColourOption(this.name, this.color);
}