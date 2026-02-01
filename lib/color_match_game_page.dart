import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'emotion_service.dart';

/// GAME STATES
enum GameState { intro, playing, paused, finished }

class ColorMatchGamePage extends StatefulWidget {
  const ColorMatchGamePage({super.key});

  @override
  State<ColorMatchGamePage> createState() => _ColorMatchGamePageState();
}

class _ColorMatchGamePageState extends State<ColorMatchGamePage>
    with SingleTickerProviderStateMixin {
  // ---------------- STATE ----------------
  GameState gameState = GameState.intro;

  final Random _random = Random();
  final EmotionService _emotionService = EmotionService();

  // ---------------- GAME DATA ----------------
  int currentDifficulty = 1;
  int correctAnswers = 0;
  int totalAnswers = 0;
  int mistakesInRow = 0;

  late String targetColorName;
  late Color targetColor;
  List<_ColourOption> options = [];

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

  @override
  void initState() {
    super.initState();
    _emotionAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initCamera();
  }

  // ---------------- CAMERA INIT ----------------
  Future<void> _initCamera() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    await _emotionService.loadModel();

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  // ---------------- GAME FLOW ----------------
  void _startGame() {
    correctAnswers = 0;
    totalAnswers = 0;
    mistakesInRow = 0;
    currentDifficulty = 1;
    _emotionHistory.clear();

    _startNewRound();
//end of the game 
    gameState = GameState.playing;

    _gameTimer = Timer(const Duration(minutes: 3), _endGame);

    // Emotion detection every 90 seconds (dyslexia-friendly)
    _emotionTimer = Timer.periodic(
      const Duration(seconds: 05),
      (_) => _detectEmotion(),
    );

    setState(() {});
  }

  void _pauseGame() {
    _gameTimer?.cancel();
    _emotionTimer?.cancel();
    gameState = GameState.paused;
    setState(() {});
  }

  void _resumeGame() {
    gameState = GameState.playing;
    _gameTimer = Timer(const Duration(minutes: 3), _endGame);
    _emotionTimer = Timer.periodic(
      const Duration(seconds: 05),
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

  // ---------------- EMOTION ----------------
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

  //  DYSLEXIA-SAFE DIFFICULTY LOGIC
  void _updateDifficulty() {
    final accuracy =
        totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;

    final sadCount = _emotionHistory
        .where((e) => e == 'sad' || e == 'angry')
        .length;

    final happyCount =
        _emotionHistory.where((e) => e == 'happy').length;

    //  Reduce difficulty (frustration)
    if ((sadCount >= 2 && accuracy < 0.6) || mistakesInRow >= 3) {
      if (currentDifficulty > 1) {
        currentDifficulty--;
      }
      return;
    }

    //  Increase difficulty (comfort)
    if (happyCount >= 2 && accuracy > 0.8) {
      if (currentDifficulty < 5) {
        currentDifficulty++;
      }
    }
  }

  // ---------------- GAME LOGIC ----------------
  void _startNewRound() {
    final count = 2 + currentDifficulty;
    final shuffled = List<_ColourOption>.from(allColours)..shuffle(_random);
    options = shuffled.take(count).toList();

    final target = options[_random.nextInt(options.length)];
    targetColorName = target.name;
    targetColor = target.color;
  }

  void _handleAnswer(_ColourOption selected) {
    totalAnswers++;

    if (selected.name == targetColorName) {
      correctAnswers++;
      mistakesInRow = 0;
    } else {
      mistakesInRow++;
    }

    _updateDifficulty();
    _startNewRound();
    setState(() {});
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    switch (gameState) {
      case GameState.intro:
        return _introScreen();
      case GameState.playing:
        return _gameScreen();
      case GameState.paused:
        return _pauseScreen();
      case GameState.finished:
        return _endScreen();
    }
  }

  Widget _introScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade200,
              Colors.pink.shade200,
              Colors.purple.shade200,
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
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🎨',
                        style: TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Colour Match',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the matching colour!',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.purple.shade700,
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
  }

  Widget _gameScreen() {
    final progress =
        totalAnswers == 0 ? 0.0 : correctAnswers / max(10, totalAnswers);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.purple.shade100,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with score and emotion
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
                            '$correctAnswers / $totalAnswers',
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _emotionEmoji(currentEmotion),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    // Pause button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.pause_rounded, size: 32),
                        color: Colors.deepPurple,
                        onPressed: _pauseGame,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
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
              // Target word in a fun container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: targetColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Find this colour:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      targetColorName,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: targetColor,
                        shadows: [
                          Shadow(
                            color: targetColor.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Color options grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: options.map((opt) {
                      return _ColorButton(
                        option: opt,
                        onTap: () => _handleAnswer(opt),
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

  Widget _pauseScreen() => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.indigo.shade200,
                Colors.blue.shade200,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '⏸️',
                  style: TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Game Paused',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 60),
                GestureDetector(
                  onTap: _resumeGame,
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
                          'RESUME',
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
              ],
            ),
          ),
        ),
      );

  Widget _endScreen() {
    final stars = _rewardStars();
    final accuracy = totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;
    final encouragement = accuracy > 0.8
        ? 'Amazing! 🎉'
        : accuracy > 0.5
            ? 'Great Job! 👏'
            : 'Keep Trying! 💪';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.yellow.shade200,
              Colors.orange.shade200,
              Colors.pink.shade200,
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
                        color: Colors.orange.withOpacity(0.3),
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
                        children: stars,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              '$correctAnswers / $totalAnswers',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
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
                        color: Colors.purple.shade700,
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

  // ---------------- HELPERS ----------------
  String _emotionEmoji(String e) {
    switch (e) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'surprise':
        return '😲';
      default:
        return '😐';
    }
  }

  List<Widget> _rewardStars() {
    final accuracy =
        totalAnswers == 0 ? 0.0 : correctAnswers / totalAnswers;

    int count = accuracy > 0.8
        ? 3
        : accuracy > 0.5
            ? 2
            : 1;

    return List.generate(
      count,
      (_) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.star, color: Colors.amber, size: 50),
      ),
    );
  }

  @override
  void dispose() {
    _emotionAnim.dispose();
    _gameTimer?.cancel();
    _emotionTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Color button widget with animation
class _ColorButton extends StatefulWidget {
  final _ColourOption option;
  final VoidCallback onTap;

  const _ColorButton({
    required this.option,
    required this.onTap,
  });

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton>
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
              width: 5,
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Text(
                widget.option.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.option.color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- COLOURS ----------------
const List<_ColourOption> allColours = [
  _ColourOption('RED', Colors.red),
  _ColourOption('BLUE', Colors.blue),
  _ColourOption('GREEN', Colors.green),
  _ColourOption('YELLOW', Colors.yellow),
  _ColourOption('ORANGE', Colors.orange),
  _ColourOption('PURPLE', Colors.purple),
];

class _ColourOption {
  final String name;
  final Color color;
  const _ColourOption(this.name, this.color);
}
