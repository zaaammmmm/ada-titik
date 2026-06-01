import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class ChatConversation {
  final int id;
  final String contextType;
  final int contextId;

  const ChatConversation({
    required this.id,
    required this.contextType,
    required this.contextId,
  });
}

class ChatMessageDto {
  final int id;
  final int conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });
}

class ChatConversationDto {
  final int id;
  final String contextType;
  final int contextId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final DateTime lastActivityAt;
  final String lastMessageBody;
  final bool unread;

  const ChatConversationDto({
    required this.id,
    required this.contextType,
    required this.contextId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastActivityAt,
    required this.lastMessageBody,
    required this.unread,
  });
}

class ChatRepository {
  const ChatRepository();

  Future<List<ChatConversationDto>> listConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/chats',
      query: {
        'page': page,
        'limit': limit,
      },
    );

    final body = res.data ?? {};
    final data = body['data'];
    if (data is! List) return [];

    return data.whereType<Map<String, dynamic>>().map((e) {
      final unreadCount = (e['unread_count'] as num?)?.toInt() ?? 0;
      final lastAtRaw = e['last_activity_at']?.toString();
      final lastAt = lastAtRaw != null
          ? DateTime.tryParse(lastAtRaw) ?? DateTime.now()
          : DateTime.now();

      return ChatConversationDto(
        id: (e['id'] as num).toInt(),
        contextType: e['context_type']?.toString() ?? 'post',
        contextId: (e['context_id'] as num).toInt(),
        otherUserId: e['other_user_id']?.toString() ?? '',
        otherUserName: e['other_user_name']?.toString() ??
            e['other_user']?.toString() ??
            'Komunitas',
        otherUserAvatar: e['other_user_avatar']?.toString() ?? '',
        lastActivityAt: lastAt,
        lastMessageBody: e['last_message_body']?.toString() ?? '',
        unread: unreadCount > 0,
      );
    }).toList();
  }

  Future<ChatConversation> startConversation({
    required String targetUserId,
    required String contextType,
    required int contextId,
  }) async {
    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/chats',
      data: {
        'target_user_id': targetUserId,
        'context_type': contextType,
        'context_id': contextId,
      },
    );

    final body = res.data ?? {};
    final data = body['data'];

    if (data is! Map<String, dynamic>) {
      // Backend contract guardrail.
      // Saat ini frontend mengharapkan `body['data']` berupa Map.
      // Jika backend mengirim bentuk lain (null/list/error), tampilkan raw body.
      final errMsg = body['message']?.toString() ??
          body['error']?.toString() ??
          'Unknown backend response';
      throw StateError(
        'Bad startConversation response: $errMsg. raw=$body',
      );
    }

    return ChatConversation(
      id: (data['id'] as num).toInt(),
      contextType: data['context_type']?.toString() ?? contextType,
      contextId: (data['context_id'] as num).toInt(),
    );
  }

  Future<List<ChatMessageDto>> listMessages({
    required int conversationId,
    required int limit,
    int? before,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/chats/$conversationId/messages',
      query: {
        'limit': limit,
        if (before != null) 'before': before,
      },
    );

    final body = res.data ?? {};
    final data = body['data'];
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => ChatMessageDto(
              id: (e['id'] as num).toInt(),
              conversationId: (e['conversation_id'] as num).toInt(),
              senderId: e['sender_id']?.toString() ?? '',
              body: e['body']?.toString() ?? '',
              createdAt: (() {
                final raw = e['created_at']?.toString();
                final parsed = DateTime.tryParse(raw ?? '');
                if (parsed == null) return DateTime.now();
                // Normalize to local time so jam sesuai perangkat.
                return parsed.isUtc ? parsed.toLocal() : parsed;
              })(),
            ))
        .toList();
  }

  Future<ChatMessageDto> sendMessage({
    required int conversationId,
    required String body,
    required String senderId,
  }) async {
    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/chats/$conversationId/messages',
      data: {
        'body': body,
      },
    );

    // Coba parse pesan yang dikembalikan API
    final resData = res.data ?? {};
    final raw = resData['data'] ?? resData['message'] ?? resData;
    if (raw is Map<String, dynamic> && raw.containsKey('id')) {
      return ChatMessageDto(
        id: (raw['id'] as num).toInt(),
        conversationId: conversationId,
        senderId: raw['sender_id']?.toString() ?? senderId,
        body: raw['body']?.toString() ?? body,
        createdAt: (() {
          final parsed = DateTime.tryParse(raw['created_at']?.toString() ?? '');
          if (parsed == null) return DateTime.now();
          return parsed.isUtc ? parsed.toLocal() : parsed;
        })(),
      );
    }

    // Fallback: kembalikan pesan dengan DateTime.now() jika API tidak return data
    return ChatMessageDto(
      id: resData['id'] != null
          ? (resData['id'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      createdAt: DateTime.now(),
    );
  }

  Future<void> markAsRead({required int conversationId}) async {
    await ApiClient.patch<Map<String, dynamic>>(
      '/api/chats/$conversationId/read',
      data: {},
    );
  }
}
