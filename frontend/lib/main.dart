// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const AdaptiveMemoryTrainerApp());
}

class AdaptiveMemoryTrainerApp extends StatelessWidget {
  const AdaptiveMemoryTrainerApp({super.key});

  Future<bool> _isLoggedIn() async {
    return await AuthService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Memory Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black87),
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return snapshot.data == true ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
