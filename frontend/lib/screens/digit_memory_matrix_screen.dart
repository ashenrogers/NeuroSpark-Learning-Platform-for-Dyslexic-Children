import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'digit_matrix_controller.dart';
import '../services/api_service.dart';
import '../widgets/heart_rate_overlay.dart';

class DigitMemoryMatrixScreen extends StatefulWidget {
  const DigitMemoryMatrixScreen({super.key});

  @override
  State<DigitMemoryMatrixScreen> createState() =>
      _DigitMemoryMatrixScreenState();
}

class _DigitMemoryMatrixScreenState
    extends State<DigitMemoryMatrixScreen>
    with SingleTickerProviderStateMixin {
  final DigitMatrixController controller = DigitMatrixController();

  final GlobalKey _paintKey = GlobalKey();
  final List<Offset?> _points = [];

  bool showMatrix = true;
  bool isSubmitting = false;

  bool highlightTarget = false;
  int countdown = 0;

  Timer? timer;

  DateTime levelStartTime = DateTime.now();
  final List<double> levelDurations = [];

  late AnimationController feedbackController;
  late Animation<double> scaleAnim;
  late Animation<Offset> shakeAnim;
  Color feedbackBorderColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    controller.startGame();

    feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: feedbackController, curve: Curves.easeOut),
    );

    shakeAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(
      CurvedAnimation(parent: feedbackController, curve: Curves.elasticIn),
    );

    _startMemorizeTimer();
  }

  void _startMemorizeTimer() {
    showMatrix = true;
    _clearCanvas();
    timer?.cancel();

    levelStartTime = DateTime.now();
    countdown = controller.memorizeSeconds;
    highlightTarget = false;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdown == 1) {
        setState(() => highlightTarget = true);
      }

      if (countdown == 0) {
        t.cancel();
        setState(() {
          showMatrix = false;
          highlightTarget = false;
        });
      } else {
        setState(() => countdown--);
      }
    });
  }

  void _clearCanvas() {
    setState(() => _points.clear());
  }

  Future<Uint8List?> _exportImage() async {
    final boundary =
        _paintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return data?.buffer.asUint8List();
  }

  Future<void> _submit() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    final png = await _exportImage();
    if (png == null) {
      setState(() => isSubmitting = false);
      return;
    }

    final result = await ApiService().validateDigit(
      base64Image: base64Encode(png),
      expectedDigit: controller.expectedDigit,
    );

    if (result["decision"] == "accept") {
      feedbackBorderColor = Colors.green;
      feedbackController.forward(from: 0);

      final duration =
          DateTime.now().difference(levelStartTime).inMilliseconds / 1000.0;

      levelDurations.add(duration);
      controller.score += 10;

      controller.advanceLevel();
      _startMemorizeTimer();
    } else {
      feedbackBorderColor = Colors.red;
      feedbackController.forward(from: 0);

      controller.attemptsLeft--;
      _clearCanvas();

      if (controller.attemptsLeft <= 0) {
        final totalTime =
            levelDurations.fold<double>(0, (a, b) => a + b);

        await ApiService.saveScore(
          game: "digit_memory_matrix",
          score: controller.score,
          totalTime: totalTime,
          levelDurations: levelDurations,
          levelReached: controller.level,
        );

        _showGameOver();
      }
    }

    setState(() => isSubmitting = false);
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: Text(
          "Score: ${controller.score}\n"
          "Level Reached: ${controller.level}",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.startGame();
              levelDurations.clear();
              _startMemorizeTimer();
              setState(() {});
            },
            child: const Text("Restart"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Digit Memory Matrix")),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: (controller.level % 5) / 5,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Level ${controller.level} | Score ${controller.score}",
                  style: const TextStyle(fontSize: 18),
                ),
              ),

              if (!showMatrix)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Draw the digit at ${controller.targetLabel}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      showMatrix ? _buildMatrix() : _buildCanvas(),
                      if (showMatrix)
                        Positioned(
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              countdown > 0 ? countdown.toString() : "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (!showMatrix) _buildControls(),
              const SizedBox(height: 12),
            ],
          ),

          // ❤️ HEART RATE OVERLAY — TOP RIGHT, PERFECT ALIGNMENT
          const Positioned(
            top: 75,
            right: 8,
            child: SafeArea(
              child: HeartRateOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrix() {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: controller.gridSize * controller.gridSize,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: controller.gridSize,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, i) {
        final r = i ~/ controller.gridSize;
        final c = i % controller.gridSize;

        final isTarget =
            highlightTarget &&
            r == controller.targetRow &&
            c == controller.targetCol;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isTarget
                ? Colors.yellowAccent
                : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isTarget
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              controller.matrix[r][c].toString(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanvas() {
    return ScaleTransition(
      scale: scaleAnim,
      child: SlideTransition(
        position: shakeAnim,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: feedbackBorderColor, width: 4),
          ),
          child: GestureDetector(
            onPanUpdate: (d) {
              final box =
                  _paintKey.currentContext!.findRenderObject()
                      as RenderBox;
              setState(() {
                _points.add(
                    box.globalToLocal(d.globalPosition));
              });
            },
            onPanEnd: (_) => _points.add(null),
            child: RepaintBoundary(
              key: _paintKey,
              child: CustomPaint(painter: _Painter(_points)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _clearCanvas,
          child: const Text("Clear"),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submit,
          child: const Text("Submit"),
        ),
      ],
    );
  }
}

class _Painter extends CustomPainter {
  final List<Offset?> points;
  _Painter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
