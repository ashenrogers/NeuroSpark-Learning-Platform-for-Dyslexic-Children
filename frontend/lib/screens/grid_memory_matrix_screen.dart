// lib/screens/grid_memory_matrix_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/api_service.dart';
import '../services/bpm_manager.dart';

/// EMNIST Balanced label mapping (47 classes) – must match backend
const List<String> emnistBalancedLabels = [
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  'a', 'b', 'd', 'e', 'f', 'g', 'h', 'n', 'q', 'r', 't',
];

class GridLevelConfig {
  final int gridSize;
  final double showTimeSeconds;
  final int questionsPerRound;
  const GridLevelConfig(this.gridSize, this.showTimeSeconds, this.questionsPerRound);
}

/// 10-level difficulty plan
const List<GridLevelConfig> kGridLevels = [
  GridLevelConfig(2, 3.0, 1), // Level 1 (2x2)
  GridLevelConfig(2, 2.0, 1), // Level 2 (2x2, faster)
  GridLevelConfig(2, 1.5, 2), // Level 3 (2x2, 2 questions)
  GridLevelConfig(3, 3.0, 1), // Level 4 (3x3)
  GridLevelConfig(3, 2.0, 2), // Level 5 (3x3, faster & 2 q's)
  GridLevelConfig(3, 1.5, 2), // Level 6
  GridLevelConfig(4, 3.0, 2), // Level 7 (4x4)
  GridLevelConfig(4, 2.0, 3), // Level 8
  GridLevelConfig(5, 3.0, 3), // Level 9 (5x5)
  GridLevelConfig(5, 2.0, 4), // Level 10 (max)
];

class GridMemoryMatrixScreen extends StatefulWidget {
  const GridMemoryMatrixScreen({Key? key}) : super(key: key);

  @override
  State<GridMemoryMatrixScreen> createState() => _GridMemoryMatrixScreenState();
}

class _GridMemoryMatrixScreenState extends State<GridMemoryMatrixScreen> {

    /// Some EMNIST symbols are visually very similar.
  /// We treat pairs in the same group as "close enough".
  bool _isEquivalentSymbol(String expected, String predicted) {
    // Exact match is always fine
    if (expected == predicted) return true;

    const List<List<String>> groups = [
      ['O', '0'],   // letter O vs digit 0
      ['b', 'P'],   // your b sometimes looks like P to the model
      ['g', 'q'],   // tail letters can be confusing
      // Add more if you notice other common confusions
    ];

    for (final group in groups) {
      if (group.contains(expected) && group.contains(predicted)) {
        return true;
      }
    }
    return false;
  }

  final Random _rand = Random();

  int _currentLevel = 1; // 1..10
  bool _showingGrid = false;
  bool _roundInProgress = false;

  late GridLevelConfig _levelConfig;

  /// Flattened list of EMNIST class indices for each cell in the grid
  List<int> _gridSymbols = [];

  /// List of indices (cell positions) that will be asked in this round
  List<int> _questionCells = [];

  int _currentQuestionIndex = 0;

  /// Simple performance tracking over recent rounds
  final List<double> _recentAccuracies = [];

  int _correctInThisRound = 0;
  int _totalQuestionsThisRound = 0;

