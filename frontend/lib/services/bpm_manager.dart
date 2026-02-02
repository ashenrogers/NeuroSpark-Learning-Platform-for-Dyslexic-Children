// lib/services/bpm_manager.dart
import 'dart:async';

class BpmSample {
  final DateTime time;
  final int bpm;

  BpmSample(this.time, this.bpm);
}

class BpmManager {
  // 🔹 Global singleton
  static final BpmManager instance = BpmManager._internal();
  BpmManager._internal();

  final List<BpmSample> history = [];
  BpmSample? lastSample;

  DateTime? _lastSecond;
  int? _latestBpmInCurrentSecond;

  double? baselineBpm;
  bool baselineLocked = false; // you can set true after saving to DB

  final int baselineSeconds = 60; // first 60s as baseline
  final Duration historyWindow = const Duration(hours: 1);

  Stream<int>? _currentSourceSubStream;
  StreamSubscription<int>? _bpmSub;

  /// Attach the BPM manager to a BPM stream from HeartRateService.
  /// Safe to call again with same/different stream.
  void attachToStream(Stream<int> source) {
    if (_currentSourceSubStream == source) return;

    _bpmSub?.cancel();
    _currentSourceSubStream = source;
    _bpmSub = source.listen(_onNewBpm);
  }

  void _onNewBpm(int bpm) {
    if (bpm <= 0) return;

    final now = DateTime.now();
    final currentSecond = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );

    if (_lastSecond == null) {
      _lastSecond = currentSecond;
      _latestBpmInCurrentSecond = bpm;
      _saveSample(currentSecond, bpm);
      return;
    }

    if (currentSecond.isAtSameMomentAs(_lastSecond!)) {
      // still within the same second, keep latest BPM
      _latestBpmInCurrentSecond = bpm;
    } else {
      // second changed, store previous second sample
      if (_latestBpmInCurrentSecond != null) {
        _saveSample(currentSecond, _latestBpmInCurrentSecond!);
      }
      _lastSecond = currentSecond;
      _latestBpmInCurrentSecond = bpm;
    }
  }

  void _saveSample(DateTime time, int bpm) {
    final sample = BpmSample(time, bpm);
    history.add(sample);
    lastSample = sample;

    // keep only last 1 hour
    final cutoff = DateTime.now().subtract(historyWindow);
    history.removeWhere((s) => s.time.isBefore(cutoff));

    if (!baselineLocked) {
      _computeBaselineIfNeeded();
    }
  }

  void _computeBaselineIfNeeded() {
    if (baselineBpm != null) return;
    if (history.length < baselineSeconds) return;

    final first = history.take(baselineSeconds).map((s) => s.bpm).toList();
    final sum = first.fold<int>(0, (a, b) => a + b);
    baselineBpm = sum / first.length;
    print("🎯 [HR] Baseline BPM computed: $baselineBpm");
  }

  String getStressLevel() {
    if (baselineBpm == null || lastSample == null) {
      return "Calibrating";
    }

    final current = lastSample!.bpm;
    final diff = current - baselineBpm!;

    if (diff > 15) return "High";
    if (diff > 5) return "Mild";
    return "Relaxed";
  }



  double? get averageBpm {
  if (history.isEmpty) return null;
  final sum = history.fold<int>(0, (a, b) => a + b.bpm);
  return sum / history.length;
  }

  bool get hasValidHrData {
  return baselineBpm != null && lastSample != null;
  }

int get currentBpm => lastSample?.bpm ?? 0;
}
