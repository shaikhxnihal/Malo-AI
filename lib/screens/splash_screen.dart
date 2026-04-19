import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/screens/on_boarding_screen.dart';
import 'package:malo/services/on_boarding_services.dart';
import 'package:malo/utils/app_theme.dart';
import 'main_shell.dart';
import '../services/database_service.dart';
import '../services/download_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = true;
  String _loadingText = 'Initializing...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeApp();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    // ✅ Simulate loading steps with progress
    await _updateLoading('Loading services...', 0.2, 600);
    await _updateLoading('Checking device...', 0.4, 600);
    await _updateLoading('Preparing AI models...', 0.6, 600);
    await _updateLoading('Finalizing...', 0.8, 600);

    // ✅ Initialize core services
    await DatabaseService.instance.db;
    await DownloadService.instance;

    // ✅ Check onboarding status
    final isOnboardingComplete = 
        await OnboardingService.instance.isOnboardingComplete();

    if (!mounted) return;

    // ✅ Navigate with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isOnboardingComplete
            ? const MainShell()
            : const OnboardingScreen(),
        transitionsBuilder: (_, __, ___, child) => FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(__),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _updateLoading(String text, double progress, int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    if (mounted) {
      setState(() {
        _loadingText = text;
        _loadingProgress = progress;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ✅ Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.border,
                  AppColors.bg,
                  AppColors.bg,
                ],
              ),
            ),
          ),

          // ✅ Animated content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ App Logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.bg.withOpacity(0.3),
                                AppColors.bg.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo-bg.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // ✅ Fallback if logo not found
                                return const Icon(
                                  Icons.psychology_outlined,
                                  size: 60,
                                  color: AppColors.accent,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ✅ App Name
                        Text(
                          'Malo',
                          style: GoogleFonts.dmSerifDisplay(
                            color: AppColors.textPrimary,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ✅ Tagline
                        Text(
                          'Offline AI Assistant',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ Bottom loading section
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // ✅ Loading text
                  Text(
                    _loadingText,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _loadingProgress,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ✅ Version number
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Subtle animated particles (optional visual flair)
          ...List.generate(5, (index) => _buildParticle(index)),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    return Positioned(
      left: (index * 60 + 50).toDouble(),
      top: (index * 100 + 100).toDouble(),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 1500 + (index * 300)),
        builder: (context, value, child) {
          return Opacity(
            opacity: value * 0.3,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
          );
        },
      ),
    );
  }
}
