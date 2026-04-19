import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/utils/app_theme.dart';
import 'package:malo/utils/common_widgets.dart';
import '../models/models.dart';
import '../services/download_service.dart';
import 'chat_screen.dart';
import 'download_screen.dart';

class LibraryScreen extends StatefulWidget {
  final List<String> downloadedModelIds;
  final VoidCallback onRefresh;
  final VoidCallback? onNavigateToModels;

  const LibraryScreen({
    super.key,
    required this.downloadedModelIds,
    required this.onRefresh,
    this.onNavigateToModels,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  DownloadState? _downloadingState;
  StreamSubscription<DownloadState?>? _downloadSubscription;

  @override
  void initState() {
    super.initState();
    _listenToDownloadProgress();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  void _listenToDownloadProgress() {
    _downloadSubscription = DownloadService.instance.downloadStateStream.listen(
      (state) {
        if (mounted) {
          setState(() {
            // ✅ FIXED: Proper null check - only show if actively downloading
            if (state != null && !state.isComplete && !state.hasError) {
              _downloadingState = state;
            } else {
              _downloadingState = null;
            }
          });
        }
      },
    );
    
    // Check if there's an active download on screen load
    final currentState = DownloadService.instance.currentDownloadState;
    if (currentState != null && !currentState.isComplete && !currentState.hasError) {
      setState(() => _downloadingState = currentState);
    }
  }

  Future<void> refresh() async {
    widget.onRefresh();
  }

  Future<void> _deleteModel(LlmModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete ${model.name} ${model.version}?',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove the model file (${model.size}) from your device. You can re-download it later.',
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DownloadService.instance.deleteModel(model);
      widget.onRefresh();
    }
  }

  List<LlmModel> get _downloadedModels {
    return kAvailableModels
        .where((m) => widget.downloadedModelIds.contains(m.id))
        .toList();
  }

  // ✅ FIXED: Safe getter with null check
  LlmModel? get _downloadingModel {
    final state = _downloadingState;
    if (state == null) return null;
    return kAvailableModels.firstWhere(
      (m) => m.id == state.modelId,
      orElse: () => kAvailableModels.first,
    );
  }

  int get _totalSizeMB {
    return _downloadedModels.fold(0, (sum, m) => sum + m.sizeMB);
  }

  @override
  Widget build(BuildContext context) {
    final models = _downloadedModels;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeader(models.length),
          // ✅ FIXED: Only show banner if actively downloading
          if (_downloadingState != null) _buildDownloadBanner(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: models.isEmpty && _downloadingState == null
                ? _buildEmpty(context)
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: All null checks added
  Widget _buildDownloadBanner() {
    final state = _downloadingState;
    if (state == null) return const SizedBox.shrink();
    
    final model = _downloadingModel;
    if (model == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Downloading ${model.name} ${model.version}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DownloadScreen(model: model),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.receivedMB} MB / ${state.totalMB} MB',
                style: const TextStyle(color: AppColors.textSub, fontSize: 11),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: GoogleFonts.dmMono(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (state.speedMbs > 0.1) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.speed, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${state.speedMbs.toStringAsFixed(1)} MB/s · ${_formatEta(state)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ✅ FIXED: Accept state parameter
  String _formatEta(DownloadState state) {
    final remaining = state.totalMB - state.receivedMB;
    if (state.speedMbs > 0.5 && remaining > 0) {
      final eta = (remaining / state.speedMbs).round();
      if (eta < 60) return '${eta}s left';
      final min = eta ~/ 60;
      final sec = eta % 60;
      return '${min}m ${sec}s left';
    }
    return '';
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Models',
                  style: GoogleFonts.dmSerifDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count model${count != 1 ? 's' : ''} downloaded  ·  ${_totalSizeMB} MB used',
                  style: const TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'No models downloaded yet',
            style: TextStyle(color: AppColors.textSub, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to the Models tab to download one',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: widget.onNavigateToModels ?? () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withOpacity(0.35)),
              ),
              child: const Text(
                '⬇  Browse Models',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _downloadedModels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildModelCard(_downloadedModels[i]),
    );
  }

  Widget _buildModelCard(LlmModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const GlowDot(color: AppColors.success, size: 8),
                        const SizedBox(width: 8),
                        Text(
                          model.name,
                          style: GoogleFonts.dmSerifDisplay(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          model.version,
                          style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${model.family} · ${model.quant} · ${model.size}',
                      style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TagBadge(label: model.tag, color: model.tagColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              StatChip(label: 'Speed', value: model.tokensPerSec),
              StatChip(label: 'RAM', value: model.ram),
              StatChip(
                label: 'Quality',
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: QualityDots(quality: model.quality),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(model: model)),
                    ).then((_) => widget.onRefresh());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withOpacity(0.35)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💬 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Chat',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _deleteModel(model),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
