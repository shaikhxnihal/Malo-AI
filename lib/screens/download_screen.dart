import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/screens/chat_screen.dart';
import 'package:malo/utils/app_theme.dart';
import '../models/models.dart';
import '../services/download_service.dart';

class DownloadScreen extends StatefulWidget {
  final LlmModel model;
  final VoidCallback? onDownloadComplete;
  const DownloadScreen({
    super.key,
    required this.model,
    this.onDownloadComplete,
  });

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  double _speedMbs = 0.0;
  int _receivedMB = 0;
  int _totalMB = 0;
  String _phase = 'Connecting to server...';
  bool _done = false;
  bool _error = false;
  String _errorMsg = '';
  int _etaSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseController);

    _totalMB = widget.model.sizeMB; // Already in MB from your model definition
    _startDownload();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startDownload() {
    DownloadService.instance.downloadModel(
      model: widget.model,
      onProgress: (receivedBytes, totalBytes, speedMBs) {
        if (!mounted) return;

        final totalMB = totalBytes > 0
            ? (totalBytes / (1024 * 1024)).round()
            : widget.model.sizeMB;

        final receivedMB = (receivedBytes / (1024 * 1024)).round();
        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0.0;

        // Calculate ETA
        int eta = 0;
        if (speedMBs > 0.5 && totalMB > receivedMB) {
          eta = ((totalMB - receivedMB) / speedMBs).round();
        }

        setState(() {
          _progress = progress.clamp(0.0, 1.0);
          _receivedMB = receivedMB;
          _totalMB = totalMB;
          _speedMbs = speedMBs;
          _etaSeconds = eta;

          // Phase updates
          if (_progress < 0.08) {
            _phase = 'Connecting to server...';
          } else if (_progress < 0.95) {
            _phase = 'Downloading model weights...';
          } else {
            _phase = 'Finalizing download...';
          }
        });
      },
      onComplete: () {
        if (!mounted) return;
        setState(() {
          _progress = 1.0;
          _done = true;
          _phase = '✓ Download complete!';
        });
        // ✅ FIXED: DON'T clear immediately - let UI show completion
        // DownloadService.instance.clearDownloadState(); // REMOVE THIS
        widget.onDownloadComplete?.call();

        // Clear after delay
        Future.delayed(const Duration(seconds: 3), () {
          DownloadService.instance.clearDownloadState();
        });
      },

      onError: (msg) {
        if (!mounted) return;
        setState(() {
          _error = true;
          _errorMsg = msg;
          _phase = 'Download failed';
        });
        // ✅ FIXED: DON'T clear immediately
        // DownloadService.instance.clearDownloadState(); // REMOVE THIS
      },
    );
  }

  void _cancel() {
    DownloadService.instance.cancelDownload();
    // ✅ FIXED: DON'T clear state here - let it persist for other screens
    // DownloadService.instance.clearDownloadState(); // REMOVE THIS
    Navigator.of(context).pop(false);
  }

  String _formatEta() {
    if (_etaSeconds <= 0) return '—';
    if (_etaSeconds < 60) return '~${_etaSeconds}s left';
    final minutes = _etaSeconds ~/ 60;
    final seconds = _etaSeconds % 60;
    return '~${minutes}m ${seconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: _cancel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textSub,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(color: AppColors.textSub, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Circular progress
              Center(child: _buildCircularProgress(pct)),
              const SizedBox(height: 32),

              // Model info
              _buildModelCard(),
              const SizedBox(height: 24),

              // Linear progress + stats
              _buildLinearProgress(),
              const SizedBox(height: 16),

              // Phase & ETA
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _phase,
                  key: ValueKey(_phase),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _done ? AppColors.success : AppColors.textSub,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!_done && !_error)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatEta(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              _buildStatsRow(),
              const Spacer(),

              // Bottom action area
              if (_error)
                _buildErrorSection()
              else if (_done)
                _buildDoneButton()
              else
                _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress(int pct) {
    final color = _done ? AppColors.success : AppColors.accent;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse glow
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) => Transform.scale(
              scale: _done ? 1.0 : _pulseAnim.value,
              child: child,
            ),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _progress),
            duration: const Duration(milliseconds: 300),
            builder: (_, value, __) => SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                backgroundColor: AppColors.border,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),

          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _done ? '✓' : '$pct%',
                style: GoogleFonts.dmMono(
                  color: color,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                _done ? 'COMPLETE' : 'complete',
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '${widget.model.name} ${widget.model.version}',
            style: GoogleFonts.dmSerifDisplay(
              color: AppColors.textPrimary,
              fontSize: 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.model.quant} · ${widget.model.size}',
            style: const TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLinearProgress() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _progress),
            duration: const Duration(milliseconds: 200),
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                _done ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_receivedMB MB / $_totalMB MB',
              style: const TextStyle(color: AppColors.textSub, fontSize: 12),
            ),
            Text(
              _speedMbs > 0.1 ? '${_speedMbs.toStringAsFixed(1)} MB/s' : '—',
              style: GoogleFonts.dmMono(color: AppColors.textSub, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('RAM Needed', widget.model.ram),
          _divider(),
          _statItem('Inference', widget.model.tokensPerSec),
          _divider(),
          _statItem('Format', 'GGUF'),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.dmMono(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);

  // ... (keep all existing imports and state)

  Widget _buildDoneButton() {
    return GestureDetector(
      // ✅ FIXED: Properly navigate to ChatScreen
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ChatScreen(model: widget.model)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
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
        child: const Text(
          'Start Chatting →',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ... (rest of the file remains the same)

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.dangerDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.4)),
        ),
        child: Text(
          'Cancel Download',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withOpacity(0.35)),
          ),
          child: Text(
            _errorMsg,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _error = false;
                    _progress = 0;
                    _phase = 'Connecting to server...';
                  });
                  _startDownload();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'Retry Download',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _cancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Go Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSub),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
