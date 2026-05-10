// lib/features/profile/presentation/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Notification & sync prefs
  bool _dailyChallengeNotif = true;
  bool _streakWarningNotif  = true;
  bool _autoSync            = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dailyChallengeNotif = prefs.getBool('notif_daily_challenge') ?? true;
      _streakWarningNotif  = prefs.getBool('notif_streak_warning')  ?? true;
      _autoSync            = prefs.getBool('pref_auto_sync')         ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ── Avatar Picker ──────────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    await context
        .read<AuthController>()
        .updateProfile(
          context.read<AuthController>().currentUser?.firstName ?? '',
          context.read<AuthController>().currentUser?.lastName ?? '',
          avatarPath: picked.path,
        );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

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
            child: Text('Cancel',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out',
                style: AppTextStyles.label.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthController>().logout();
    }
  }

  // ── Edit Name ───────────────────────────────────────────────────────────────

  Future<void> _showEditDialog(BuildContext context, dynamic user) async {
    final firstCtrl = TextEditingController(text: user?.firstName);
    final lastCtrl  = TextEditingController(text: user?.lastName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Name', style: AppTextStyles.headingSmall),
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
            child: Text('Cancel',
                style: AppTextStyles.label
                    .copyWith(color: AppColors.mutedForeground)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AuthController>()
                  .updateProfile(firstCtrl.text, lastCtrl.text);
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style:
                    AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthController>();
    final user  = auth.currentUser;

    final displayName = user != null
        ? '${user.firstName} ${user.lastName}'.trim()
        : 'Learner';
    final email      = user?.email ?? '—';
    final level      = user?.startingLevel != null
        ? 'Level: ${user!.startingLevel}'
        : 'Take diagnostic to unlock';

    final avatarPath = user?.avatarPath;
    final hasAvatar  = avatarPath != null && File(avatarPath).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),

              // ── Avatar + Name ────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.primary.withAlpha(38),
                            backgroundImage:
                                hasAvatar ? FileImage(File(avatarPath)) : null,
                            child: !hasAvatar
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 44,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.surface, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(displayName, style: AppTextStyles.displayMedium),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,
                              size: 20, color: AppColors.primary),
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
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
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

              // ── Offline / Sync Status ────────────────────────────────────
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

              // ── Sync Preferences ─────────────────────────────────────────
              _SectionCard(
                children: [
                  _ToggleRow(
                    icon: Icons.sync_alt_rounded,
                    label: 'Auto Sync',
                    subtitle: _autoSync ? 'Syncs when online' : 'Manual only',
                    value: _autoSync,
                    onChanged: (v) {
                      setState(() => _autoSync = v);
                      _savePref('pref_auto_sync', v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Notifications ────────────────────────────────────────────
              _SectionCard(
                children: [
                  _ToggleRow(
                    icon: Icons.assignment_outlined,
                    label: 'Daily Challenge Reminder',
                    subtitle: 'Remind me about today\'s challenge',
                    value: _dailyChallengeNotif,
                    onChanged: (v) {
                      setState(() => _dailyChallengeNotif = v);
                      _savePref('notif_daily_challenge', v);
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _ToggleRow(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streak Warning',
                    subtitle: 'Alert before my streak resets',
                    value: _streakWarningNotif,
                    onChanged: (v) {
                      setState(() => _streakWarningNotif = v);
                      _savePref('notif_streak_warning', v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── About ────────────────────────────────────────────────────
              _SectionCard(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About MyADA',
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Logout ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 18),
                  label: Text(
                    'Log Out',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text('MyADA v1.0.0 — Prototype',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('About MyADA', style: AppTextStyles.headingSmall),
        content: Text(
          'MyADA is an offline-first adaptive learning application '
          'designed to help IT students strengthen their programming '
          'foundations through personalized, data-driven learning paths.\n\n'
          'Version: 1.0.0-prototype\n'
          'Built with Flutter & SQLite',
          style: AppTextStyles.body
              .copyWith(color: AppColors.subtleForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style:
                    AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.subtleForeground, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLg),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SettingsRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.subtleForeground, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTextStyles.bodyLg)),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }
}
