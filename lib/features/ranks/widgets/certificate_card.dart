// lib/features/ranks/widgets/certificate_card.dart
//
// Renders a printable certificate UI. Wrap in a RepaintBoundary
// with a GlobalKey to enable PNG export via CertificateService.

import 'package:flutter/material.dart';
import '../../../../core/services/certificate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class CertificateCard extends StatelessWidget {
  final CertificateModel cert;
  final String learnerName;
  final GlobalKey? exportKey;

  const CertificateCard({
    super.key,
    required this.cert,
    required this.learnerName,
    this.exportKey,
  });

  String get _typeLabel => CertificateService.instance.typeLabel(cert.type);

  Color get _accentColor => switch (cert.type) {
    CertificateType.excellenceTop1   => AppColors.success,
    CertificateType.excellenceTop10  => AppColors.primary,
    CertificateType.recognitionTop20 => AppColors.accent,
    CertificateType.completion       => AppColors.primaryHover,
    CertificateType.runnerUp         => AppColors.error,
    CertificateType.participation    => AppColors.mutedForeground,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return RepaintBoundary(
      key: exportKey,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: accent.withAlpha(80), width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ornament ────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded, color: accent, size: 26),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Certificate type ───────────────────────────────────────
              Text(
                _typeLabel.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: accent,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── This is to certify ─────────────────────────────────────
              Text(
                'This is to certify that',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Learner name ───────────────────────────────────────────
              Text(
                learnerName,
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.foreground,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Citation ───────────────────────────────────────────────
              Text(
                'has successfully demonstrated proficiency in',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                cert.moduleTitle,
                style: AppTextStyles.headingSmall.copyWith(color: accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'with a score of ${cert.scorePct >= 1.0 ? "100" : (cert.scorePct * 100).round()}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),

              // ── Divider ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Divider(color: AppColors.border),
              ),

              // ── Signatory ──────────────────────────────────────────────
              Column(
                children: [
                  Text(
                    'MyADA Learning System',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Issued ${_formatDate(cert.issuedAt)}  ·  ${cert.certCode}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}
