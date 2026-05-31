import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/auth_storage.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

import '../donation/donation_history_screen.dart';
import 'account_settings_screen.dart';
import 'edit_profile_dialog.dart';
import 'user_activity_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = DonationRepository();

    return FutureBuilder<UserModel>(
      future: repo.getProfile(),
      builder: (context, snapshot) {
        final state = snapshot.connectionState;

        if (state == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AdaTitikAppBar(
              title: 'Profil',
              onNotification: () => context.push('/home/notification'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load profile',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AdaTitikAppBar(
            title: 'Profil',
            onNotification: () => context.push('/home/notification'),
          ),
          body: _ProfileContent(
            user: snapshot.data!,
            onLogout: () async {
              await AuthStorage.clear();
              ref.invalidate(authProvider);
              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        );
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;
  final Future<void> Function() onLogout;

  Future<void> _openEditProfileDialog(BuildContext context,
      {required UserModel user}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    );
    // Parent screen refresh is handled by reloading profile in next iteration; for now just close.
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    }
  }

  const _ProfileContent({
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 12),
          _buildQuickLinks(context),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Your Impact', style: AppTextStyles.headlineMedium),
          ),
          const SizedBox(height: 12),
          _buildImpactCards(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: AppTextStyles.headlineMedium),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DonationHistoryScreen(),
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildRecentActivity(),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              UserAvatar(
                avatarUrl: user.avatarUrl,
                name: user.name,
                size: 88,
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user.name, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${user.isVerified ? 'Verified ' : ''}${user.role.toLowerCase() == 'komunitas' ? 'Komunitas' : 'Donatur'}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.bio ?? '',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AccountSettingsScreen(user: user),
                  ),
                );

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTextStyles.buttonMedium,
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      _QuickLink(
        icon: Icons.history_rounded,
        label: 'Riwayat Donasi',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DonationHistoryScreen(),
          ),
        ),
      ),
      _QuickLink(
        icon: Icons.favorite_outline_rounded,
        label: 'Aktivitas Anda',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UserActivityScreen(),
          ),
        ),
      ),
      _QuickLink(
        icon: Icons.manage_accounts_outlined,
        label: 'Pengaturan Akun',
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountSettingsScreen(user: user),
            ),
          );
          if (result == true) {
            // Trigger parent ProfileScreen to reload
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengaturan akun disimpan')),
            );
          }
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Quick Links',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...List.generate(links.length, (i) {
            final link = links[i];
            return Column(
              children: [
                ListTile(
                  leading: Icon(link.icon, color: AppColors.primary, size: 22),
                  title: Text(link.label, style: AppTextStyles.titleSmall),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onTap: link.onTap,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                ),
                if (i < links.length - 1)
                  const Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: AppColors.divider,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImpactCards() {
    // Untuk komunitas: donationCount = titik yang dibuat, communityPoints = poin dari membuat titik
    // Untuk donatur: donationCount = rating yang diberikan, communityPoints = poin dari rating
    final isKomunitas = user.role.toLowerCase() == 'komunitas';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ImpactCard(
            icon: Icons.local_shipping_outlined,
            label: 'Point Helped',
            value: '\${user.pointsHelped}',
            sub: isKomunitas
                ? 'Jumlah titik yang berhasil dibantu'
                : 'Titik yang telah Anda bantu',
            iconColor: const Color(0xFF1565C0),
            iconBg: const Color(0xFFE3F2FD),
          ),
          const SizedBox(height: 12),
          _ImpactCard(
            icon: Icons.emoji_events_outlined,
            label: 'Poin ${isKomunitas ? "Komunitas" : "Donatur"}',
            value: '${user.communityPoints}',
            sub: isKomunitas
                ? 'Poin dari membuat titik & donasi'
                : 'Poin dari memberikan rating',
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final repo = DonationRepository();
    return FutureBuilder<List<ActivityItem>>(
      future: repo.getUserActivity(limit: 2),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Gagal memuat aktivitas. Mohon coba lagi.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Text(
                'Belum ada aktivitas terbaru. Silakan ulangi lagi nanti.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: List.generate(activities.length, (i) {
                final item = activities[i];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _activityIconBackground(item.iconType),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _activityIconData(item.iconType),
                              color: _activityIconColor(item.iconType),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: AppTextStyles.titleSmall),
                                const SizedBox(height: 2),
                                if (item.subtitle.isNotEmpty)
                                  Text(item.subtitle,
                                      style: AppTextStyles.bodySmall),
                                const SizedBox(height: 6),
                                Text(item.timeAgo,
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 1, color: AppColors.divider),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  IconData _activityIconData(String type) {
    return switch (type) {
      'success' => Icons.check_circle_outline_rounded,
      'donation' => Icons.favorite_outline_rounded,
      'participant_accepted' => Icons.people_outline_rounded,
      _ => Icons.campaign_rounded,
    };
  }

  Color _activityIconBackground(String type) {
    return switch (type) {
      'success' => AppColors.statusCompletedLight,
      'donation' => AppColors.urgencyHighLight,
      'participant_accepted' => AppColors.primaryContainer,
      _ => AppColors.urgencyMediumLight,
    };
  }

  Color _activityIconColor(String type) {
    return switch (type) {
      'success' => AppColors.statusCompleted,
      'donation' => AppColors.urgencyHigh,
      'participant_accepted' => AppColors.primary,
      _ => AppColors.urgencyMedium,
    };
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () => onLogout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Logout',
            style: AppTextStyles.buttonMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color iconColor;
  final Color iconBg;

  const _ImpactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: AppTextStyles.captionUppercase),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(sub, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
