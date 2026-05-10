// lib/components/navigation/global_sync_header.dart
//
// Reusable header for the Home screen.
// Displays the user's avatar/initials, full name + skill level, and a sync button.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class GlobalSyncHeader extends StatefulWidget {
  const GlobalSyncHeader({super.key});

  @override
  State<GlobalSyncHeader> createState() => _GlobalSyncHeaderState();
}

class _GlobalSyncHeaderState extends State<GlobalSyncHeader> {
  bool _isSyncing = false;
  bool _isOnline  = true;

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final combined = '$f$l';
    return combined.isEmpty ? '?' : combined;
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final online = await ConnectivityService().isOnline();
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _onSyncTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await _checkConnectivity();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    final firstName = user?.firstName ?? '';
    final lastName  = user?.lastName  ?? '';
    final initials  = _initials(firstName, lastName);

    final fullName    = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : 'Student';
    final levelLabel  = user?.startingLevel != null
        ? '${user!.startingLevel} · MyADA'
        : 'MyADA';

    final syncColor  = _isOnline ? AppColors.primary : AppColors.mutedForeground;
    final avatarPath = user?.avatarPath;
    final hasAvatar  = avatarPath != null && File(avatarPath).existsSync();

    return Row(
      children: [
        // ── Avatar ─────────────────────────────────────────────────────────
        CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.primaryLight.withAlpha(50),
          backgroundImage: hasAvatar ? FileImage(File(avatarPath)) : null,
          child: !hasAvatar
              ? Text(
                  initials,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),

        // ── Name + Level ────────────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 15,
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                levelLabel,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),

        // ── Sync Button ─────────────────────────────────────────────────────
        GestureDetector(
          onTap: _onSyncTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: _isSyncing
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: syncColor,
                      ),
                    )
                  : Icon(
                      _isOnline
                          ? Icons.sync_rounded
                          : Icons.sync_disabled_rounded,
                      size: 16,
                      color: syncColor,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
