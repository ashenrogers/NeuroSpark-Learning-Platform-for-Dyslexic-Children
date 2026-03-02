import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Soft, low-glare background
      appBar: AppBar(
        title: const Text(
          "Memory Matrix",
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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "How to Play",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3142),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Very simple, clear visual steps
                      _buildStepCard(
                        icon: Icons.grid_view_rounded,
                        iconColor: Colors.blueAccent,
                        text: "1. Look at the numbers.",
                      ),
                      _buildStepCard(
                        icon: Icons.visibility_off_rounded,
                        iconColor: Colors.purpleAccent,
                        text: "2. Remember where they are.",
                      ),
                      _buildStepCard(
                        icon: Icons.draw_rounded,
                        iconColor: Colors.orangeAccent,
                        text: "3. Draw the missing number!",
                      ),

                      const SizedBox(height: 10),

                      const Spacer(),

                      // Large, clear, contrasting play button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50), // Friendly Green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DigitMemoryMatrixScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Start Game",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: iconColor.withOpacity(0.3), 
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: iconColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0.5,
                color: Color(0xFF2D3142),
              ),
            ),
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
