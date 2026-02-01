import 'dart:async';
import 'dart:math';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'emotion_service.dart';

enum GameState { intro, playing, paused, finished }

class ColorSortingGamePage extends StatefulWidget {
  const ColorSortingGamePage({super.key});

  @override
  State<ColorSortingGamePage> createState() => _ColorSortingGamePageState();
}

class _ColorSortingGamePageState extends State<ColorSortingGamePage>
    with SingleTickerProviderStateMixin {
  // ---------------- STATE ----------------
  GameState gameState = GameState.intro;

  final Random _random = Random();
  final EmotionService _emotionService = EmotionService();

  // ---------------- DIFFICULTY ----------------
  int currentDifficulty = 1;

  // ---------------- SCORE ----------------
  int totalItems = 0;
  int correctAssignments = 0;

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

  List<_ColourOption> buckets = [];
  List<_Item> items = [];

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

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  // ---------------- GAME FLOW ----------------
  void _startGame() {
    currentDifficulty = 1;
    correctAssignments = 0;
    totalItems = 0;
    _emotionHistory.clear();

    _generateRound();

    gameState = GameState.playing;
    _gameTimer = Timer(const Duration(minutes: 3), _endGame);

    // ⏱️ Dyslexia-friendly emotion detection (90s)
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

  // 🧠 DYSLEXIA-SAFE DIFFICULTY LOGIC
  void _updateDifficulty() {
    final accuracy =
        totalItems == 0 ? 0.0 : correctAssignments / totalItems;

    final sadCount = _emotionHistory
        .where((e) => e == 'sad' || e == 'angry')
        .length;

    final happyCount =
        _emotionHistory.where((e) => e == 'happy')
        .length;

    // 🔽 Reduce difficulty (frustration)
    if (sadCount >= 2 && accuracy < 0.6) {
      if (currentDifficulty > 1) {
        currentDifficulty--;
      }
      return;
    }

    // 🔼 Increase difficulty (comfort)
    if (happyCount >= 2 && accuracy > 0.8) {
      if (currentDifficulty < 5) {
        currentDifficulty++;
      }
    }
  }

  // ---------------- GAME LOGIC ----------------
  void _generateRound() {
    final bucketCount = 2 + currentDifficulty;
    final itemCount = 4 + currentDifficulty * 2;

    final shuffled = List<_ColourOption>.from(allColours)..shuffle(_random);
    buckets = shuffled.take(bucketCount.clamp(2, 6)).toList();

    items = List.generate(
      itemCount,
      (i) {
        final colour = buckets[_random.nextInt(buckets.length)];
        return _Item(id: i, colour: colour);
      },
    );

    totalItems = itemCount;
    correctAssignments = 0;
    setState(() {});
  }

  void _assignItem(_Item item, _ColourOption bucket) {
    final wasCorrect =
        item.assignedBucket?.name == item.colour.name;
    final willBeCorrect = bucket.name == item.colour.name;

    if (wasCorrect && !willBeCorrect) {
      correctAssignments--;
    } else if (!wasCorrect && willBeCorrect) {
      correctAssignments++;
    }

    item.assignedBucket = bucket;

    if (items.every((i) => i.assignedBucket != null)) {
      _updateDifficulty();
      _generateRound();
    }

    setState(() {});
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (gameState == GameState.intro) return _intro();
    if (gameState == GameState.finished) return _end();
    return _game();
  }

  Widget _intro() => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade200,
                Colors.teal.shade200,
                Colors.cyan.shade200,
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
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🧺',
                          style: TextStyle(fontSize: 60),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Colour Sorting',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sort into buckets!',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.teal.shade700,
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

  Widget _game() {
    final progress =
        totalItems == 0 ? 0.0 : correctAssignments / totalItems;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lime.shade100,
              Colors.teal.shade100,
              Colors.cyan.shade100,
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
                          const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            '$correctAssignments / $totalItems',
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
                          _emoji(currentEmotion),
                          style: const TextStyle(fontSize: 32),
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

              const SizedBox(height: 20),

              // ITEMS TO SORT
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: item.colour.color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: item.colour.color.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            'Item ${item.id + 1}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: item.assignedBucket != null
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              item.assignedBucket?.name ?? 'Not sorted',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.assignedBucket != null
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // INSTRUCTION TEXT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '👇',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Tap a bucket to sort!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // BUCKETS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: buckets.map((bucket) {
                    return GestureDetector(
                      onTap: () async {
                        final item = await showDialog<_Item>(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    bucket.color.withOpacity(0.3),
                                    bucket.color.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: bucket.color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: bucket.color.withOpacity(0.5),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Choose item for',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    bucket.name,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: bucket.color,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ...items.map((it) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context, it),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: it.colour.color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                'Item ${it.id + 1}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (item != null) _assignItem(item, bucket);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              bucket.color,
                              bucket.color.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: bucket.color.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_basket,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              bucket.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _end() {
    final accuracy =
        totalItems == 0 ? 0.0 : correctAssignments / totalItems;

    int stars = accuracy > 0.8
        ? 3
        : accuracy > 0.5
            ? 2
            : 1;

    final encouragement = accuracy > 0.8
        ? 'Excellent! 🎉'
        : accuracy > 0.5
            ? 'Good Work! 👏'
            : 'Nice Try! 💪';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.yellow.shade200,
              Colors.lime.shade200,
              Colors.green.shade200,
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
                        color: Colors.green.withOpacity(0.3),
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
                          color: Colors.green.shade700,
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
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              '$correctAssignments / $totalItems',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
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
                        color: Colors.green.shade700,
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

  String _emoji(String e) {
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

  @override
  void dispose() {
    _emotionAnim.dispose();
    _cameraController?.dispose();
    _emotionTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }
}

// ---------------- MODELS ----------------
class _ColourOption {
  final String name;
  final Color color;
  const _ColourOption(this.name, this.color);
}

class _Item {
  final int id;
  final _ColourOption colour;
  _ColourOption? assignedBucket;

  _Item({required this.id, required this.colour});
}
