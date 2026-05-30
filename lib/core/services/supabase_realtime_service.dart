import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Supabase realtime integration for Flutter.
///
/// Implements realtime subscription to `chat_messages` using Supabase Realtime.
class SupabaseRealtimeService {
  SupabaseRealtimeService();

  StreamSubscription<dynamic>? _sub;
  RealtimeChannel? _channel;

  /// Subscribe to realtime inserts for chat messages.
  ///
  /// Contract (backend): conversationId is an integer column named `conversation_id`.
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

    _channel!.subscribe();
  }

  /// Subscribe to realtime updates for chat conversations.
  ///
  /// Contract (backend): table `chat_conversations` has RLS so client only
  /// receives rows they are allowed to see.
  Future<void> subscribeToChatConversations({
    required String currentUserId,
    required void Function(Map<String, dynamic> payload) onUpsert,
    void Function(Object error)? onError,
  }) async {
    await dispose();

    final supabase = Supabase.instance.client;

    // Can't rely on Postgres filter because `chat_conversations` likely has
    // two participant columns. RLS will enforce visibility.
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
              onUpsert(record);
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
              onUpsert(record);
            }
          },
        )
        .subscribe();

    _channel!.subscribe();
  }

  /// Subscribe to realtime inserts for notifications.
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
              // Tampilkan local notification heads-up saat event realtime masuk
              _showLocalNotification(record);
              onInsert(record);
            }
          },
        )
        .subscribe();

    _channel!.subscribe();
  }

  /// Tampilkan local notification untuk event notifikasi dari backend.
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
    } catch (_) {
      // Jangan crash jika notifikasi gagal
    }
  }

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
}
