import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/utils/app_theme.dart';
import '../services/monetization_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await MonetizationService.instance.checkLocalPremium();
    if (mounted) setState(() => _isPremium = isPremium);
  }

  Future<void> _restorePurchases() async {
    final restored = await MonetizationService.instance.restorePurchases();
    if (mounted) {
      setState(() => _isPremium = restored);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored ? '✅ Premium Restored!' : '❌ No purchase found'),
          backgroundColor: restored ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Settings', style: GoogleFonts.dmSerifDisplay(fontSize: 24)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Premium Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isPremium
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPremium
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPremium ? Icons.workspace_premium : Icons.lock_outline,
                  color: _isPremium ? AppColors.success : AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPremium ? 'Premium Active' : 'Free Version',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isPremium
                            ? 'You have lifetime access to all models'
                            : 'Upgrade to unlock all models',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restore Purchases
          if (!_isPremium)
            ListTile(
              leading: const Icon(Icons.restore, color: AppColors.accent),
              title: const Text('Restore Purchases'),
              subtitle: const Text('Recover your previous purchase'),
              onTap: _restorePurchases,
            ),

          const SizedBox(height: 24),

          // Other Settings
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textSub),
            title: const Text('About'),
            onTap: () {
              // Navigate to about screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.textSub),
            title: const Text('Privacy Policy'),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description, color: AppColors.textSub),
            title: const Text('Terms of Service'),
            onTap: () {
              // Navigate to terms
            },
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
