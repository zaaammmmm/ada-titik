// lib/features/notification/data/notification_repository.dart
import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class NotificationRepository {
  const NotificationRepository();

  // ─── GET /api/notifications/nearby ─────────────────────────────────────
  /// Get nearby donation points as notifications
  Future<List<NotificationModel>> getNearbyNotifications({
    required double lat,
    required double lng,
    double radius = 5000,
    int limit = 10,
  }) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/notifications/nearby',
        query: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'limit': limit,
        },
      );

      final statusCode = res.statusCode ?? 0;
      if (statusCode != 200) {
        throw Exception('Gagal memuat notifikasi ($statusCode)');
      }

      final body = res.data ?? {};
      final data = (body['data'] as List?) ?? [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(_mapNearbyNotification)
          .toList();
    } catch (e) {
      print('❌ Error getting nearby notifications: $e');
      return [];
    }
  }

  NotificationModel _mapNearbyNotification(Map<String, dynamic> item) {
    return NotificationModel(
      id: item['id']?.toString() ?? '',
      title: item['title']?.toString() ?? 'Bantuan baru di dekat Anda',
      subtitle: item['subtitle']?.toString() ?? '',
      type: NotificationType.nearbyPoint,
      payload: {
        // Backend v3: payload tidak dispesifikkan di docs /api/notifications/nearby,
        // tetapi biasanya tersedia field point_id. Kita taruh ke payload untuk deep-link.
        'pointId': item['point_id']?.toString(),
        // keep extra fields jika dibutuhkan
        'distanceMeters': item['distance_meters']?.toString(),
        'distanceMetersNumber': item['distance_meters'],
        'latitude': item['latitude'],
        'longitude': item['longitude'],
      },
      createdAt: _parseDateTime(item['created_at']),
      read: item['read'] == true,
    );
  }

  // ─── GET /api/notifications (all notifications) ─────────────────────────
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/notifications',
        query: {'page': page, 'limit': limit},
      );

      final statusCode = res.statusCode ?? 0;
      if (statusCode != 200) {
        throw Exception('Gagal memuat notifikasi ($statusCode)');
      }

      final body = res.data ?? {};
      final data = (body['data'] as List?) ?? [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(_mapNotification)
          .toList();
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  NotificationModel _mapNotification(Map<String, dynamic> item) {
    final typeStr = item['type']?.toString() ?? 'nearby_point';
    final type = _parseNotificationType(typeStr);

    return NotificationModel(
      id: item['id']?.toString() ?? '',
      title: item['title']?.toString() ?? '',
      subtitle: item['subtitle']?.toString() ?? '',
      type: type,
      payload: item['payload'] is Map<String, dynamic>
          ? item['payload'] as Map<String, dynamic>?
          : null,
      createdAt: _parseDateTime(item['created_at']),
      read: item['read'] == true,
    );
  }

  NotificationType _parseNotificationType(String s) {
    return switch (s) {
      'status_update' => NotificationType.statusUpdate,
      'like' => NotificationType.like,
      'comment' => NotificationType.comment,
      'comment_reply' => NotificationType.commentReply,
      _ => NotificationType.nearbyPoint,
    };
  }

  // ─── PATCH /api/notifications/:id/read ─────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      await ApiClient.patch<Map<String, dynamic>>(
        '/api/notifications/$notificationId/read',
        data: {},
      );
    } catch (e) {
      print('⚠️ Error marking notification as read: $e');
    }
  }

  // ─── PATCH /api/notifications/read-all ──────────────────────────────────
  Future<void> markAllAsRead() async {
    try {
      await ApiClient.patch<Map<String, dynamic>>(
        '/api/notifications/read-all',
        data: {},
      );
    } catch (e) {
      print('⚠️ Error marking all as read: $e');
    }
  }

  // ─── DELETE /api/notifications/:id ──────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    try {
      await ApiClient.delete<Map<String, dynamic>>(
        '/api/notifications/$notificationId',
      );
    } catch (e) {
      print('⚠️ Error deleting notification: $e');
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
