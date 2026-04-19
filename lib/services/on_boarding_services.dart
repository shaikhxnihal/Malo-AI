import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static OnboardingService? _instance;
  OnboardingService._();
  static OnboardingService get instance => _instance ??= OnboardingService._();

  // ✅ Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  // ✅ Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  // ✅ Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
  }
}
