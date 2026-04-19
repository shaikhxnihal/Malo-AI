import 'dart:io';
import 'package:equatable/src/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevenueCatService {
  static RevenueCatService? _instance;
  RevenueCatService._();
  static RevenueCatService get instance => _instance ??= RevenueCatService._();

  bool _isInitialized = false;
  bool _isPremium = false;
  String _apiKey = dotenv.env['REV_CAT_API_KEY'] ?? 'default_key';





  // ✅ MUST MATCH APP STORE & PLAY STORE PRODUCT IDs
  static const String _premiumProductId = 'malo_premium_lifetime';

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;

  // ✅ Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      // final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
      await Purchases.configure(PurchasesConfiguration(_apiKey));

      await _checkPremiumStatus();

      _isInitialized = true;
      print('✅ RevenueCat initialized successfully');
    } catch (e) {
      print('❌ RevenueCat initialization failed: $e');
    }
  }

  // ✅ Check if user is premium
  Future<void> _checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.active.containsKey('premium');

      // Save locally for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', _isPremium);

      print('💎 Premium status: $_isPremium');
    } catch (e) {
      print('❌ Error checking premium status: $e');
    }
  }

  // ✅ Get available packages
  Future<List<Equatable>> getAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
      return [];
    } catch (e) {
      print('❌ Error getting packages: $e');
      return [];
    }
  }

  // ✅ Purchase premium
  Future<PurchaseResult> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages
          .firstWhere((p) => p.storeProduct.identifier == _premiumProductId);

      if (package == null) {
        return PurchaseResult.error;
      }

      final result = await Purchases.purchasePackage(package);

      if (result.customerInfo.entitlements.active.containsKey('premium')) {
        _isPremium = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium', true);
        return PurchaseResult.success;
      }

      return PurchaseResult.cancelled;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      return PurchaseResult.error;
    } catch (e) {
      return PurchaseResult.error;
    }
  }

  // ✅ Restore purchases (for reinstall/new device)
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _isPremium = customerInfo.entitlements.active.containsKey('premium');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', _isPremium);

      print('✅ Restore successful: $_isPremium');
      return _isPremium;
    } catch (e) {
      print('❌ Restore failed: $e');
      return false;
    }
  }

  // ✅ Check local cache (for offline access)
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
