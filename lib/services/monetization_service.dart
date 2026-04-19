import 'package:shared_preferences/shared_preferences.dart';
import 'revenue_cat_service.dart';

class MonetizationService {
  static MonetizationService? _instance;
  MonetizationService._();
  static MonetizationService get instance => _instance ??= MonetizationService._();

  // ✅ SET THIS DATE WHEN YOU DECIDE TO MONETIZE
  // Anyone who installed BEFORE this date gets free premium forever
  static final DateTime _grandfatherDate = DateTime(2025, 6, 1);

  bool _isPremium = false;
  bool _isInitialized = false;

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;

  // ✅ Initialize (checks grandfather + RevenueCat)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Check if user is an Early Adopter (Grandfathered)
    final isEarlyAdopter = await _checkEarlyAdopterStatus();

    if (isEarlyAdopter) {
      _isPremium = true;
      print('🎁 User is Early Adopter: Premium Granted for Life');

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true);

      _isInitialized = true;
      return;
    }

    // 2. Otherwise, initialize RevenueCat normally
    await RevenueCatService.instance.initialize();
    _isPremium = RevenueCatService.instance.isPremium;

    _isInitialized = true;
  }

  // ✅ Check if user installed before grandfather date
  Future<bool> _checkEarlyAdopterStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the date they first opened the app
    final firstOpenMillis = prefs.getInt('first_open_date');

    if (firstOpenMillis == null) {
      // First time ever opening app (after monetization update)
      await prefs.setInt('first_open_date', DateTime.now().millisecondsSinceEpoch);
      return false;
    }

    final firstOpenDate = DateTime.fromMillisecondsSinceEpoch(firstOpenMillis);

    // If they installed BEFORE the grandfather date, they get premium
    return firstOpenDate.isBefore(_grandfatherDate);
  }

  // ✅ Purchase premium
  purchasePremium() async {
    return await RevenueCatService.instance.purchasePremium();
  }

  // ✅ Restore purchases
  Future<bool> restorePurchases() async {
    return await RevenueCatService.instance.restorePurchases();
  }

  // ✅ CHECK LOCAL CACHE (for offline access & settings screen)
  Future<bool> checkLocalPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_premium') ?? false;
  }
}

enum PurchaseResult {
  success,
  cancelled,
  error,
}
