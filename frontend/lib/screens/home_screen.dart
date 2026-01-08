import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'fluency_game_screen.dart';
import 'pronunciation_game_screen.dart';
import 'vocabulary_game_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isConnected = false;
  bool _isChecking = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    // Initialize pulse animation for connection indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade300,
              Colors.pink.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: _isChecking
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_sync,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Connecting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // App Title with Animation
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_stories,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: AnimatedTextKit(
                                          animatedTexts: [
                                            TypewriterAnimatedText(
                                              'Dyslexia Support',
                                              textStyle: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                              speed: const Duration(milliseconds: 150),
                                            ),
                                          ],
                                          totalRepeatCount: 1,
                                          displayFullTextOnTap: true,
                                          pause: const Duration(milliseconds: 500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Hello! 👋 Ready to learn?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Connection Status Badge
                          ScaleTransition(
                            scale: _isConnected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isConnected ? Colors.green : Colors.red,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _isConnected ? Icons.wifi : Icons.wifi_off,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Connection Warning (if disconnected)
                    if (!_isConnected)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'No connection. Tap to retry.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                              onPressed: _checkConnection,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Game Cards
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: widget),
                          ),
                          children: [
                            _buildModernGameCard(
                              context,
                              title: 'Reading Fluency',
                              emoji: '📖',
                              description: 'Practice reading sentences with AI feedback',
                              gradient: [Colors.blue.shade600, Colors.blue.shade400],
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, animation, __) => const FluencyGameScreen(),
                                  transitionsBuilder: (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModernGameCard(
                              context,
                              title: 'Pronunciation',
                              emoji: '🎤',
                              description: 'Master word sounds with speech analysis',
                              gradient: [Colors.green.shade600, Colors.green.shade400],
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, animation, __) => const PronunciationGameScreen(),
                                  transitionsBuilder: (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModernGameCard(
                              context,
                              title: 'Vocabulary Builder',
                              emoji: '🧠',
                              description: 'Expand your vocabulary with fun questions',
                              gradient: [Colors.orange.shade600, Colors.orange.shade400],
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, animation, __) => const VocabularyGameScreen(),
                                  transitionsBuilder: (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                          CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Footer encouragement
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.yellow, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'You can do it!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.star, color: Colors.yellow, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildModernGameCard(
    BuildContext context, {
    required String title,
    required String emoji,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isConnected ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Emoji Circle
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Play Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