  @override
  void initState() {
    super.initState();
    _levelConfig = kGridLevels[_currentLevel - 1];

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


  void _startNewRound() {
    _levelConfig = kGridLevels[_currentLevel - 1];
    _gridSymbols = _generateGridSymbols(_levelConfig.gridSize);
    _questionCells = _pickQuestionCells(
      _levelConfig.gridSize,
      _levelConfig.questionsPerRound,
    );
    _currentQuestionIndex = 0;
    _correctInThisRound = 0;
    _totalQuestionsThisRound = _questionCells.length;

    setState(() {
      _showingGrid = true;
      _roundInProgress = true;
    });

    Future.delayed(
      Duration(milliseconds: (_levelConfig.showTimeSeconds * 1000).round()),
      () {
        if (!mounted) return;
        setState(() {
          _showingGrid = false;
        });
      },
    );
  }

  List<int> _generateGridSymbols(int gridSize) {
    final int cellCount = gridSize * gridSize;
    return List<int>.generate(
      cellCount,
      (_) => _rand.nextInt(emnistBalancedLabels.length),
    );
  }

  List<int> _pickQuestionCells(int gridSize, int questions) {
    final int cellCount = gridSize * gridSize;
    final cells = List<int>.generate(cellCount, (i) => i);
    cells.shuffle(_rand);
    return cells.take(questions).toList();
  }

  String _cellLabelForIndex(int index) {
    final classIdx = _gridSymbols[index];
    return emnistBalancedLabels[classIdx];
  }

  String _questionText() {
    if (_questionCells.isEmpty) return "";
    final idx = _questionCells[_currentQuestionIndex];
    final gridSize = _levelConfig.gridSize;
    final row = idx ~/ gridSize;
    final col = idx % gridSize;

    String rowName;
    if (row == 0) {
      rowName = "top";
    } else if (row == gridSize - 1) {
      rowName = "bottom";
    } else if (row == gridSize ~/ 2) {
      rowName = "middle";
    } else {
      rowName = "row ${row + 1}";
    }

    String colName;
    if (col == 0) {
      colName = "left";
    } else if (col == gridSize - 1) {
      colName = "right";
    } else if (col == gridSize ~/ 2) {
      colName = "middle";
    } else {
      colName = "column ${col + 1}";
    }

    return "What was in the $rowName-$colName cell?";
  }

  Future<void> _handleAnswerResult(bool correct) async {
    if (correct) _correctInThisRound++;

    if (_currentQuestionIndex < _questionCells.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Round finished
      final accuracy = _correctInThisRound / _totalQuestionsThisRound;
      _recentAccuracies.add(accuracy);
      if (_recentAccuracies.length > 5) {
        _recentAccuracies.removeAt(0);
      }

      final avg = _recentAccuracies.isEmpty
          ? 0.0
          : _recentAccuracies.reduce((a, b) => a + b) / _recentAccuracies.length;

      int newLevel = _currentLevel;
      if (avg >= 0.8 && _currentLevel < kGridLevels.length) {
        newLevel++;
      } else if (avg <= 0.4 && _currentLevel > 1) {
        newLevel--;
      }

      setState(() {
        _currentLevel = newLevel;
        _roundInProgress = false;
      });

      // Save score to backend
      try {
        await ApiService.saveScore(
          game: "grid_memory_matrix",
          score: _correctInThisRound,
          totalTime: 0.0,
          levelDurations: const [],
          levelReached: _currentLevel,
        );
      } catch (e) {
        debugPrint("Error saving grid_memory_matrix score: $e");
      }

      final message = "Round complete!\n"
          "Accuracy: ${(_correctInThisRound / _totalQuestionsThisRound * 100).toStringAsFixed(0)}%\n"
          "Average (last ${_recentAccuracies.length} rounds): ${(avg * 100).toStringAsFixed(0)}%\n"
          "Next level: $_currentLevel";

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Good job!"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _startHandwritingForCurrentQuestion() async {
    if (_showingGrid || !_roundInProgress) return;

    final int cellIndex = _questionCells[_currentQuestionIndex];
    final int expectedClassIndex = _gridSymbols[cellIndex];
    final String expectedChar = emnistBalancedLabels[expectedClassIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                     "Draw the symbol.",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "Hint: It was '$expectedChar'",
                      style: const TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w700, 
                        color: Colors.blueAccent,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Draw clearly below!",
                    style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: HandwritingPad(
                      onSubmit: (pngBytes) async {
                      Navigator.of(sheetCtx).pop(); // close bottom sheet

                      final base64Image =
                          "data:image/png;base64,${base64Encode(pngBytes)}";

                      final res = await ApiService.predictHandwriting(base64Image);

                      if (res == null) {
                        // Some generic network / server error
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Prediction failed. Please try again.")),
                        );
                        await _handleAnswerResult(false);
                        return;
                      }

                      // Handle special "blank_image" error from backend
                      if (res["error"] == "blank_image") {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("I can't see your drawing. Try drawing more clearly."),
                          ),
                        );
                        await _handleAnswerResult(false);
                        return;
                      }

                      // Normal successful prediction
                      final int predictedIndex = res["class_index"] as int;
                      final double confidence =
                          (res["confidence"] as num).toDouble();
                      final String predictedChar =
                          (res["predicted_char"] ?? "?").toString();

                        // If the model is very unsure, treat this as unreadable.
                        const double minConfidence = 0.5;
                        if (confidence < minConfidence) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "I'm not sure what that is. Try drawing a bit clearer next time.",
                              ),
                            ),
                          );
                          await _handleAnswerResult(false);
                          return;
                        }

                      final bool correct =
                      predictedIndex == expectedClassIndex ||
                      _isEquivalentSymbol(expectedChar, predictedChar);


                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            correct
                                ? "Correct! Predicted: $predictedChar (conf: ${(confidence * 100).toStringAsFixed(1)}%)"
                                : "Didn’t match.\nExpected: $expectedChar, Got: $predictedChar (conf: ${(confidence * 100).toStringAsFixed(1)}%)",
                          ),
                        ),
                      );

                      await _handleAnswerResult(correct);

                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gridSize = _levelConfig.gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Soft background
      appBar: AppBar(
        title: const Text(
          "Grid Memory",
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Level + status (Enlarged)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Level $_currentLevel",
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      _roundInProgress
                          ? (_showingGrid
                              ? "Memorize! 👀"
                              : "Answer! ✍️")
                          : "Ready",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _roundInProgress ? Colors.deepPurpleAccent : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

            // Grid display area
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showingGrid
                        ? _buildGrid(gridSize)
                        : _roundInProgress
                            ? _buildQuestionArea()
                            : _buildIdlePlaceholder(),
                  ),
                ),
              ),
            ),

              const SizedBox(height: 24),

              // Start / Answer button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_roundInProgress) {
                      _startNewRound();
                    } else if (!_showingGrid) {
                      _startHandwritingForCurrentQuestion();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // Friendly Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    !_roundInProgress
                        ? "Start Game"
                        : _showingGrid
                            ? "Memorizing..."
                            : "Draw Answer",
                    style: const TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(int gridSize) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridSize * gridSize,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _cellLabelForIndex(index),
                style: const TextStyle(
                  fontSize: 36, // Much larger font
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3142),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          _questionText(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3142),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildIdlePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0D5FF)),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grid_view_rounded, size: 60, color: Color(0xFF9FA8DA)),
            SizedBox(height: 20),
            Text(
              "1. Look at the grid\n2. Remember the symbols\n3. Draw the answer!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple handwriting canvas that returns a PNG image as bytes
class HandwritingPad extends StatefulWidget {
  final Future<void> Function(Uint8List pngBytes) onSubmit;

  const HandwritingPad({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<HandwritingPad> createState() => _HandwritingPadState();
}

class _HandwritingPadState extends State<HandwritingPad> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<Offset?> _points = [];

  // Logical on-screen canvas size (what the user sees)
  static const double _canvasSize = 200.0;

  void _clear() {
    setState(() => _points.clear());
  }

  Future<void> _submit() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // We want the exported image to be ~28x28 pixels (EMNIST style).
      const double targetSize = 28.0;
      const double logicalSize = _canvasSize; // width/height of the SizedBox
      final double pixelRatio = targetSize / logicalSize;

      // Capture at a pixel ratio that yields ~28x28 output
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      await widget.onSubmit(pngBytes);
    } catch (e) {
      debugPrint("Error capturing handwriting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: _canvasSize,
              height: _canvasSize,
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.black, // visible black background
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() => _points.add(null));
                      },
                      child: CustomPaint(
                        painter: _HandwritingPainter(_points),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.refresh),
              label: const Text("Clear"),
            ),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check, size: 28),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              label: const Text("Submit", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  final List<Offset?> points;
  _HandwritingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Black background (matches backend expectation)
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Thinner stroke to be EMNIST-like after downscaling to 28x28
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3  // was 18 before
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, strokePaint);
      }
    }
  }

    @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) {
    // Always repaint when the points list is updated
    return true;
  }

}

