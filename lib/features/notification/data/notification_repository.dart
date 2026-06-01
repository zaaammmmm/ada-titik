// lib/features/notification/data/notification_repository.dart
import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class NotificationRepository {
  const NotificationRepository();

  // ─── GET /api/notifications/nearby (legacy) ───────────────────────────
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
        'pointId': item['point_id']?.toString(),
        'distanceMeters': item['distance_meters']?.toString(),
        'distanceMetersNumber': item['distance_meters'],
        'latitude': item['latitude'],
        'longitude': item['longitude'],
      },
      createdAt: _parseDateTime(item['created_at']),
      read: item['read_at'] != null || item['read'] == true,
    );
  }

  // ─── GET /api/notifications (event-driven v3.2) ────────────────────────
  Future<List<NotificationModel>> getUserNotifications({
    int page = 1,
    int limit = 20,
    bool unread = false,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (unread) 'unread': true,
      };

      final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/notifications',
        query: query,
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
      print('❌ Error getting user notifications: $e');
      return [];
    }
  }

  NotificationModel _mapNotification(Map<String, dynamic> item) {
    final typeStr = item['type']?.toString() ?? '';
    final type = _parseNotificationType(typeStr);

    // Backend v3.2 kontrak: { title, body, payload, read_at, created_at }
    final title = item['title']?.toString() ?? '';
    final subtitle =
        item['body']?.toString() ?? item['subtitle']?.toString() ?? '';

    final payloadRaw = item['payload'];
    final payload = payloadRaw is Map<String, dynamic> ? payloadRaw : null;

    final readAt = item['read_at'];
    final isRead = readAt != null;

    return NotificationModel(
      id: item['id']?.toString() ?? '',
      title: title,
      subtitle: subtitle,
      type: type,
      payload: payload,
      createdAt: _parseDateTime(item['created_at']),
      read: isRead,
    );
  }

  NotificationType _parseNotificationType(String s) {
    switch (s) {
      case 'donator_departed':
        return NotificationType.departure;
      case 'participant_accepted':
        return NotificationType.participantAccepted;
      case 'participant_completed':
        return NotificationType.participantCompleted;
      case 'progress_updated':
      case 'urgency_changed':
        return NotificationType.statusUpdate;
      case 'post_liked':
        return NotificationType.like;
      case 'post_commented':
        return NotificationType.commentReply;
      default:
        return NotificationType.nearbyPoint;
    }
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
