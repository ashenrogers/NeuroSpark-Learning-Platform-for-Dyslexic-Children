// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  List<dynamic> scores = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.getUser();
    final s = await ApiService.getUserScores();
    setState(() {
      user = u;
      scores = s;
      loading = false;
    });
  }

  void _logout() async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      backgroundColor: const Color(0xFFF7F7F7),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(child: Text((user?['display_name'] ?? 'U')[0]), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              title: Text(user?['display_name'] ?? user?['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Username: ${user?['username'] ?? ''}"),
              trailing: IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text("Recent sessions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Expanded(
              child: scores.isEmpty
                  ? const Center(child: Text("No sessions yet", style: TextStyle(color: Colors.black54)))
                  : ListView.separated(
                      itemCount: scores.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final s = scores[idx];
                        final game = s['game'] ?? '';
                        final score = s['score'] ?? 0;
                        final ts = s['timestamp'] ?? '';
                        final playedOn = ts != null ? DateTime.tryParse(ts) : null;
                        final totalTime = s['total_time'];
                        return ListTile(
                          title: Text("$game — ⭐ $score"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (playedOn != null) Text("Played: ${playedOn.day}/${playedOn.month}/${playedOn.year}"),
                              if (totalTime != null) Text("Total time: ${totalTime.toString()}s"),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
