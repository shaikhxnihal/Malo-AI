import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/services/display_info_service.dart';
import 'package:malo/services/download_service.dart';
import 'package:malo/services/monetization_service.dart';
import 'package:malo/utils/app_theme.dart';
import '../models/models.dart';
import 'download_screen.dart';
import 'paywall_screen.dart';

class ModelsScreen extends StatefulWidget {
  final VoidCallback? onDownloadComplete;

  const ModelsScreen({super.key, this.onDownloadComplete});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DeviceInfo? _deviceInfo;
  bool _loadingDeviceInfo = true;

  // Track download progress
  DownloadState? _downloadingState;
  StreamSubscription<DownloadState?>? _downloadSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ModelTier.values.length,
      vsync: this,
    );
    _loadDeviceInfo();
    _listenToDownloadProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _downloadSubscription?.cancel();
    super.dispose();
  }

  // Listen to download progress
  void _listenToDownloadProgress() {
    _downloadSubscription = DownloadService.instance.downloadStateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            if (state != null && !state.isComplete && !state.hasError) {
              _downloadingState = state;
            } else {
              _downloadingState = null;
            }
          });
        }
      },
    );
  }

  // Check if model is currently downloading
  bool _isDownloading(String modelId) {
    final state = _downloadingState;
    return state != null && state.modelId == modelId;
  }

  // Get download progress for a model
  double? _getDownloadProgress(String modelId) {
    final state = _downloadingState;
    if (state == null || state.modelId != modelId) return null;
    return state.progress;
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoService.instance.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loadingDeviceInfo = false;
      });
    }
  }

  // Check if model is compatible with device
  bool _isModelCompatible(LlmModel model) {
    if (_deviceInfo == null) return true;

    final ramOk = _deviceInfo!.ramGB >= model.minRamGB;
    final storageOk = _deviceInfo!.availableStorageMB >= model.minStorageMB;

    return ramOk && storageOk;
  }

  // Get compatibility warnings for a model
  List<String> _getCompatibilityWarnings(LlmModel model) {
    if (_deviceInfo == null) return [];

    final warnings = <String>[];

    if (_deviceInfo!.ramGB < model.minRamGB) {
      warnings.add(
          'Insufficient RAM (Need ${model.minRamGB}GB, Have ${_deviceInfo!.ramGB}GB)');
    }

    if (_deviceInfo!.availableStorageMB < model.minStorageMB) {
      final needGB = (model.minStorageMB / 1024).toStringAsFixed(1);
      final haveGB = (_deviceInfo!.availableStorageMB / 1024).toStringAsFixed(1);
      warnings.add(
          'Insufficient Storage (Need ${needGB}GB, Have ${haveGB}GB)');
    }

    return warnings;
  }

  // ✅ Check if model requires premium
  bool _isPremiumModel(LlmModel model) {
    return model.minRamGB >= 4; // Tier 3+ requires premium
  }

  // ✅ Check if user can access this model
  bool _canAccessModel(LlmModel model) {
    final isPremiumModel = _isPremiumModel(model);
    final isUserPremium = MonetizationService.instance.isPremium;
    return !isPremiumModel || isUserPremium;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  _buildHeader(),
                  _buildDeviceConfigCard(),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSub,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  tabs: ModelTier.values
                      .map((tier) => Tab(text: tier.label))
                      .toList(),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: ModelTier.values.map((tier) {
            final models =
                kAvailableModels.where((m) => m.tier == tier).toList();
            return _buildTierPage(tier, models);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose AI Model",
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Select a model compatible with your device",
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Refresh button
          GestureDetector(
            onTap: _loadDeviceInfo,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppColors.textSub,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceConfigCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: _loadingDeviceInfo
            ? const Row(
                children: [
                  CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                   
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Detecting device specs...',
                    style: TextStyle(color: AppColors.textSub, fontSize: 13),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Device',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Overall compatibility badge
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getOverallCompatibilityColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getOverallCompatibilityIcon(),
                              size: 12,
                              color: _getOverallCompatibilityColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getOverallCompatibilityText(),
                              style: TextStyle(
                                color: _getOverallCompatibilityColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDeviceStat(
                          Icons.memory,
                          'RAM',
                          '${_deviceInfo!.ramGB} GB',
                          _deviceInfo!.ramGB >= 6
                              ? AppColors.success
                              : _deviceInfo!.ramGB >= 4
                                  ? AppColors.warn
                                  : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDeviceStat(
                          Icons.storage,
                          'Storage',
                          '${(_deviceInfo!.availableStorageMB / 1024).toStringAsFixed(1)} GB',
                          _deviceInfo!.availableStorageMB >= 8000
                              ? AppColors.success
                              : _deviceInfo!.availableStorageMB >= 4000
                                  ? AppColors.warn
                                  : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDeviceStat(
                          Icons.battery_full_rounded,
                          'Battery',
                          '—',
                          AppColors.textMuted,
                          isPlaceholder: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _deviceInfo!.deviceName,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeviceStat(IconData icon, String label, String value, Color color,
      {bool isPlaceholder = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isPlaceholder ? AppColors.textMuted : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOverallCompatibilityColor() {
    if (_deviceInfo == null) return AppColors.textMuted;

    final highRamModels =
        kAvailableModels.where((m) => m.minRamGB <= _deviceInfo!.ramGB).length;
    final ratio = highRamModels / kAvailableModels.length;

    if (ratio >= 0.7) return AppColors.success;
    if (ratio >= 0.4) return AppColors.warn;
    return AppColors.danger;
  }

  IconData _getOverallCompatibilityIcon() {
    if (_deviceInfo == null) return Icons.info_outline;

    final highRamModels =
        kAvailableModels.where((m) => m.minRamGB <= _deviceInfo!.ramGB).length;
    final ratio = highRamModels / kAvailableModels.length;

    if (ratio >= 0.7) return Icons.check_circle_outline;
    if (ratio >= 0.4) return Icons.warning_amber_rounded;
    return Icons.error_outline;
  }

  String _getOverallCompatibilityText() {
    if (_deviceInfo == null) return 'Checking...';

    final highRamModels =
        kAvailableModels.where((m) => m.minRamGB <= _deviceInfo!.ramGB).length;
    final ratio = highRamModels / kAvailableModels.length;

    if (ratio >= 0.7) return 'Great Compatibility';
    if (ratio >= 0.4) return 'Limited Compatibility';
    return 'Low Compatibility';
  }

  Widget _buildTierPage(ModelTier tier, List<LlmModel> models) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: models.length,
      itemBuilder: (context, index) {
        return _buildModelCard(models[index]);
      },
    );
  }

  Widget _buildModelCard(LlmModel model) {
    final isCompatible = _isModelCompatible(model);
    final warnings = _getCompatibilityWarnings(model);
    final isDownloading = _isDownloading(model.id);
    final progress = _getDownloadProgress(model.id);
    final state = _downloadingState;

    // ✅ Premium check
    final isPremiumModel = _isPremiumModel(model);
    final isUserPremium = MonetizationService.instance.isPremium;
    final isLocked = isPremiumModel && !isUserPremium;

    return GestureDetector(
      onTap: isLocked
          ? () => _showPaywall()
          : isDownloading
              ? () => _showDownloadProgressDialog(model)
              : isCompatible
                  ? () => _showDownloadConfirmation(model)
                  : () => _showIncompatibleDialog(model),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isCompatible ? AppColors.card : AppColors.card.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: model.recommended
                ? AppColors.accent
                : isCompatible
                    ? AppColors.border
                    : AppColors.warn.withOpacity(0.5),
            width: model.recommended ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${model.name} ${model.version}',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 19,
                              color: isLocked
                                  ? AppColors.textMuted
                                  : isCompatible
                                      ? AppColors.textPrimary
                                      : AppColors.textSub,
                            ),
                          ),
                          if (model.recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Recommended",
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        model.description,
                        style: TextStyle(
                          color: isLocked
                              ? AppColors.textMuted
                              : isCompatible
                                  ? AppColors.textSub
                                  : AppColors.textMuted,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ✅ Lock icon for premium models
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Download progress
            if (isDownloading && progress != null && state != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.receivedMB} MB / ${state.totalMB} MB',
                    style: const TextStyle(color: AppColors.textSub, fontSize: 10),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.dmMono(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Compatibility Warnings
            if (warnings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warn.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warn.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.warn),
                        const SizedBox(width: 6),
                        Text(
                          'Device Compatibility Warning',
                          style: TextStyle(
                            color: AppColors.warn,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppColors.warn, fontSize: 11)),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: const TextStyle(
                                    color: AppColors.textSub,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Tier Tag
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: model.tier.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    model.tier.label,
                    style: TextStyle(
                      color: model.tier.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Compatibility Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCompatible
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.warn.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompatible
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 12,
                        color:
                            isCompatible ? AppColors.success : AppColors.warn,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompatible ? 'Compatible' : 'May Not Work',
                        style: TextStyle(
                          color:
                              isCompatible ? AppColors.success : AppColors.warn,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Premium Badge
                if (isPremiumModel && !isUserPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: AppColors.warn,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Device Info + Stats Row
            Row(
              children: [
                _buildInfoItem(Icons.memory, "RAM", model.ram,
                    _deviceInfo != null &&
                        _deviceInfo!.ramGB < model.minRamGB),
                const SizedBox(width: 12),
                _buildInfoItem(Icons.storage, "Size", model.size,
                    _deviceInfo != null &&
                        _deviceInfo!.availableStorageMB < model.minStorageMB),
                const SizedBox(width: 12),
                _buildInfoItem(
                    Icons.speed, "Speed", model.tokensPerSec, false),
              ],
            ),

            const SizedBox(height: 12),

            // Subtitle / Device requirement
            Text(
              model.tier.subtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: isLocked
                    ? () => _showPaywall()
                    : isDownloading
                        ? () => _showDownloadProgressDialog(model)
                        : isCompatible
                            ? () => _showDownloadConfirmation(model)
                            : () => _showIncompatibleDialog(model),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isLocked || !isCompatible
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.accent, Color(0xFF00C4B4)]),
                    color: isLocked || !isCompatible
                        ? AppColors.surface
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked
                          ? AppColors.accent.withOpacity(0.3)
                          : !isCompatible
                              ? AppColors.border
                              : AppColors.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock
                            : isCompatible
                                ? Icons.download_rounded
                                : Icons.block_rounded,
                        size: 18,
                        color: isLocked
                            ? AppColors.accent
                            : isCompatible
                                ? Colors.black
                                : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLocked
                            ? 'Unlock Premium'
                            : isCompatible
                                ? 'Download'
                                : 'Not Compatible',
                        style: TextStyle(
                          color: isLocked
                              ? AppColors.accent
                              : isCompatible
                                  ? Colors.black
                                  : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value,
      bool isWarning) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isWarning ? AppColors.warn : AppColors.textSub,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isWarning ? AppColors.warn : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirmation Dialog ─────────────────────────────────────
  void _showDownloadConfirmation(LlmModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Download ${model.name} ${model.version}?",
          style: GoogleFonts.dmSerifDisplay(fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              model.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.memory, color: AppColors.textSub, size: 20),
                const SizedBox(width: 8),
                Text("Requires ~${model.ram}",
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storage, color: AppColors.textSub, size: 20),
                const SizedBox(width: 8),
                Text("Size: ${model.size}",
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
            if (_deviceInfo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _isModelCompatible(model)
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: _isModelCompatible(model)
                        ? AppColors.success
                        : AppColors.warn,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isModelCompatible(model)
                        ? '✓ Your device meets requirements'
                        : '⚠ May not work on your device',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isModelCompatible(model)
                          ? AppColors.success
                          : AppColors.warn,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startDownload(model);
            },
            child: const Text("Download Now"),
          ),
        ],
      ),
    );
  }

  // ✅ Show paywall for locked models
  void _showPaywall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          onPurchaseComplete: () {
            setState(() {}); // Refresh UI after purchase
          },
        ),
      ),
    );
  }

  // Show dialog when model is incompatible
  void _showIncompatibleDialog(LlmModel model) {
    final warnings = _getCompatibilityWarnings(model);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 24),
            const SizedBox(width: 8),
            const Text(
              "Device Not Compatible",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${model.name} ${model.version} requires more resources than your device has available.',
              style: const TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
            const SizedBox(height: 16),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.close, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Text(
                '💡 Tip: Try a smaller model from Tier 1 or Tier 2 for better performance on your device.',
                style: TextStyle(fontSize: 12, color: AppColors.textSub),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("OK", style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(0); // Go to Tier 1
            },
            child: const Text("Browse Compatible"),
          ),
        ],
      ),
    );
  }

  // Show download progress dialog
  void _showDownloadProgressDialog(LlmModel model) {
    final state = _downloadingState;
    if (state == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Download in Progress'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${model.name} ${model.version} is downloading...',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: state.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.receivedMB} MB / ${state.totalMB} MB',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                Text(
                  '${(state.progress * 100).toInt()}%',
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (state.speedMbs > 0.1) ...[
              const SizedBox(height: 8),
              Text(
                '${state.speedMbs.toStringAsFixed(1)} MB/s',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DownloadScreen(model: model)),
              );
            },
            child: const Text('View Details',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _startDownload(LlmModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DownloadScreen(
          model: model,
          onDownloadComplete: widget.onDownloadComplete,
        ),
      ),
    );
  }
}

// ── SliverAppBarDelegate for pinned TabBar ────────────────────────
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
