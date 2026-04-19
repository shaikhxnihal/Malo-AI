import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malo/utils/app_theme.dart';
import '../models/models.dart';

// ── Glowing dot ───────────────────────────────────────────────
class GlowDot extends StatelessWidget {
  final Color color;
  final double size;
  const GlowDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
      ),
    );
  }
}

// ── Quality dots ──────────────────────────────────────────────
class QualityDots extends StatelessWidget {
  final int quality;
  const QualityDots({super.key, required this.quality});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < quality ? AppColors.accent : AppColors.border,
          ),
        );
      }),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;
  const StatChip(
      {super.key, required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        if (value != null)
          Text(
            value!,
            style: GoogleFonts.dmMono(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (child != null) child!,
      ],
    );
  }
}

// ── Tag badge ─────────────────────────────────────────────────
class TagBadge extends StatelessWidget {
  final String label;
  final Color color;
  const TagBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Warning box ───────────────────────────────────────────────
class WarningBox extends StatelessWidget {
  final List<String> warnings;
  const WarningBox({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warnDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warn.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings
            .map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  w,
                  style: const TextStyle(
                    color: AppColors.warn,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Screen header ─────────────────────────────────────────────
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const ScreenHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const GlowDot(color: AppColors.accent, size: 7),
            const SizedBox(width: 8),
            Text(
              'OFFLINE AI',
              style: TextStyle(
                color: AppColors.textSub,
                fontSize: 11,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.dmSerifDisplay(
            color: AppColors.textPrimary,
            fontSize: 24,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Accent button ─────────────────────────────────────────────
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool fullWidth;
  const AccentButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Model card (used in both select + library screens) ────────
class ModelCard extends StatelessWidget {
  final LlmModel model;
  final bool isSelected;
  final bool isDownloaded;
  final List<String> warnings;
  final VoidCallback onTap;

  const ModelCard({
    super.key,
    required this.model,
    required this.isSelected,
    required this.isDownloaded,
    required this.warnings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.card : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : warnings.isNotEmpty
                    ? AppColors.warn.withOpacity(0.4)
                    : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentGlow,
                    blurRadius: 20,
                    spreadRadius: -4,
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        model.name,
                        style: GoogleFonts.dmSerifDisplay(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        model.version,
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDownloaded)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TagBadge(
                        label: '✓ Downloaded',
                        color: AppColors.success),
                  ),
                TagBadge(label: model.tag, color: model.tagColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              model.description,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Stats
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                StatChip(label: 'Size', value: model.size),
                StatChip(label: 'RAM', value: model.ram),
                StatChip(label: 'Speed', value: model.tokensPerSec),
                StatChip(
                  label: 'Quality',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: QualityDots(quality: model.quality),
                  ),
                ),
              ],
            ),
            if (warnings.isNotEmpty) WarningBox(warnings: warnings),
          ],
        ),
      ),
    );
  }
}