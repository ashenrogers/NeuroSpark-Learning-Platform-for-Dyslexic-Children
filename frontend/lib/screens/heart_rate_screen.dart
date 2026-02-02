// lib/screens/heart_rate_screen.dart
import 'package:flutter/material.dart';
import '../services/heart_rate_service.dart';
import '../services/bpm_manager.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      await HeartRateService.instance.startBackgroundStreaming();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bpmManager = BpmManager.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Heart Rate & Stress Monitor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _connecting
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Connecting to ESP32..."),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          "Could not connect to ESP32",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _start,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StreamBuilder<int>(
                        stream: HeartRateService.instance.bpmStream,
                        builder: (context, snapshot) {
                          final bpm = bpmManager.currentBpm;
                          final stress = bpmManager.getStressLevel();

                          final displayBpm =
                              bpm > 0 ? bpm.toString() : "--";

                          String hint;
                          if (bpm <= 0) {
                            hint = "Place your finger on the sensor";
                          } else if (stress == "Calibrating") {
                            hint = "Calibrating baseline… keep still";
                          } else {
                            hint = "Baseline: "
                                "${bpmManager.baselineBpm?.toStringAsFixed(1) ?? '--'} bpm";
                          }

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Current Heart Rate",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        displayBpm,
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "bpm",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hint,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Stress Level",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStressRow(bpmManager.getStressLevel()),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Note: The app computes a calm baseline over the first ~60 seconds, "
                        "then marks mild or high stress if your BPM rises significantly above that baseline.",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStressRow(String level) {
    Color color;
    String text;

    switch (level) {
      case "High":
        color = Colors.redAccent;
        text = "High stress – try to relax";
        break;
      case "Mild":
        color = Colors.orangeAccent;
        text = "Mild stress – slightly elevated";
        break;
      case "Relaxed":
        color = Colors.green;
        text = "Relaxed – within normal range";
        break;
      default:
        color = Colors.blueGrey;
        text = "Calibrating baseline…";
    }

    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: color),
        ),
      ],
    );
  }
}
