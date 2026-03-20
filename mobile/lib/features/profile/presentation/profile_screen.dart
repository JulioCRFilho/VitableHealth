import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/colors/app_colors.dart';
import '../application/profile_provider.dart';

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
              backgroundColor:
                  (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
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
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () {
                    // Logic to edit profile info
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: profileState.when(
          data: (profile) => _ProfileContent(profile: profile, isDark: isDark),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final dynamic profile; // UserProfile
  final bool isDark;

  const _ProfileContent({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
                        ? const Icon(Icons.person_rounded,
                            size: 60, color: Colors.white24)
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
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        ),
        Center(
          child: Text(
            profile.email,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                value: 'VIT-${profile.id.substring(0, 4).toUpperCase()}',
                isDark: isDark,
              ),
              Divider(height: 32, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              _InfoRow(
                icon: Icons.verified_user_rounded,
                label: 'Status',
                value: profile.status.toUpperCase(),
                valueColor: Colors.greenAccent,
                isDark: isDark,
              ),
              Divider(height: 32, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
              _InfoRow(
                icon: Icons.health_and_safety_rounded,
                label: 'Health Plan',
                value: profile.planId.contains('complete') ? 'Complete' : 'Basic',
                isDark: isDark,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

        const SizedBox(height: 24),

        // ---------------------------------------------------------------------
        // Action List
        // ---------------------------------------------------------------------
        _SectionTitle(title: 'Settings', isDark: isDark)
            .animate()
            .fadeIn(delay: 500.ms),
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
              onTap: () {},
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
            color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
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
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight),
            fontSize: 14,
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
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
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
                : (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.08),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.redAccent : (isDark ? Colors.white : AppColors.textPrimaryLight),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: (isDestructive ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
