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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              backgroundColor: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.05),
              elevation: 0,
              title: const Text(
                'Account Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
              actions: [
                if (profileState.hasValue)
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    onPressed: () =>
                        _showEditDialog(context, ref, profileState.value!),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: profileState.when(
          data: (profile) => _ProfileContent(
            profile: profile,
            isDark: isDark,
            onLogout: () => _logout(context, ref),
            onEdit: () => _showEditDialog(context, ref, profile),
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
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
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

class _ProfileContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
      children: [
        // ---------------------------------------------------------------------
        // Profile Header / Avatar
        // ---------------------------------------------------------------------
        Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
              Positioned(
                bottom: 0,
                right: 0,
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
            ],
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            profile.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        ),
        Center(
          child: Text(
            profile.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : AppColors.primary).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: 0.1,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                valueColor ??
                (isDark ? Colors.white : AppColors.textPrimaryLight),
          ),
        ),
      ],
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

class _ActionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.redAccent.withValues(alpha: 0.1)
                : (isDark ? Colors.white : AppColors.primary).withValues(
                    alpha: 0.04,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : (isDark ? Colors.white : AppColors.primary).withValues(
                      alpha: 0.08,
                    ),
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
                  color: isDestructive
                      ? Colors.redAccent
                      : (isDark ? Colors.white : AppColors.textPrimaryLight),
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
    );
  }
}
