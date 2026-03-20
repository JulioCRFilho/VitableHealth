import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/colors/app_colors.dart';
import '../application/profile_provider.dart';
import '../domain/models/user_profile.dart';
import '../../identity/application/auth_notifier.dart';
import '../../../core/design/theme/high_contrast_provider.dart';
import '../../../core/design/accessibility/accessibility_dialogs.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = ref.watch(highContrastProvider);

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1A2D2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF0FAF8), Color(0xFFE9F5F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: isHighContrast
                  ? theme.scaffoldBackgroundColor
                  : (isDark ? Colors.black : Colors.white).withValues(
                      alpha: 0.05,
                    ),
              elevation: 0,
              title: const Text(
                'Account Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              ),
              actions: [
                if (profileState.hasValue)
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    tooltip: 'Edit Profile Details',
                    onPressed: () =>
                        _showEditDialog(context, ref, profileState.value!),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.accessibility_new_rounded),
                  tooltip: 'Accessibility Options',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  onSelected: (value) {
                    if (value == 'font_size') {
                      showTextScaleDialog(context, ref);
                    } else if (value == 'contrast') {
                      ref.read(highContrastProvider.notifier).toggle();
                      final isHighContrast = ref.read(highContrastProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isHighContrast
                                ? 'High contrast mode enabled'
                                : 'High contrast mode disabled',
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Feature $value coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'font_size',
                      child: Row(
                        children: [
                          Icon(Icons.text_fields_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Text Size'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'contrast',
                      child: Row(
                        children: [
                          Icon(Icons.contrast_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('High Contrast'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'screen_reader',
                      child: Row(
                        children: [
                          Icon(Icons.record_voice_over_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Screen Reader Help'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isHighContrast ? null : bgGradient,
          color: isHighContrast ? theme.scaffoldBackgroundColor : null,
        ),
        child: profileState.when(
          data: (profile) => _ProfileContent(
            profile: profile,
            isDark: isDark,
            onLogout: () => _logout(context, ref),
            onEdit: () => _showEditDialog(context, ref, profile!),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/?message=I want to login'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('I want to login'),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(profileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Enter your full name',
                child: TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Enter your email address',
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final updated = profile.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
              );

              Navigator.of(ctx).pop();
              await ref.read(profileProvider.notifier).updateProfile(updated);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/');
    }
  }
}

class _ProfileContent extends ConsumerWidget {
  final dynamic profile; // UserProfile
  final bool isDark;
  final VoidCallback onLogout;
  final VoidCallback onEdit;

  const _ProfileContent({
    required this.profile,
    required this.isDark,
    required this.onLogout,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isHighContrast = ref.watch(highContrastProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
      children: [
        // ---------------------------------------------------------------------
        // Profile Header / Avatar
        // ---------------------------------------------------------------------
        Center(
          child: Stack(
            children: [
              Semantics(
                label: 'Profile picture of ${profile.name}',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: isHighContrast
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                    border: isHighContrast
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 3,
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Hero(
                    tag: 'profile-photo',
                    child: CircleAvatar(
                      backgroundImage: profile.profilePictureUrl != null
                          ? NetworkImage(profile.profilePictureUrl!)
                          : null,
                      backgroundColor: Colors.white12,
                      child: profile.profilePictureUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: Colors.white24,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Semantics(
                  button: true,
                  label: 'Change profile picture',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),

        const SizedBox(height: 16),

        Center(
          child: Semantics(
            header: true,
            label: 'User Name: ${profile.name}',
            child: Text(
              profile.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        ),
        Center(
          child: Semantics(
            label: 'User Email: ${profile.email}',
            child: Text(
              profile.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isHighContrast
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        ),

        const SizedBox(height: 32),

        // ---------------------------------------------------------------------
        // Info Section Cards
        // ---------------------------------------------------------------------
        _GlassCard(
          isDark: isDark,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.vpn_key_rounded,
                label: 'Membership ID',
                value: profile.id.length >= 4
                    ? 'VIT-${profile.id.substring(0, 4).toUpperCase()}'
                    : 'VIT-${profile.id.toUpperCase()}',
                isDark: isDark,
              ),
              Divider(
                height: 32,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
              _InfoRow(
                icon: Icons.verified_user_rounded,
                label: 'Status',
                value: profile.status.toUpperCase(),
                valueColor: Colors.greenAccent,
                isDark: isDark,
              ),
              Divider(
                height: 32,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
              _InfoRow(
                icon: Icons.health_and_safety_rounded,
                label: 'Health Plan',
                value: profile.planId.contains('complete')
                    ? 'Complete'
                    : 'Basic',
                isDark: isDark,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // Action List
        // ---------------------------------------------------------------------
        _SectionTitle(
          title: 'Settings',
          isDark: isDark,
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 12),

        Column(
          children: [
            _ActionTile(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications',
              onTap: () {},
              isDark: isDark,
            ),
            _ActionTile(
              icon: Icons.security_rounded,
              title: 'Security \u0026 Privacy',
              onTap: () {},
              isDark: isDark,
            ),
            _ActionTile(
              icon: Icons.help_outline_rounded,
              title: 'Help Center',
              onTap: () {},
              isDark: isDark,
            ),
            _ActionTile(
              icon: Icons.logout_rounded,
              title: 'Logout',
              isDestructive: true,
              onTap: onLogout,
              isDark: isDark,
            ),
          ],
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Component Widgets
// -----------------------------------------------------------------------------

class _GlassCard extends ConsumerWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(highContrastProvider);
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isHighContrast
                ? theme.scaffoldBackgroundColor
                : (isDark ? Colors.white : AppColors.primary).withValues(
                    alpha: 0.05,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighContrast
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.white : AppColors.primary).withValues(
                      alpha: 0.1,
                    ),
              width: isHighContrast ? 2.0 : 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isHighContrast = ref.watch(highContrastProvider);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? (isDark ? Colors.white12 : Colors.black12)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: isHighContrast
                  ? Border.all(color: isDark ? Colors.white : Colors.black)
                  : null,
            ),
            child: Icon(
              icon,
              color: isHighContrast
                  ? (isDark ? Colors.white : Colors.black)
                  : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isHighContrast
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color:
                  valueColor ??
                  (isHighContrast
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white : AppColors.textPrimaryLight)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }
}

class _ActionTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isDark;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isHighContrast = ref.watch(highContrastProvider);
    return Semantics(
      button: true,
      label: '$title button',
      hint: isDestructive
          ? 'Will perform a destructive action'
          : 'Tap to open $title',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? theme.scaffoldBackgroundColor
                  : (isDestructive
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : (isDark ? Colors.white : AppColors.primary)
                              .withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighContrast
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDestructive
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : (isDark ? Colors.white : AppColors.primary)
                                .withValues(alpha: 0.08)),
                width: isHighContrast ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive ? Colors.redAccent : AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighContrast
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDestructive
                              ? Colors.redAccent
                              : (isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight)),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: (isDestructive ? Colors.redAccent : AppColors.primary)
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
