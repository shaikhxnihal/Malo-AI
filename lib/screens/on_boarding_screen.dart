import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/models/models.dart';
import 'package:malo/services/display_info_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:malo/utils/app_theme.dart';
import 'package:malo/utils/common_widgets.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  DeviceInfo? _deviceInfo;
  bool _loadingDevice = true;

  // ✅ Onboarding pages data
  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.security_outlined,
      emoji: '🔒',
      title: '100% Offline & Private',
      description: 'Your conversations never leave your device. No servers, no tracking, no cloud. Complete privacy guaranteed.',
      color: AppColors.success,
    ),
    _OnboardingPage(
      icon: Icons.psychology_outlined,
      emoji: '🧠',
      title: 'Powerful AI Models',
      description: 'Choose from 25+ AI models ranging from ultra-light 135M to powerful 32B parameters. Something for every device.',
      color: AppColors.accent,
    ),
    _OnboardingPage(
      icon: Icons.speed_outlined,
      emoji: '⚡',
      title: 'Optimized for Mobile',
      description: 'Models are quantized and optimized for ARM processors. Get desktop-class AI on your phone.',
      color: AppColors.blue,
    ),
    _OnboardingPage(
      icon: Icons.memory,
      emoji: '📱',
      title: 'Device Compatibility',
      description: 'Smart model recommendations based on your RAM and storage. No crashes, no guesswork.',
      color: AppColors.warn,
      isDeviceCheck: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoService.instance.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loadingDevice = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    
    // ✅ Navigate to MainShell with fade transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, __, ___, child) => FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(__),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ✅ Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),

            // ✅ Bottom controls
            _buildBottomControls(),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Icon/Illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    page.color.withOpacity(0.2),
                    page.color.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: page.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  page.emoji,
                  style: const TextStyle(fontSize: 72),
                ),
              ),
            ),
        
            const SizedBox(height: 48),
        
            // ✅ Title
            Text(
              page.title,
              style: GoogleFonts.dmSerifDisplay(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
        
            const SizedBox(height: 16),
        
            // ✅ Description
            Text(
              page.description,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
        
            // ✅ Device Info (only on compatibility page)
            if (page.isDeviceCheck && _deviceInfo != null) ...[
              const SizedBox(height: 32),
              _buildDeviceCompatibilityCard(),
            ],
        
            // ✅ Loading state
            if (page.isDeviceCheck && _loadingDevice) ...[
              const SizedBox(height: 32),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                   
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Detecting your device...',
                    style: TextStyle(color: AppColors.textSub, fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCompatibilityCard() {
    if (_deviceInfo == null) return const SizedBox.shrink();

    // ✅ Calculate compatibility score
    final compatibleModels = kAvailableModels
        .where((m) => 
          _deviceInfo!.ramGB >= m.minRamGB && 
          _deviceInfo!.availableStorageMB >= m.minStorageMB
        ).length;
    
    final ratio = compatibleModels / kAvailableModels.length;
    final percentage = (ratio * 100).toInt();

    Color compatibilityColor;
    String compatibilityText;
    IconData compatibilityIcon;

    if (percentage >= 70) {
      compatibilityColor = AppColors.success;
      compatibilityText = 'Great Compatibility';
      compatibilityIcon = Icons.check_circle_outline;
    } else if (percentage >= 40) {
      compatibilityColor = AppColors.warn;
      compatibilityText = 'Limited Compatibility';
      compatibilityIcon = Icons.warning_amber_rounded;
    } else {
      compatibilityColor = AppColors.danger;
      compatibilityText = 'Low Compatibility';
      compatibilityIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ✅ Device name
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _deviceInfo!.deviceName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ Specs row
          Row(
            children: [
              Expanded(
                child: _buildSpecItem(
                  Icons.memory,
                  'RAM',
                  '${_deviceInfo!.ramGB} GB',
                  _deviceInfo!.ramGB >= 6 ? AppColors.success : 
                        _deviceInfo!.ramGB >= 4 ? AppColors.warn : AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSpecItem(
                  Icons.storage,
                  'Storage',
                  '${(_deviceInfo!.availableStorageMB / 1024).toStringAsFixed(1)} GB',
                  _deviceInfo!.availableStorageMB >= 8000 ? AppColors.success : 
                        _deviceInfo!.availableStorageMB >= 4000 ? AppColors.warn : AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ Compatibility badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: compatibilityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: compatibilityColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(compatibilityIcon, size: 16, color: compatibilityColor),
                const SizedBox(width: 6),
                Text(
                  '$compatibilityText ($percentage%)',
                  style: TextStyle(
                    color: compatibilityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Tip
          Text(
            percentage >= 70 
                ? '✓ You can run most models smoothly!'
                : percentage >= 40
                    ? '💡 Stick to Tier 1-3 models for best performance'
                    : '💡 We recommend ultra-light models for your device',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        // ✅ Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index 
                    ? AppColors.accent 
                    : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ✅ CTA Button
        GestureDetector(
          onTap: _nextPage,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFF00C4B4)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentPage == _pages.length - 1 
                      ? Icons.check 
                      : Icons.arrow_forward_ios_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        // ✅ Progress text
        if (_currentPage < _pages.length - 1) ...[
          const SizedBox(height: 16),
          Text(
            '${_currentPage + 1} of ${_pages.length}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Onboarding Page Data Model ──────────────────────────────────
class _OnboardingPage {
  final IconData icon;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final bool isDeviceCheck;

  const _OnboardingPage({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    this.isDeviceCheck = false,
  });
}
