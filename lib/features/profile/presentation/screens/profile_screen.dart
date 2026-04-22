// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text('Log out?', style: AppTextStyles.headingSmall),
        content: Text(
          'Your progress is saved locally and will still be here when you log back in.',
          style: AppTextStyles.body.copyWith(color: AppColors.subtleForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.label.copyWith(color: AppColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log out',
              style: AppTextStyles.label.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthController>().logout();
    }
  }

  Future<void> _showEditDialog(BuildContext context, dynamic user) async {
    final firstCtrl = TextEditingController(text: user?.firstName);
    final lastCtrl = TextEditingController(text: user?.lastName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Profile', style: AppTextStyles.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstCtrl, 
              decoration: const InputDecoration(labelText: 'First Name'),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: lastCtrl, 
              decoration: const InputDecoration(labelText: 'Last Name'),
              style: AppTextStyles.body,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthController>().updateProfile(firstCtrl.text, lastCtrl.text);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    final displayName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Learner';
    final email = user?.email ?? '—';
    final level = user?.startingLevel != null
        ? 'Level: ${user!.startingLevel}'
        : 'Take diagnostic to unlock';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // Avatar + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(38),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(102),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(displayName, style: AppTextStyles.displayMedium),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                          onPressed: () => _showEditDialog(context, user),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(email, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user?.startingLevel != null
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: user?.startingLevel != null
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                            size: 14,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(level, style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Offline storage status
              _SectionCard(
                children: [
                  _InfoRow(
                    icon: Icons.offline_pin_rounded,
                    label: 'Offline Storage',
                    value: '0 MB used',
                    color: AppColors.accent,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _InfoRow(
                    icon: Icons.sync_rounded,
                    label: 'Last Sync',
                    value: user?.lastSeenAt != null
                        ? _formatDate(user!.lastSeenAt)
                        : 'Never',
                    color: AppColors.mutedForeground,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Settings section
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _SettingsRow(
                    icon: Icons.text_increase_rounded,
                    label: 'Text Size',
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _SettingsRow(icon: Icons.language_rounded, label: 'Language'),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // About section
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About MyADA',
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  label: Text(
                    'Log Out',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('MyADA v1.0.0 — Prototype', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.bodyLg),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SettingsRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.subtleForeground, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.bodyLg)),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedForeground,
            size: 20,
          ),
        ],
      ),
    );
  }
}
