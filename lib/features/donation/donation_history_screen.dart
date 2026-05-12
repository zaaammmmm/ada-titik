// lib/features/donation/donation_history_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<List<ActivityItem>> _activityFuture;
  final DonationRepository _repo = DonationRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activityFuture = _repo.getUserActivity(limit: 10);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Riwayat Donasi', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Donasi Saya'),
            Tab(text: 'Kelola Bantuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonationsTab(),
          _buildKelolaBantuanTab(),
        ],
      ),
    );
  }

  Widget _buildDonationsTab() {
    return FutureBuilder<List<ActivityItem>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat riwayat donasi.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Center(
            child: Text(
              'Belum ada riwayat donasi.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _buildActivityCard(activities[i]),
        );
      },
    );
  }

  Widget _buildDonationCard({
    required String title,
    required String amount,
    required String date,
    required RequestStatus status,
    required String category,
  }) {
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildKelolaBantuanTab() {
    return FutureBuilder<List<ActivityItem>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat riwayat bantuan.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Center(
            child: Text(
              'Belum ada riwayat bantuan.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _buildActivityCard(activities[i]),
        );
      },
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _activityIconBackground(activity.iconType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _activityIconData(activity.iconType),
              color: _activityIconColor(activity.iconType),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: AppTextStyles.titleSmall),
                if (activity.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(activity.subtitle, style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 8),
                Text(activity.timeAgo, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIconData(String type) {
    return switch (type) {
      'success' => Icons.check_circle_rounded,
      'donation' => Icons.favorite_rounded,
      _ => Icons.campaign_rounded,
    };
  }

  Color _activityIconBackground(String type) {
    return switch (type) {
      'success' => AppColors.statusCompletedLight,
      'donation' => AppColors.urgencyHighLight,
      _ => AppColors.urgencyMediumLight,
    };
  }

  Color _activityIconColor(String type) {
    return switch (type) {
      'success' => AppColors.statusCompleted,
      'donation' => AppColors.urgencyHigh,
      _ => AppColors.urgencyMedium,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    IconData? icon;

    switch (status) {
      case RequestStatus.open:
        color = AppColors.statusOpen;
        bg = AppColors.statusOpenLight;
        label = 'Open';
        icon = null;
        break;
      case RequestStatus.onProgress:
        color = AppColors.statusProgress;
        bg = AppColors.statusProgressLight;
        label = 'In Progress';
        icon = Icons.sync_rounded;
        break;
      case RequestStatus.completed:
        color = AppColors.statusCompleted;
        bg = AppColors.statusCompletedLight;
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
