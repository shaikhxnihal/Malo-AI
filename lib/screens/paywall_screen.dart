import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/utils/app_theme.dart';
import '../services/monetization_service.dart';

class PaywallScreen extends StatefulWidget {
  final VoidCallback? onPurchaseComplete;

  const PaywallScreen({super.key, this.onPurchaseComplete});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await MonetizationService.instance.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _purchase() async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    final result = await MonetizationService.instance.purchasePremium();

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (result == PurchaseResult.success) {
      widget.onPurchaseComplete?.call();
      if (mounted) Navigator.of(context).pop(true);
    } else if (result == PurchaseResult.cancelled) {
      // User cancelled, do nothing
    } else {
      setState(() => _error = 'Purchase failed. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);

    final restored = await MonetizationService.instance.restorePurchases();

    if (!mounted) return;

    setState(() => _isPurchasing = false);

    if (mounted) {
      if (restored) {
        widget.onPurchaseComplete?.call();
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No purchases found to restore')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Top bar with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: AppColors.textSub),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Main content (flexible, fits available space)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withOpacity(0.3),
                            AppColors.accent.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Unlock Premium',
                      style: GoogleFonts.dmSerifDisplay(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access all AI models on your device',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Features (compact)
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildFeature('🚀 Access Tier 3-5 Models', true),
                          _buildFeature('⚡ Faster Inference Speed', true),
                          _buildFeature('🔒 Priority Support', true),
                          _buildFeature('📦 Unlimited Downloads', true),
                          _buildFeature('💬 Advanced Reasoning Models', true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Price Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                'One-Time',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '\$9.99',
                                style: GoogleFonts.dmMono(
                                  color: AppColors.accent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Lifetime',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error message
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.dangerDim,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ✅ Bottom Action Bar (fixed)
            Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.bg,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  // Purchase Button
                  GestureDetector(
                    onTap: _isPurchasing ? null : _purchase,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFF00C4B4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_open, color: Colors.black, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Purchase Premium',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Restore Button
                  TextButton(
                    onPressed: _isPurchasing ? null : _restore,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restore, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Restore Purchase',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Terms
                  const SizedBox(height: 8),
                  Text(
                    'Secure payment via Apple/Google. No recurring charges.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String text, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.info_outline,
            size: 18,
            color: included ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: included ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
