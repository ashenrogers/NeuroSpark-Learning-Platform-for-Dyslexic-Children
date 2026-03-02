// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'cosmic_sequence_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../widgets/game_card.dart';
import 'grid_memory_matrix_screen.dart';
import 'heart_rate_screen.dart';
import 'morph_sequence_screen.dart';
import 'digit_memory_matrix_intro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7), // Soft background
      appBar: AppBar(
        title: const Text(
          "Memory Trainer",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: "Profile",
            color: const Color(0xFF2D3142),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _logout(context),
            tooltip: "Logout",
            color: Colors.redAccent,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Activities",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3142),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // Lowering ratio gives cards more vertical height
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    GameCard(
                      title: "Cosmic Sequence",
                      icon: Icons.auto_awesome,
                      color: Colors.deepPurpleAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CosmicSequenceScreen())),
                    ),
                    GameCard(
                      title: "Grid\nMemory",
                      icon: Icons.grid_view_rounded,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GridMemoryMatrixScreen(),
                          ),
                        );
                      },
                    ),
                    GameCard(
                      title: "Morph\nMemory",
                      icon: Icons.change_circle_rounded,
                      color: const Color(0xFF4EA8F2),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MorphSequenceScreen()),
                        );
                      }, 
                    ),
                    GameCard(
                      title: "Digit\nRecall",
                      icon: Icons.numbers_rounded,
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DigitMemoryMatrixIntroScreen()),
                        );
                      }, 
                    ),
                    GameCard(
                      title: "My\nPerformance",
                      icon: Icons.emoji_events_rounded,
                      color: Colors.teal,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                    ),
                    GameCard(
                      title: "Heart Rate Monitor",
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HeartRateScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
