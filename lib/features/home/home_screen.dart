// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../donation/active_requests_screen.dart';
import '../donation/request_detail_screen.dart';
import '../donation/data/donation_repository.dart';
import '../maps/maps_screen.dart';
import '../news/news_screen.dart';
import '../news/data/news_repository.dart';

import '../notification/notification_screen.dart';
import '../search/search_screen.dart';

import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final DonationRepository _repo = const DonationRepository();

  late Future<UserModel> _profileFuture;
  late Future<List<DonationRequest>> _urgentFuture;
  late Future<List<ActivityItem>> _activityFuture;
  Timer? _autoRefreshTimer;
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repo.getProfile();
    _urgentFuture = _repo.getAll(
      status: RequestStatus.open,
      page: 1,
      limit: 20,
    );
    _activityFuture = _repo.getUserActivity(limit: 4);
    WidgetsBinding.instance.addObserver(this);
    // ✨ TODO L: Autorefresh setiap 60 detik (tidak agresif, hemat rate limit)
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_appInForeground && mounted) _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    setState(() {
      _profileFuture = _repo.getProfile();
      _urgentFuture = _repo.getAll(
        status: RequestStatus.open,
        page: 1,
        limit: 20,
      );
      _activityFuture = _repo.getUserActivity(limit: 4);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<UserModel>(
      future: _profileFuture,
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
            title: 'Beranda',
            onNotification: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const AlwaysScrollableScrollPhysics(),
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
                  _buildStatsRow(user),
                  const SizedBox(height: 12),
                  _buildActiveRequestBanner(context),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Kebutuhan Mendesak',
                    actionLabel: 'Lihat Semua',
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
                  _buildArticlesSection(),
                  const SizedBox(height: 24),

                  // Text(
                  //   'Aktivitas Terbaru',
                  //   style: AppTextStyles.headlineMedium,
                  // ),
                  // const SizedBox(height: 12),
                  // _buildActivityList(),
                  // const SizedBox(height: 24),
                ],
              ),
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
          'Halo, ${user.name}!',
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Keramahan Anda menciptakan gelombang. Siap membuat dampak hari ini?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _StatsCard(
            icon: Icons.favorite_rounded,
            number: user.donationCount.toString(),
            label: 'ACTIVITY COUNT',
            color: AppColors.statsTeal,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatsCard(
            icon: Icons.location_on_rounded,
            number: user.pointsHelped.toString(),
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
        MaterialPageRoute(builder: (_) => const MapsScreen()),
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
                  Text('Map Donasi', style: AppTextStyles.titleMedium),
                  Text(
                    'Temukan titik-titik aktif di sekitar Anda',
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
        future: _urgentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Debug: Tampilkan error detail
            debugPrint('Error loading urgent requests: ${snapshot.error}');
            return Center(
              child: Text(
                'Gagal memuat kebutuhan mendesak',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];

          // ✅ Filter prioritas: Urgent terlebih dahulu, kemudian Normal, kemudian Rendah
          final urgent =
              all.where((r) => r.urgency == UrgencyLevel.urgent).toList();
          final normal =
              all.where((r) => r.urgency == UrgencyLevel.normal).toList();
          final low = all.where((r) => r.urgency == UrgencyLevel.low).toList();

          // Sort setiap kategori berdasarkan tanggal terbaru (untuk menampilkan komunitas terbaru)
          urgent.sort((a, b) => b.timeAgo.compareTo(a.timeAgo));
          normal.sort((a, b) => b.timeAgo.compareTo(a.timeAgo));
          low.sort((a, b) => b.timeAgo.compareTo(a.timeAgo));

          final ordered = [...urgent, ...normal, ...low].toList();

          if (ordered.isEmpty) {
            return Center(
              child: Text(
                'Belum ada kebutuhan mendesak',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          debugPrint(
              'Tampilkan ${ordered.length} kebutuhan (${urgent.length} urgent)');

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final req = ordered[index];
              // Debug: Print image URL untuk verifikasi
              debugPrint(
                  'Card ${index}: ${req.title} - Image: ${req.imageUrl}');
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
    return FutureBuilder<List<ActivityItem>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gagal memuat aktivitas. Silakan coba lagi.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'Belum ada aktivitas terbaru. Silakan ulangi lagi nanti.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

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
              Text('', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              ...List.generate(activities.length, (i) {
                final activity = activities[i];
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _activityIconBackground(activity.iconType),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _activityIconData(activity.iconType),
                            color: _activityIconColor(activity.iconType),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(activity.title,
                                  style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 2),
                              Text(
                                activity.timeAgo,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 20, color: Colors.transparent),
                  ],
                );
              }),
            ],
          ),
        );
      },
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

  Widget _buildArticlesSection() {
    // Ambil dari repository berita (statik open-source links)
    final all = const NewsRepository().getAll();
    final show = all.take(6).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Berita',
          actionLabel: 'Lihat Semua',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: show.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final article = show[i];
              return _ArticleCard(
                article: _ArticleItem(
                  title: article.title,
                  subtitle: article.subtitle,
                  url: article.url,
                  icon: article.icon,
                ),
              );
            },
          ),
        ),
      ],
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
            // Image - dengan handling lebih baik untuk error dan loading
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
                    child: _buildImageWidget(),
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

  // ✅ Improved image widget dengan better error handling
  Widget _buildImageWidget() {
    if (request.imageUrl != null && request.imageUrl!.isNotEmpty) {
      return Image.network(
        request.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image error for ${request.title}: $error');
          return _placeholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
    return _placeholderImage();
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

class _ArticleItem {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;

  const _ArticleItem({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
  });
}

class _ArticleCard extends StatelessWidget {
  final _ArticleItem article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(article.icon, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ARTIKEL',
                    style: AppTextStyles.captionUppercase.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: AppTextStyles.titleSmall.copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Baca selengkapnya',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
