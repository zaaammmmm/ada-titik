// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/mock_data.dart';
import '../../shared/models/models.dart';
import '../donation/donation_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context, user),
            const SizedBox(height: 12),
            _buildQuickLinks(context),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Your Impact', style: AppTextStyles.headlineMedium),
            ),
            const SizedBox(height: 12),
            _buildImpactCards(user),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Activity', style: AppTextStyles.headlineMedium),
                  TextButton(
                    onPressed: () {},
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
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: const NetworkImage(
            'https://i.pravatar.cc/150?img=12',
          ),
          backgroundColor: AppColors.primaryContainer,
        ),
      ),
      title: Text(
        'Ada Titik?',
        style: AppTextStyles.brandTitle.copyWith(fontSize: 22),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textPrimary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel user) {
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
              CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(
                  user.avatarUrl ?? 'https://i.pravatar.cc/150?img=12',
                ),
                backgroundColor: AppColors.primaryContainer,
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
                'Verified Member',
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
              onPressed: () {},
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
          MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
        ),
      ),
      _QuickLink(
        icon: Icons.favorite_outline_rounded,
        label: 'Daftar Keinginan',
        onTap: () {},
      ),
      _QuickLink(
        icon: Icons.manage_accounts_outlined,
        label: 'Pengaturan Akun',
        onTap: () {},
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

  Widget _buildImpactCards(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ImpactCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total Donasi',
            value: 'Rp 2.5M',
            sub: 'Lifetime contribution',
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryContainer,
          ),
          const SizedBox(height: 12),
          _ImpactCard(
            icon: Icons.local_shipping_outlined,
            label: 'Bantuan Disalurkan',
            value: '${user.donationCount}',
            sub: 'Successful deliveries',
            iconColor: const Color(0xFF1565C0),
            iconBg: const Color(0xFFE3F2FD),
          ),
          const SizedBox(height: 12),
          _ImpactCard(
            icon: Icons.emoji_events_outlined,
            label: 'Poin Komunitas',
            value: '${user.communityPoints}',
            sub: 'Top 15% Contributor',
            iconColor: AppColors.textSecondary,
            iconBg: AppColors.surfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final items = [
      _ActivityEntry(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFFFF8E1),
        iconColor: AppColors.urgencyMedium,
        title: 'Paket Sembako Keluarga Harapan',
        subtitle: 'Donasi Barang · Menunggu Penjemputan',
        status: 'On Progress',
        statusColor: AppColors.statusProgress,
        statusBg: AppColors.statusProgressLight,
        date: 'Today, 09:45 AM',
      ),
      _ActivityEntry(
        icon: Icons.check_circle_outline_rounded,
        iconBg: AppColors.urgencyLowLight,
        iconColor: AppColors.urgencyLow,
        title: 'Bantuan Tunai Pendidikan SD Mawar',
        subtitle: 'Donasi Dana · Rp 500.000',
        status: 'Completed',
        statusColor: AppColors.statusCompleted,
        statusBg: AppColors.statusCompletedLight,
        date: 'Oct 12, 2023',
      ),
      _ActivityEntry(
        icon: Icons.volunteer_activism_outlined,
        iconBg: AppColors.primaryContainer,
        iconColor: AppColors.primary,
        title: 'Relawan Dapur Umum Banjir Bandang',
        subtitle: 'Partisipasi Tenaga · 8 Jam',
        status: 'Completed',
        statusColor: AppColors.statusCompleted,
        statusBg: AppColors.statusCompletedLight,
        date: 'Sep 28, 2023',
      ),
    ];

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
          children: List.generate(items.length, (i) {
            final item = items[i];
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
                          color: item.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: item.statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.date,
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            );
          }),
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
                    Text(
                      label,
                      style: AppTextStyles.captionUppercase,
                    ),
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

class _ActivityEntry {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String date;

  const _ActivityEntry({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.date,
  });
}
