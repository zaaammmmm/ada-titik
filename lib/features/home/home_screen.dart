// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../donation/active_requests_screen.dart';
import '../donation/request_detail_screen.dart';
import '../donation/data/donation_repository.dart';
import '../notification/notification_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = DonationRepository();

    return FutureBuilder<UserModel>(
      future: repo.getProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text('Failed to load profile'),
            ),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AdaTitikAppBar(
            onNotification: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                AppSearchBar(
                  hint: 'Search for aid requests, categories...',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildGreeting(user),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 12),
                _buildActiveRequestBanner(context),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Kebutuhan Mendesak',
                  actionLabel: 'View All',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveRequestsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildUrgentCarousel(context),
                const SizedBox(height: 24),
                Text(
                  'Aktivitas Terbaru',
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 12),
                _buildActivityList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${user.name}!',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Your kindness creates ripples. Ready to make an impact today?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.favorite_rounded,
            number: '12',
            label: 'DONATIONS SENT',
            color: AppColors.statsTeal,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.location_on_rounded,
            number: '8',
            label: 'POINTS HELPED',
            color: AppColors.statsLavender,
            textColor: AppColors.textPrimary,
            iconColor: AppColors.statsBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRequestBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveRequestsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Request', style: AppTextStyles.titleMedium),
                  Text(
                    'Find active points around you',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentCarousel(BuildContext context) {
    return SizedBox(
      height: 240,
      child: FutureBuilder<List<DonationRequest>>(
        future: DonationRepository().getAll(
          status: RequestStatus.open,
          page: 1,
          limit: 20,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load requests',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];
          final urgent = all.where((r) => r.urgency == UrgencyLevel.urgent);
          final normal = all.where((r) => r.urgency != UrgencyLevel.urgent);
          final ordered = [...urgent, ...normal].toList();

          if (ordered.isEmpty) {
            return Center(
              child: Text(
                'No active requests',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final req = ordered[index];
              return _UrgentCard(
                request: req,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(request: req),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityList() {
    // Step 3: belum ada endpoint activity di Postman yang jelas untuk UI ini,
    // jadi sementara tampilkan placeholder agar tidak pakai MockData.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aktivitas Terbaru', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Coming soon: aktivitas dari backend.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;
  final Color color;
  final Color textColor;
  final Color? iconColor;

  const _StatsCard({
    required this.icon,
    required this.number,
    required this.label,
    required this.color,
    required this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? textColor.withOpacity(0.8), size: 22),
          const SizedBox(height: 8),
          Text(
            number,
            style: AppTextStyles.headlineLarge.copyWith(
              color: textColor,
              fontSize: 28,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.captionUppercase.copyWith(
              color: textColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  final DonationRequest request;
  final VoidCallback onTap;
  const _UrgentCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    color: AppColors.primaryContainer,
                    child: request.imageUrl != null
                        ? Image.network(
                            request.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                  if (request.urgency == UrgencyLevel.urgent)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.urgencyHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Urgent',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  DonationProgressBar(
                    collected: request.collectedAmount,
                    goal: request.goalAmount,
                    collectedLabel:
                        'Terkumpul: Rp ${_fmt(request.collectedAmount)}',
                    goalLabel: 'Target: Rp ${_fmt(request.goalAmount)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.primaryContainer,
      child: const Center(
        child: Icon(
          Icons.volunteer_activism_rounded,
          color: AppColors.primary,
          size: 36,
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (activity.iconType) {
      'success' => (
          Icons.check_circle_rounded,
          AppColors.statusCompletedLight,
          AppColors.statusCompleted,
        ),
      'donation' => (
          Icons.favorite_rounded,
          AppColors.urgencyHighLight,
          AppColors.urgencyHigh,
        ),
      _ => (
          Icons.campaign_rounded,
          AppColors.urgencyMediumLight,
          AppColors.urgencyMedium,
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 3,
                ),
                const SizedBox(height: 2),
                Text(activity.timeAgo, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
