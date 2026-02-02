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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text("Adaptive Memory Trainer"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: "Profile",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 3 / 3.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            GameCard(
              title: "🪐 Cosmic Sequence",
              icon: Icons.auto_awesome,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CosmicSequenceScreen())),
            ),
            GameCard(
              title: "🏆 My Performance",
              icon: Icons.emoji_events,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            ),
            // placeholders for future games
            GameCard(
              title: "🧩 Grid Memory Matrix",
              icon: Icons.grid_on,
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
              title: "🔄  Morph Memory Game",
              icon: Icons.transform,
              color:  const Color.fromARGB(255, 78, 168, 242),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MorphSequenceScreen()),
              );
            }, 
            ),
            GameCard(
              title: "🔄  Digit Recall Game",
              icon: Icons.transform,
              color:  const Color.fromARGB(255, 78, 168, 242),
              onTap: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DigitMemoryMatrixIntroScreen()),
              );
            }, 
            ),
            GameCard(
              title: "❤️ Heart Rate Monitor",
              icon: Icons.monitor_heart,
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
    );
  }
}
