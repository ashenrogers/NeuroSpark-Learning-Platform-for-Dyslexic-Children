import 'package:flutter/material.dart';
import '../widgets/heart_rate_overlay.dart';
import '../services/bpm_manager.dart';
import 'digit_memory_matrix_screen.dart';

class DigitMemoryMatrixIntroScreen extends StatefulWidget {
  const DigitMemoryMatrixIntroScreen({super.key});

  @override
  State<DigitMemoryMatrixIntroScreen> createState() =>
      _DigitMemoryMatrixIntroScreenState();
}

class _DigitMemoryMatrixIntroScreenState
    extends State<DigitMemoryMatrixIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // ✅ INITIALIZED SAFELY (no late crash)
  Animation<double> _fadeAnim = const AlwaysStoppedAnimation(1.0);
  Animation<Offset> _slideAnim =
      const AlwaysStoppedAnimation(Offset.zero);

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!BpmManager.instance.hasValidHrData) {
        _showHrWarning();
      }
    });
  }

  void _showHrWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Heart Rate Monitor Not Connected"),
        content: const Text(
          "You can still play this game without a heart rate sensor.\n\n"
          "Heart rate and stress insights will not be recorded.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continue"),
          ),
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "How to Play",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildCard(
                        icon: Icons.grid_on,
                        title: "Memory Challenge",
                        content:
                            "Memorize the grid of digits shown on the screen.\n\n"
                            "After a short time, the grid disappears and you must "
                            "draw the digit from a specific position.",
                      ),

                      const SizedBox(height: 16),

                      _buildCard(
                        icon: Icons.favorite,
                        title: "Heart Rate Tracking",
                        content:
                            "If a heart rate sensor is connected, your heart rate "
                            "will be monitored during gameplay.\n\n"
                            "This helps analyze focus, stress, and cognitive load "
                            "while solving memory challenges.",
                      ),

                      const Spacer(),

                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DigitMemoryMatrixScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Start Game",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ❤️ HEART RATE OVERLAY — SAFE & NON-INTRUSIVE
          const Positioned(
            top: 5,
            right: 5,
            child: SafeArea(
              child: HeartRateOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
}
