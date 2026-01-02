import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'fluency_game_screen.dart';
import 'pronunciation_game_screen.dart';
import 'vocabulary_game_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  bool _isConnected = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final connected = await _apiService.checkConnection();
    setState(() {
      _isConnected = connected;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyslexia Support App'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade300,
              Colors.blue.shade300,
              Colors.indigo.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: _isChecking
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                )
              : AnimationLimiter(
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Animated Welcome Header
                      AnimationConfiguration.staggeredList(
                        position: 0,
                        duration: const Duration(milliseconds: 800),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.psychology,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 15),
                                        AnimatedTextKit(
                                          animatedTexts: [
                                            TypewriterAnimatedText(
                                              'Welcome to Dyslexia Support',
                                              textStyle: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              speed: const Duration(milliseconds: 100),
                                            ),
                                          ],
                                          totalRepeatCount: 1,
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Personalized Learning Experience',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Connection Status
                      if (!_isConnected)
                        AnimationConfiguration.staggeredList(
                          position: 1,
                          duration: const Duration(milliseconds: 800),
                          child: SlideAnimation(
                            verticalOffset: 30.0,
                            child: FadeInAnimation(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.orange.shade700),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning, color: Colors.white, size: 24),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Server connection lost. Please check your connection.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.refresh, color: Colors.white),
                                        onPressed: _checkConnection,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Game Cards
                      Expanded(
                        child: AnimationConfiguration.staggeredList(
                          position: 2,
                          duration: const Duration(milliseconds: 1000),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: ListView(
                                padding: const EdgeInsets.all(20),
                                children: [
                                  _buildEnhancedGameCard(
                                    context,
                                    title: 'Reading Fluency',
                                    description:
                                        'Practice reading sentences aloud with AI-powered feedback',
                                    icon: Icons.menu_book,
                                    color: Colors.blue,
                                    onTap: () => Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const FluencyGameScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: animation.drive(
                                              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEnhancedGameCard(
                                    context,
                                    title: 'Pronunciation Practice',
                                    description:
                                        'Master word pronunciation with intelligent speech analysis',
                                    icon: Icons.record_voice_over,
                                    color: Colors.green,
                                    onTap: () => Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const PronunciationGameScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: animation.drive(
                                              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEnhancedGameCard(
                                    context,
                                    title: 'Vocabulary Builder',
                                    description:
                                        'Expand your vocabulary with adaptive AI-generated questions',
                                    icon: Icons.psychology,
                                    color: Colors.orange,
                                    onTap: () => Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const VocabularyGameScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: animation.drive(
                                              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                                            ),
                                            child: child,
                                          );
                                        },
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
                ),
        ),
      ),
    );
  }

  Widget _buildEnhancedGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.6),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isConnected ? onTap : null,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 25),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
