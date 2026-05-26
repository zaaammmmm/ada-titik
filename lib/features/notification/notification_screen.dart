// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/location_service.dart';

import 'dart:async';

import '../../features/donation/request_detail_screen.dart';
import '../../shared/models/models.dart';

import 'data/notification_repository.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {
  late final NotificationRepository _repo;
  late Future<List<NotificationItem>> _future;

  Timer? _timer;
  bool _appInForeground = true;

  // mapping tipe event (string dari NotificationType.name) -> iconType (untuk UI)
  String _mapNotificationType(String raw) {
    switch (raw.toLowerCase()) {
      case 'like':
        return 'favorite';
      case 'comment':
        return 'comment';
      case 'statusupdate':
      case 'status_update':
        return 'warning';
      case 'commentreply':
      case 'comment_reply':
        return 'comment';
      default:
        return 'nearby_donation';
    }
  }

  // keep UI model sederhana (NotificationItem), karena response v3 belum selalu kirim read flag
  final ScrollController _scrollController = ScrollController();

  List<NotificationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _repo = const NotificationRepository();

    _future = _loadNotifications();

    // Auto-refresh notifikasi (lebih realtime)
    _timer = Timer.periodic(const Duration(seconds: 90), (_) async {
      if (!_appInForeground || !mounted) return;
      final loaded = await _loadNotifications();
      if (!mounted) return;
      setState(() {
        _items = loaded;
      });
    });

    _future.then((loaded) {
      if (!mounted) return;
      setState(() => _items = loaded);
    });
  }

  // ✅ FIXED: dapatkan koordinat GPS user yang aktual, bukan hardcoded Yogyakarta
  // ✅ FIXED: mapping field sesuai response v3 (content = judul titik, bukan authorName)
  Future<List<NotificationItem>> _loadNotifications() async {
    // Coba ambil posisi GPS user aktual
    double lat = LocationService.defaultCenter.latitude;
    double lng = LocationService.defaultCenter.longitude;

    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      lat = pos.latitude;
      lng = pos.longitude;
    }

    final posts = await _repo.getNearbyNotifications(
      lat: lat,
      lng: lng,
      limit: 10,
    );

    return posts
        .map((n) => NotificationItem(
              id: n.id,
              title: n.title,
              subtitle: n.subtitle,
              time: n.createdAt.toString(),
              unread: true,
              iconType: _mapNotificationType(n.type.name),
              pointId: n.payload?['pointId']?.toString() ??
                  n.payload?['point_id']?.toString(),
              postId: n.payload?['postId']?.toString() ??
                  n.payload?['post_id']?.toString(),
            ))
        .toList();
  }

  void _markAllAsRead() {
    setState(() {
      _items = _items
          .map((e) => NotificationItem(
                id: e.id,
                title: e.title,
                subtitle: e.subtitle,
                time: e.time,
                unread: false,
                iconType: e.iconType,
              ))
          .toList();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        title: Text('Notifikasi', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Tandai Semua',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gagal memuat notifikasi.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications =
              _items.isNotEmpty ? _items : (snapshot.data ?? []);
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tidak ada notifikasi terbaru di sekitar Anda.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  // Deep-link sesuai payload (pointId/postId).
                  // Jika backend mengirim payload pointId, kita arahkan ke detail titik.
                  if (item.pointId != null && item.pointId!.isNotEmpty) {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(
                          // RequestDetailScreen butuh model DonationRequest.
                          // Karena NotificationItem tidak menyertakan semua field, sementara fallback
                          // navigasi dilakukan ke route dengan placeholder (mengandalkan reload di screen).
                          request: DonationRequest(
                            id: item.pointId!,
                            title: item.subtitle,
                            description: '',
                            authorName: '',
                            urgency: UrgencyLevel.normal,
                            status: RequestStatus.open,
                            category: 'Umum',
                            location: '',
                            timeAgo: '',
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  // Jika payload hanya postId, buka comments screen (jika tersedia di project).
                  if (item.postId != null && item.postId!.isNotEmpty) {
                    // Fitur ini opsional karena CommentsScreen butuh int postId.
                  }
                },
                child: _buildNotifItem(
                  icon: _iconForType(item.iconType),
                  iconBg: _bgForType(item.iconType),
                  iconColor: _colorForType(item.iconType),
                  title: item.title,
                  subtitle: item.subtitle,
                  time: item.time,
                  isUnread: item.unread,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'bantuanDibutuhkan' => Icons.location_on_rounded,
      'pertanyaan' => Icons.question_mark_rounded,
      'updateKomunitas' => Icons.campaign_rounded,
      'inspirasi' => Icons.lightbulb_outline_rounded,
      'kisahSukses' => Icons.check_circle_rounded,
      _ => Icons.notifications_outlined,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'bantuanDibutuhkan' => AppColors.urgencyHigh,
      'pertanyaan' => const Color(0xFF1565C0),
      'updateKomunitas' => AppColors.primary,
      'inspirasi' => AppColors.urgencyMedium,
      'kisahSukses' => AppColors.statusCompleted,
      _ => AppColors.primary,
    };
  }

  Color _bgForType(String type) {
    return switch (type) {
      'bantuanDibutuhkan' => AppColors.urgencyHighLight,
      'pertanyaan' => const Color(0xFFE3F2FD),
      'updateKomunitas' => AppColors.primaryContainer,
      'inspirasi' => AppColors.urgencyMediumLight,
      'kisahSukses' => AppColors.statusCompletedLight,
      _ => AppColors.primaryContainer,
    };
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      color: isUnread ? AppColors.primaryContainer.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;
  final String iconType;

  /// Deep link
  final String? pointId;
  final String? postId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.iconType,
    this.pointId,
    this.postId,
  });
}
