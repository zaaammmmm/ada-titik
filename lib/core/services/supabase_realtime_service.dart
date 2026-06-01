// lib/core/services/supabase_realtime_service.dart
//
// PERUBAHAN dari versi sebelumnya:
// - Tambah subscribeToCommunityPosts() sesuai migration_v6.sql:
//   community_posts dan donation_points sudah masuk supabase_realtime publication
//   + RLS SELECT publik (USING true).
// - subscribeToDonationPoints() tetap ada, dipindah ke bawah dengan channel name
//   yang lebih eksplisit.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class SupabaseRealtimeService {
  SupabaseRealtimeService();

  // Callback status koneksi — biar kegagalan realtime tidak diam-diam.
  // SUBSCRIBED = sehat; CHANNEL_ERROR/TIMED_OUT = ada masalah (kredensial/RLS).
  static void _logStatus(String channel, RealtimeSubscribeStatus status,
      [Object? error]) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      debugPrint('[realtime] $channel: SUBSCRIBED ✓');
    } else {
      debugPrint('[realtime] $channel: $status ${error ?? ''}');
    }
  }

  StreamSubscription<dynamic>? _sub;
  RealtimeChannel? _channel;
  RealtimeChannel? _donationChannel;
  RealtimeChannel? _communityChannel; // ✅ NEW: community_posts realtime

  // ─── Community Posts ──────────────────────────────────────────────────────
  //
  // Migration v6: community_posts ditambahkan ke supabase_realtime publication
  // + RLS policy: community_posts_public_read (USING true) → siapa pun bisa subscribe.
  //
  // CATATAN: Payload realtime hanya berisi kolom mentah community_posts.
  // Untuk author_name, author_avatar, comments_count → re-fetch via GET /api/community/posts.

  Future<void> subscribeToCommunityPosts({
    required void Function() onInsert,
  }) async {
    try {
      await _communityChannel?.unsubscribe();
    } catch (_) {}

    final supabase = Supabase.instance.client;
    _communityChannel = supabase.channel('community_posts_feed');

    _communityChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_posts',
          callback: (_) => onInsert(),
        )
        .subscribe((status, [error]) =>
            _logStatus('community_posts', status, error));
  }

  Future<void> unsubscribeFromCommunityPosts() async {
    try {
      await _communityChannel?.unsubscribe();
    } catch (_) {}
    _communityChannel = null;
  }

  // ─── Donation Points ──────────────────────────────────────────────────────
  //
  // Migration v6: donation_points juga ditambahkan ke supabase_realtime publication
  // + RLS policy: donation_points_public_read (USING deleted_at IS NULL).

  Future<void> subscribeToDonationPoints({
    required void Function() onUpdate,
  }) async {
    try {
      await _donationChannel?.unsubscribe();
    } catch (_) {}

    final supabase = Supabase.instance.client;
    _donationChannel = supabase.channel('donation_points_changes');

    _donationChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'donation_points',
          callback: (_) => onUpdate(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'donation_points',
          callback: (_) => onUpdate(),
        )
        .subscribe((status, [error]) =>
            _logStatus('donation_points', status, error));
  }

  Future<void> unsubscribeFromDonationPoints() async {
    try {
      await _donationChannel?.unsubscribe();
    } catch (_) {}
    _donationChannel = null;
  }

  // ─── Chat Messages ────────────────────────────────────────────────────────

  Future<void> subscribeToChatMessages({
    required String conversationId,
    required void Function(Map<String, dynamic> payload) onInsert,
    void Function(Object error)? onError,
  }) async {
    await dispose();

    final supabase = Supabase.instance.client;

    final intConvId = int.tryParse(conversationId);
    if (intConvId == null) {
      throw ArgumentError(
          'conversationId harus berupa integer. Diterima: $conversationId');
    }

    final channelName = 'chat_messages:$conversationId';
    _channel = supabase.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: intConvId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record is Map<String, dynamic>) {
              onInsert(record);
            }
          },
        )
        .subscribe();
  }

  // ─── Chat Conversations ───────────────────────────────────────────────────

  Future<void> subscribeToChatConversations({
    required String currentUserId,
    required void Function(Map<String, dynamic> payload) onUpsert,
    void Function(Object error)? onError,
  }) async {
    await dispose();

    final supabase = Supabase.instance.client;
    final channelName = 'chat_conversations:$currentUserId';
    _channel = supabase.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_conversations',
          callback: (payload) {
            final record = payload.newRecord;
            if (record is Map<String, dynamic>) {
              // Client-side filter: only handle conversations involving current user
              final p1 = record['participant1_id']?.toString() ?? '';
              final p2 = record['participant2_id']?.toString() ?? '';
              if (p1 == currentUserId || p2 == currentUserId) {
                onUpsert(record);
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_conversations',
          callback: (payload) {
            final record = payload.newRecord;
            if (record is Map<String, dynamic>) {
              final p1 = record['participant1_id']?.toString() ?? '';
              final p2 = record['participant2_id']?.toString() ?? '';
              if (p1 == currentUserId || p2 == currentUserId) {
                onUpsert(record);
              }
            }
          },
        )
        .subscribe();
  }

  RealtimeChannel? _chatNotifChannel;

  /// Subscribe to new chat messages for the current user (for background/global notifications).
  /// This shows a local notification when a message arrives from any conversation.
  Future<void> subscribeToAllChatMessages({
    required String currentUserId,
    required void Function(Map<String, dynamic> payload) onNewMessage,
  }) async {
    try {
      await _chatNotifChannel?.unsubscribe();
    } catch (_) {}

    final supabase = Supabase.instance.client;
    _chatNotifChannel = supabase.channel('chat_messages_all:$currentUserId');

    _chatNotifChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final record = payload.newRecord;
            if (record is Map<String, dynamic>) {
              // Only notify for messages NOT sent by the current user
              final senderId = record['sender_id']?.toString() ?? '';
              if (senderId != currentUserId) {
                onNewMessage(record);
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> unsubscribeFromAllChatMessages() async {
    try {
      await _chatNotifChannel?.unsubscribe();
    } catch (_) {}
    _chatNotifChannel = null;
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<void> subscribeToNotifications({
    required String currentUserId,
    required void Function(Map<String, dynamic> payload) onInsert,
    void Function(Object error)? onError,
  }) async {
    await dispose();

    final supabase = Supabase.instance.client;
    final channelName = 'notifications:$currentUserId';
    _channel = supabase.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record is Map<String, dynamic>) {
              _showLocalNotification(record);
              onInsert(record);
            }
          },
        )
        .subscribe((status, [error]) =>
            _logStatus('notifications', status, error));
  }

  void _showLocalNotification(Map<String, dynamic> record) {
    try {
      final title = record['title']?.toString() ?? 'Ada Titik!';
      final body = record['body']?.toString() ??
          record['subtitle']?.toString() ??
          'Ada pembaruan donasi untuk Anda.';
      final id = record['id']?.toString() ?? '';
      NotificationService.instance.show(
        id: id.hashCode.abs() % 100000,
        title: title,
        body: body,
        payload: 'notification:$id',
      );
    } catch (_) {}
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;

    try {
      await _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;
  }

  Future<void> disposeAll() async {
    await dispose();
    await unsubscribeFromDonationPoints();
    await unsubscribeFromCommunityPosts();
    await unsubscribeFromAllChatMessages();
  }
}
