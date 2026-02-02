import 'package:flutter/material.dart';
import '../services/bpm_manager.dart';
import '../services/heart_rate_service.dart';

class HeartRateOverlay extends StatelessWidget {
  const HeartRateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final bpmManager = BpmManager.instance;
    final hrService = HeartRateService.instance;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 8,
      child: StreamBuilder<int>(
        stream: hrService.bpmStream,
        builder: (context, snapshot) {
          final bool connected = hrService.isConnected;
          final int bpm = bpmManager.currentBpm;
          final String stress = bpmManager.getStressLevel();

          return Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: connected
                      ? Colors.black12
                      : Colors.redAccent.withOpacity(0.6),
                ),
              ),
              child: connected
                  ? _ConnectedView(bpm: bpm, stress: stress)
                  : const _DisconnectedView(),
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- CONNECTED VIEW ---------------- */

class _ConnectedView extends StatelessWidget {
  final int bpm;
  final String stress;

  const _ConnectedView({
    required this.bpm,
    required this.stress,
  });

  Color _stressColor(String stress) {
    switch (stress) {
      case "High":
        return Colors.redAccent;
      case "Mild":
        return Colors.orangeAccent;
      case "Relaxed":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stressColor = _stressColor(stress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- HEADER ----
        Row(
          children: const [
            Icon(Icons.favorite, size: 16, color: Colors.redAccent),
            SizedBox(width: 6),
            Text(
              "Heart Rate Monitor",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ---- BPM + STRESS (SAME LINE) ----
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // BPM
            Text(
              bpm > 0 ? bpm.toString() : "--",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              "bpm",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(width: 16),

            // Stress indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: stressColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              stress,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: stressColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


/* ---------------- DISCONNECTED VIEW ---------------- */

class _DisconnectedView extends StatelessWidget {
  const _DisconnectedView();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Row(
          children: [
            Icon(Icons.heart_broken,
                size: 16, color: Colors.redAccent),
            SizedBox(width: 6),
            Text(
              "Heart Rate Monitor",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "Not connected",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        SizedBox(height:3),
        Text(
          "Physiological data will not be recorded",
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
