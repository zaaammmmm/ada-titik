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
import '../news/news_detail_screen.dart';
import '../news/data/news_repository.dart';
import '../news/data/news_model.dart' as news_models;

import '../notification/notification_screen.dart';
import '../notification/data/notification_repository.dart';
import 'dart:math' as math;
import '../../core/services/supabase_realtime_service.dart';
import '../../core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../search/search_screen.dart';

import 'package:url_launcher/url_launcher.dart';

/// Callback opsional agar MainScaffold bisa listen event dari HomeScreen
typedef VoidCallback = void Function();

class HomeScreen extends StatefulWidget {
  final VoidCallback? onRefreshUnread;
  const HomeScreen({super.key, this.onRefreshUnread});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final DonationRepository _repo = const DonationRepository();

  late Future<UserModel> _profileFuture;
  late Future<List<DonationRequest>> _urgentFuture;
  late Future<_HomeStats> _statsFuture;
  int _unreadNotifCount = 0;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repo.getProfile();
    _urgentFuture = _fetchUrgentRequests();
    _statsFuture = _fetchStats();
    WidgetsBinding.instance.addObserver(this);
    _subscribeRealtime();
    _loadUnreadCount();
    _loadUserPosition();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifRepo = const NotificationRepository();
      final notifs = await notifRepo.getUserNotifications(
          page: 1, limit: 50, unread: true);
      if (mounted) setState(() => _unreadNotifCount = notifs.length);
    } catch (_) {}
  }

  Future<void> _loadUserPosition() async {
    final pos = await LocationService.instance.getCurrentPosition();
    if (mounted && pos != null) {
      setState(() {
        _userPosition = pos;
        // Re-compute urgent list with new position
        _urgentFuture = _fetchUrgentRequests();
      });
    }
  }

  final SupabaseRealtimeService _realtimeNotif = SupabaseRealtimeService();

  void _subscribeRealtime() {
    // Subscribe donation points - refresh card urgent
    final supabase = SupabaseRealtimeService();
    supabase.subscribeToDonationPoints(onUpdate: () {
      if (mounted) _refreshHome();
    });

    // Subscribe notification insert - refresh unread badge + stats realtime
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Re-read current userId from shared pref / auth (not riverpod here)
      // We'll use a lightweight approach: subscribe after init
      _subscribeNotifRealtime();
    });
  }

  void _subscribeNotifRealtime() async {
    try {
      // Read userId from the profile we already loaded
      final profile = await _profileFuture.catchError((_) => throw Exception());
      final userId = profile.id;
      if (userId.isEmpty) return;

      await _realtimeNotif.subscribeToNotifications(
        currentUserId: userId,
        onInsert: (_) {
          if (mounted) {
            _loadUnreadCount();
            // Also refresh stats as activity may have changed
            setState(() => _statsFuture = _fetchStats());
          }
        },
      );
    } catch (_) {}
  }

  Future<void> _refreshHome() async {
    if (!mounted) return;
    setState(() {
      _urgentFuture = _fetchUrgentRequests();
    });
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _profileFuture = _repo.getProfile();
      _urgentFuture = _fetchUrgentRequests();
      _statsFuture = _fetchStats();
    });
    _loadUnreadCount();
    // Re-load user position to ensure distance labels are fresh
    _loadUserPosition();
  }

  /// Statistik dari DATA ASLI backend (bukan mengarang poin via string-matching).
  /// Poin = users.points (GET /api/users/points); jumlah aktivitas =
  /// pagination.total (GET /api/users/activity).
  Future<_HomeStats> _fetchStats() async {
    try {
      final results = await Future.wait([
        _repo.getMyPointsTotal(),
        _repo.getActivityTotal(),
      ]);
      return _HomeStats(
        activityCount: results[1],
        earnedPoints: results[0],
      );
    } catch (_) {
      return const _HomeStats(activityCount: 0, earnedPoints: 0);
    }
  }

  Future<List<DonationRequest>> _fetchUrgentRequests() async {
    final openFuture =
        _repo.getAll(status: RequestStatus.open, page: 1, limit: 50);
    final onProgressFuture =
        _repo.getAll(status: RequestStatus.onProgress, page: 1, limit: 50);
    final results = await Future.wait([openFuture, onProgressFuture]);
    final combined = <String, DonationRequest>{};
    for (final list in results) {
      for (final r in list) {
        combined[r.id] = r;
      }
    }

    var items =
        combined.values.where((r) => r.urgency == UrgencyLevel.urgent).toList();

    final pos = _userPosition;
    if (pos != null) {
      items = items.map((req) {
        if (req.distanceKm <= 0) {
          final dMeters = _haversineMeters(
            pos.latitude,
            pos.longitude,
            req.latitude,
            req.longitude,
          );
          return DonationRequest(
            id: req.id,
            title: req.title,
            description: req.description,
            authorName: req.authorName,
            authorAvatar: req.authorAvatar,
            createdById: req.createdById,
            urgency: req.urgency,
            status: req.status,
            category: req.category,
            location: req.location,
            latitude: req.latitude,
            longitude: req.longitude,
            timeAgo: req.timeAgo,
            imageUrl: req.imageUrl,
            goalAmount: req.goalAmount,
            collectedAmount: req.collectedAmount,
            tags: req.tags,
            goalText: req.goalText,
            avgRating: req.avgRating,
            distanceKm: dMeters / 1000.0,
            goalUnit: req.goalUnit,
          );
        }
        return req;
      }).toList();
    }

    items.sort((a, b) {
      final aKm = a.distanceKm > 0 ? a.distanceKm : double.maxFinite;
      final bKm = b.distanceKm > 0 ? b.distanceKm : double.maxFinite;
      return aKm.compareTo(bKm);
    });

    return items;
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  @override
  void dispose() {
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
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Gagal memuat profil')),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AdaTitikAppBar(
            title: 'Beranda',
            unreadNotifCount: _unreadNotifCount,
            onNotification: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationScreen(),
                ),
              );
              _loadUnreadCount();
            },
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
                    hint: 'Cari titik bantuan, kategori, lokasi…',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
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
                    actionLabel: 'Lihat Semua',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ActiveRequestsScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildUrgentCarousel(context),
                  const SizedBox(height: 24),
                  _buildArticlesSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(UserModel user) {
    final firstName = user.name.trim().split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Halo, $firstName!', style: AppTextStyles.displayMedium),
        const SizedBox(height: 4),
        // Subtitle data-driven: jumlah titik mendesak di sekitar (lebih hidup
        // & relevan daripada kalimat motivasi generik).
        FutureBuilder<List<DonationRequest>>(
          future: _urgentFuture,
          builder: (context, snapshot) {
            final n = snapshot.data?.length ?? 0;
            final text = n > 0
                ? 'Ada $n titik mendesak di dekatmu hari ini. Yuk bantu 🤝'
                : 'Yuk lihat siapa yang butuh bantuan di sekitarmu hari ini.';
            return Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<_HomeStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            const _HomeStats(activityCount: 0, earnedPoints: 0);
        return Row(
          children: [
            Expanded(
              child: _StatsCard(
                icon: Icons.local_activity_rounded,
                number: stats.activityCount.toString(),
                label: 'AKTIVITAS',
                color: AppColors.statsTeal,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatsCard(
                icon: Icons.stars_rounded,
                number: stats.earnedPoints.toString(),
                label: 'POIN DIPEROLEH',
                color: AppColors.statsLavender,
                textColor: AppColors.textPrimary,
                iconColor: AppColors.statsBlue,
              ),
            ),
          ],
        );
      },
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
      height: 260,
      child: FutureBuilder<List<DonationRequest>>(
        future: _urgentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat kebutuhan mendesak',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final ordered = snapshot.data ?? [];
          if (ordered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_rounded,
                      color: AppColors.primary.withOpacity(0.7), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Semua aman untuk saat ini 🌱',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Belum ada kebutuhan mendesak di sekitarmu.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ordered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final req = ordered[index];
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _repo.getDocumentation(req.id),
                builder: (context, docsSnap) {
                  final coverUrl = docsSnap.data?.isNotEmpty == true
                      ? (docsSnap.data!.first['photo_url']?.toString() ?? '')
                      : null;

                  return _UrgentCard(
                    request: req,
                    coverImageUrl: coverUrl,
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
          );
        },
      ),
    );
  }

  Widget _buildArticlesSection() {
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
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
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
                onDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(
                        item: news_models.NewsItem(
                      title: article.title,
                      subtitle: article.subtitle,
                      content: article.content,
                      url: article.url,
                      category: article.category,
                      icon: article.icon,
                    )),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Data class untuk stats di home screen
class _HomeStats {
  final int activityCount;
  final int earnedPoints;
  const _HomeStats({required this.activityCount, required this.earnedPoints});
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
  final String? coverImageUrl;

  const _UrgentCard({
    required this.request,
    required this.onTap,
    this.coverImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.urgencyHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Urgent',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white),
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
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.primary),
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
                  if (request.distanceKm > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${request.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  DonationProgressBar(
                    collected: request.collectedAmount,
                    goal: request.goalAmount,
                    collectedLabel:
                        _inferUnitFromCategory(request.category) == 'Kg'
                            ? '${_fmt(request.collectedAmount)} Kg'
                            : 'Rp ${_fmt(request.collectedAmount)}',
                    goalLabel: _inferUnitFromCategory(request.category) == 'Kg'
                        ? 'Target: ${_fmt(request.goalAmount)} Kg'
                        : 'Target: Rp ${_fmt(request.goalAmount)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Samakan sumber thumbnail dengan RequestDetail docs:
    // docs[i]['photo_url'] -> coverImageUrl
    final imageToShow =
        coverImageUrl?.isNotEmpty == true ? coverImageUrl! : null;

    if (imageToShow != null) {
      return Image.network(
        imageToShow,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    return _placeholderImage();
  }

  Widget _placeholderImage() {
    // Use category-based icon instead of heart/hand
    final icon = _categoryIcon(request.category);
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 4),
            Text(
              request.category,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') ||
        cat.contains('water') ||
        cat.contains('makanan')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('health') ||
        cat.contains('medis') ||
        cat.contains('kesehatan')) {
      return Icons.local_hospital_rounded;
    } else if (cat.contains('cloth') || cat.contains('pakaian')) {
      return Icons.checkroom_rounded;
    } else if (cat.contains('education') || cat.contains('pendidikan')) {
      return Icons.school_rounded;
    } else if (cat.contains('shelter') || cat.contains('rumah')) {
      return Icons.home_rounded;
    } else {
      return Icons.inventory_2_rounded;
    }
  }

  String _inferUnitFromCategory(String category) {
    // Heuristik berbasis kategori UI (backend tidak menyimpan unit kg/rp).
    // Gunakan kategori yang ada untuk memperkirakan unit.
    final c = category.toLowerCase().trim();
    // Makanan/air, medis seringnya lebih masuk akal pakai Kg.
    if (c.contains('pangan') ||
        c.contains('medis') ||
        c.contains('pakaian') == false &&
            (c.contains('makanan') ||
                c.contains('water') ||
                c.contains('food'))) {
      return 'Kg';
    }
    // Selebihnya default Rp.
    return 'Rp';
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
  final VoidCallback? onDetail;
  const _ArticleCard({required this.article, this.onDetail});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetail ??
          () async {
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
                GestureDetector(
                  onTap: onDetail,
                  child: Row(
                    children: [
                      Text(
                        'Baca selengkapnya',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_rounded,
                          color: AppColors.primary, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
