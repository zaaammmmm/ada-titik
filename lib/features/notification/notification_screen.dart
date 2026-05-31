// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'dart:async';

import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_realtime_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/donation/request_detail_screen.dart';
import '../../features/donation/departure_review_screen.dart';
import '../../features/community/comments_screen.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/donation/data/donation_repository.dart';

import '../../shared/models/models.dart';

import 'data/notification_repository.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with WidgetsBindingObserver {
  late final NotificationRepository _repo;
  late Future<List<NotificationItem>> _future;

  Timer? _timer;
  bool _appInForeground = true;

  String _mapNotificationType(String raw) {
    switch (raw.toLowerCase()) {
      case 'donator_departed':
        return 'departure';
      case 'participant_accepted':
        return 'accepted';
      case 'participant_completed':
        return 'completed';
      case 'progress_updated':
      case 'urgency_changed':
        return 'warning';
      case 'post_liked':
        return 'favorite';
      case 'post_commented':
        return 'comment';
      default:
        return 'nearby_donation';
    }
  }

  final ScrollController _scrollController = ScrollController();
  List<NotificationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _repo = const NotificationRepository();

    // Load ALL notifications (bukan hanya unread) agar notifikasi tidak hilang
    _future = _loadNotifications();

    // Polling setiap 30 detik
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_appInForeground || !mounted) return;
      final loaded = await _loadNotifications();
      if (!mounted) return;
      setState(() => _items = loaded);
    });

    _future.then((loaded) {
      if (!mounted) return;
      setState(() => _items = loaded);
    });

    // Realtime insert notifications (Supabase)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null || userId.isEmpty) return;

      final realtime = SupabaseRealtimeService();
      await realtime.subscribeToNotifications(
        currentUserId: userId,
        onInsert: (payload) {
          if (!mounted) return;
          final mapped = _mapNotificationItemFromRealtime(payload);
          if (mapped == null) return;

          setState(() {
            final existingIdx = _items.indexWhere((e) => e.id == mapped.id);
            if (existingIdx >= 0) {
              _items = [
                ..._items.sublist(0, existingIdx),
                mapped,
                ..._items.sublist(existingIdx + 1),
              ];
            } else {
              _items = [mapped, ..._items];
            }
          });
        },
      );
    });
  }

  /// Load ALL notifications — read dan unread — agar tidak ada yang menghilang.
  Future<List<NotificationItem>> _loadNotifications() async {
    final notifications = await _repo.getUserNotifications(
      page: 1,
      limit: 50,
      unread: false, // ambil semua, bukan hanya unread
    );

    return notifications
        .map((n) => NotificationItem(
              id: n.id,
              title: n.title,
              subtitle: n.subtitle,
              time: n.createdAt.toString(),
              unread: !n.read,
              iconType: _mapNotificationType(n.type.name),
              rawType: n.type.name,
              pointId: n.payload?['point_id']?.toString() ??
                  n.payload?['pointId']?.toString() ??
                  n.payload?['point']?.toString(),
              postId: n.payload?['post_id']?.toString() ??
                  n.payload?['postId']?.toString(),
            ))
        .toList();
  }

  NotificationItem? _mapNotificationItemFromRealtime(
      Map<String, dynamic> item) {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final typeStr = item['type']?.toString() ?? '';
    final mappedType = _mapNotificationType(typeStr);

    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString();
    final subtitle =
        body?.isNotEmpty == true ? body! : (item['subtitle']?.toString() ?? '');

    final createdAtRaw = item['created_at']?.toString();
    final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();

    final readAt = item['read_at'];
    final isRead = readAt != null;

    final payloadRaw = item['payload'];
    final payload = payloadRaw is Map<String, dynamic> ? payloadRaw : null;

    return NotificationItem(
      id: id,
      title: title,
      subtitle: subtitle,
      time: createdAt.toString(),
      unread: !isRead,
      iconType: mappedType,
      rawType: typeStr,
      pointId: payload?['point_id']?.toString() ??
          payload?['pointId']?.toString() ??
          payload?['point']?.toString(),
      postId: payload?['post_id']?.toString() ?? payload?['postId']?.toString(),
    );
  }

  void _markAllAsRead() async {
    // Panggil API mark-all-as-read
    await _repo.markAllAsRead();
    if (!mounted) return;
    setState(() {
      _items = _items
          .map((e) => NotificationItem(
                id: e.id,
                title: e.title,
                subtitle: e.subtitle,
                time: e.time,
                unread: false,
                iconType: e.iconType,
                rawType: e.rawType,
                pointId: e.pointId,
                postId: e.postId,
              ))
          .toList();
    });
  }

  /// Hapus satu notifikasi dari list dan backend.
  Future<void> _deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    if (!mounted) return;
    setState(() {
      _items = _items.where((e) => e.id != id).toList();
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
                  'Tidak ada notifikasi',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.urgencyHigh,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 28),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Notifikasi?'),
                      content: const Text(
                          'Notifikasi ini akan dihapus secara permanen.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.urgencyHigh,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => _deleteNotification(item.id),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    // HANYA mark as read — notifikasi TIDAK dihapus dari list
                    if (item.unread) {
                      await _repo.markAsRead(item.id);
                      if (!mounted) return;
                      setState(() {
                        _items = _items
                            .map((e) => e.id == item.id
                                ? NotificationItem(
                                    id: e.id,
                                    title: e.title,
                                    subtitle: e.subtitle,
                                    time: e.time,
                                    unread: false, // tandai sebagai dibaca
                                    iconType: e.iconType,
                                    rawType: e.rawType,
                                    pointId: e.pointId,
                                    postId: e.postId,
                                  )
                                : e)
                            .toList();
                        // Catatan: item TIDAK dihapus dari _items
                      });
                    }

                    // Deep-link: payload.point_id -> donation detail
                    if (item.pointId != null && item.pointId!.isNotEmpty) {
                      if (!context.mounted) return;

                      final isDepartureNotif =
                          item.iconType.toLowerCase() == 'departure' ||
                              item.rawType.toLowerCase() == 'donator_departed';
                      if (isDepartureNotif) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DepartureReviewScreen(
                              pointId: item.pointId!,
                              pointTitle: item.subtitle.isNotEmpty
                                  ? item.subtitle
                                  : item.title,
                            ),
                          ),
                        );
                        return;
                      }

                      // FE-only deep-link untuk rating/donasi:
                      // load detail request dari backend supaya section rating donatur
                      // tampil sesuai status real (mis. RequestStatus.completed).
                      final requestId = item.pointId!;
                      final donationRepo = const DonationRepository();
                      final loaded = await donationRepo.getById(requestId);

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(
                            request: loaded,
                          ),
                        ),
                      );
                      return;
                    }

                    if (item.postId != null && item.postId!.isNotEmpty) {
                      // Navigate to community post detail
                      if (!context.mounted) return;
                      final communityRepo = const CommunityRepository();
                      try {
                        final post = await communityRepo.getPostById(item.postId!);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentsScreen(postId: item.postId!),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        // Fallback: buka community tab dengan post id
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentsScreen(postId: item.postId!),
                          ),
                        );
                      }
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
                    itemId: item.id,
                  ),
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
      'departure' => Icons.directions_run_rounded,
      'accepted' => Icons.check_circle_outline_rounded,
      'completed' => Icons.stars_rounded,
      'warning' => Icons.update_rounded,
      'favorite' => Icons.favorite_outline_rounded,
      'comment' => Icons.comment_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      'departure' => AppColors.statusProgress,
      'accepted' => AppColors.primary,
      'completed' => AppColors.statusCompleted,
      'warning' => AppColors.urgencyMedium,
      'favorite' => AppColors.urgencyHigh,
      'comment' => const Color(0xFF1565C0),
      _ => AppColors.primary,
    };
  }

  Color _bgForType(String type) {
    return switch (type) {
      'departure' => AppColors.statusProgress.withOpacity(0.12),
      'accepted' => AppColors.primaryContainer,
      'completed' => AppColors.statusCompletedLight,
      'warning' => AppColors.urgencyMediumLight,
      'favorite' => AppColors.urgencyHighLight,
      'comment' => const Color(0xFFE3F2FD),
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
    required String itemId,
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
            // Tombol hapus manual (selain swipe)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.textLight),
              tooltip: 'Hapus notifikasi',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Notifikasi?'),
                    content: const Text(
                        'Notifikasi ini akan dihapus secara permanen.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.urgencyHigh,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _deleteNotification(itemId);
                }
              },
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
  final String rawType;

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
    this.rawType = '',
    this.pointId,
    this.postId,
  });
}
