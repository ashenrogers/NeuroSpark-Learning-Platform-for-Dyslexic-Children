// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> userScores = [];
  bool loading = true;
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadUserScores();
  }

  Future<void> _loadUserScores() async {
    setState(() => loading = true);
    final user = await AuthService.getUsername();
    final data = await ApiService.getScores();

    // keep only this user's records (server already restricts, but double-check)
    final filtered = data.where((s) => s['player_name'] == user).toList();

    // group by game and keep highest score
    final Map<String, dynamic> bestByGame = {};
    for (var s in filtered) {
      final game = s['game'] ?? 'Unknown';
      final sc = (s['score'] ?? 0) as num;
      if (!bestByGame.containsKey(game) || sc > (bestByGame[game]['score'] ?? 0)) {
        bestByGame[game] = s;
      }
    }

    setState(() {
      username = user ?? 'Player';
      userScores = bestByGame.values.toList();
      loading = false;
    });
  }

  String _motivation(int score) {
    if (score >= 30) return "🌟 Memory Master";
    if (score >= 20) return "🔥 Excellent Progress";
    if (score >= 10) return "💪 Great Work";
    if (score >= 5) return "🚀 Keep Training";
    return "✨ Start Your Journey";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text("$username's Performance"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUserScores,
                child: userScores.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            "No game history yet.\nPlay and train your memory!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: userScores.length,
                        itemBuilder: (context, idx) {
                          final s = userScores[idx];
                          final game = s['game'] ?? 'Unknown';
                          final score = s['score'] ?? 0;
                          final totalTime = s['total_time'];
                          final levelReached = s['level_reached'];
                          final levelDurations = s['level_durations'] as List<dynamic>?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(game, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text("⭐ $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.orange)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (levelReached != null)
                                    Text("Best level: $levelReached", style: const TextStyle(color: Colors.black54)),
                                  if (totalTime != null)
                                    Text("Total time: ${totalTime.toString()}s", style: const TextStyle(color: Colors.black54)),
                                  if (levelDurations != null && levelDurations.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text("Per-level durations:", style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    for (int i = 0; i < levelDurations.length; i++)
                                      Text("Level ${i + 1}: ${levelDurations[i].toStringAsFixed(2)} s", style: const TextStyle(color: Colors.black54)),
                                  ],
                                  const SizedBox(height: 10),
                                  Text(_motivation(score as int), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
