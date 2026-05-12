// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../donation/data/donation_repository.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<List<NotificationItem>> _loadNotifications() async {
    final repo = DonationRepository();
    return repo.getNearbyNotifications(limit: 10).then(
          (items) => items
              .map((post) => NotificationItem(
                    id: post.id,
                    title: post.authorName,
                    subtitle: post.content,
                    time: post.timeAgo,
                    unread: true,
                    iconType: post.type.name,
                  ))
              .toList(),
        );
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
            onPressed: () {},
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
        future: _loadNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat notifikasi. Silakan coba lagi.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tidak ada notifikasi terbaru.',
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
              return _buildNotifItem(
                icon: _iconForType(item.iconType),
                iconBg: _bgForType(item.iconType),
                iconColor: _colorForType(item.iconType),
                title: item.title,
                subtitle: item.subtitle,
                time: item.time,
                isUnread: item.unread,
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

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.iconType,
  });
}
