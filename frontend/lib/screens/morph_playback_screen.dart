import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/heart_rate_overlay.dart';

class MorphPlaybackScreen extends StatefulWidget {
  final List<List<String>> pairs;
  final int framesPerMorph; // 31 => 000..030
  final int frameDurationMs;
  final int pauseBetweenMorphsMs;

  const MorphPlaybackScreen({
    super.key,
    required this.pairs,
    required this.framesPerMorph,
    required this.frameDurationMs,
    required this.pauseBetweenMorphsMs,
  });

  @override
  State<MorphPlaybackScreen> createState() => _MorphPlaybackScreenState();
}

class _MorphPlaybackScreenState extends State<MorphPlaybackScreen> {
  int pairIndex = 0;
  int frameIndex = 0;
  Timer? timer;
  bool isPausing = false;

  late final List<String> seenSequence;

  @override
  void initState() {
    super.initState();
    seenSequence = _buildSeenSequence(widget.pairs);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _precacheCurrentMorph();
      _startTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  List<String> _buildSeenSequence(List<List<String>> pairs) {
    if (pairs.isEmpty) return [];
    final out = <String>[pairs.first[0]];
    for (final p in pairs) out.add(p[1]);
    return out;
  }

  String _pairName(List<String> p) => "${p[0]}_to_${p[1]}";

  String _framePath(int pIdx, int fIdx) {
    final p = widget.pairs[pIdx];
    final name = _pairName(p);
    final frame = fIdx.toString().padLeft(3, '0');
    return "assets/morph_frames/$name/${name}_frame_$frame.png";
  }

  Future<void> _precacheCurrentMorph() async {
    final ctx = context;
    final paths = <String>[];

    for (int i = 0; i < widget.framesPerMorph; i++) {
      paths.add(_framePath(pairIndex, i));
    }
    if (pairIndex + 1 < widget.pairs.length) {
      paths.add(_framePath(pairIndex + 1, 0));
    }

    for (final p in paths) {
      await precacheImage(AssetImage(p), ctx);
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      Duration(milliseconds: widget.frameDurationMs),
      (_) => _tick(),
    );
  }

  Future<void> _tick() async {
    if (!mounted || isPausing) return;

    setState(() => frameIndex++);

    if (frameIndex >= widget.framesPerMorph) {
      isPausing = true;
      frameIndex = widget.framesPerMorph - 1;

      await Future.delayed(
        Duration(milliseconds: widget.pauseBetweenMorphsMs),
      );
      if (!mounted) return;

      setState(() {
        pairIndex++;
        frameIndex = 0;
        isPausing = false;
      });

      if (pairIndex >= widget.pairs.length) {
        timer?.cancel();
        Navigator.pop(context, seenSequence);
        return;
      }

      await _precacheCurrentMorph();
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePair = pairIndex.clamp(0, widget.pairs.length - 1);
    final safeFrame = frameIndex.clamp(0, widget.framesPerMorph - 1);

    final framePath = _framePath(safePair, safeFrame);

    final progress =
        (safePair + (safeFrame / widget.framesPerMorph)) /
            widget.pairs.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ===== MORPH ANIMATION (CENTER) =====
          Positioned.fill(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Image.asset(framePath),
              ),
            ),
          ),

          // ===== TOP BAR (CLOSE BUTTON ONLY) =====
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 10,
            child: IconButton(
              onPressed: () {
                timer?.cancel();
                Navigator.pop(context, null);
              },
              icon: const Icon(Icons.close),
            ),
          ),

          // ===== HEART RATE OVERLAY (TOP-RIGHT, UNCHANGED) =====
          const HeartRateOverlay(),

          // ===== PLAYBACK PROGRESS (BOTTOM) =====
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  "${safePair + 1} / ${widget.pairs.length}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
