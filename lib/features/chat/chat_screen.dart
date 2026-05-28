import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import 'data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? targetUserId;
  final int? contextId;
  final String contextType;

  const ChatScreen({
    super.key,
    this.targetUserId,
    this.contextId,
    this.contextType = 'post',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  late final ChatRepository _repo;

  bool _loading = true;
  bool _sending = false;

  int? _conversationId;
  List<ChatMessageDto> _messages = [];

  // Minimal UI: WhatsApp-style bubbles.

  @override
  void initState() {
    super.initState();
    _repo = const ChatRepository();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      // Jika dibuka dari list percakapan, kita mungkin tidak punya targetUserId/context.
      // Dalam versi sederhana ini: hanya dukung mode thread langsung jika parameter ada.
      if (widget.targetUserId == null || widget.contextId == null) {
        setState(() {
          _loading = false;
          _messages = [];
        });
        return;
      }

      final conv = await _repo.startConversation(
        targetUserId: widget.targetUserId!,
        contextType: widget.contextType,
        contextId: widget.contextId!,
      );
      _conversationId = conv.id;

      final msgs = await _repo.listMessages(
        conversationId: conv.id,
        limit: 50,
        before: null,
      );

      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });

      // Mark as read when opening
      await _repo.markAsRead(conversationId: conv.id);

      // Scroll to bottom (latest)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat chat: $e')),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;
    if (_conversationId == null) return;

    setState(() => _sending = true);
    try {
      await _repo.sendMessage(
        conversationId: _conversationId!,
        body: body,
      );
      _textController.clear();

      // Refresh messages (simple approach)
      final msgs = await _repo.listMessages(
        conversationId: _conversationId!,
        limit: 50,
        before: null,
      );

      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _sending = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });

      await _repo.markAsRead(conversationId: _conversationId!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = userId != null && msg.senderId == userId;
                      return _MessageBubble(
                        isMe: isMe,
                        body: msg.body,
                        time: _formatTime(msg.createdAt),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tulis pesan...',
                              hintStyle: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _send,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String body;
  final String time;

  const _MessageBubble({
    required this.isMe,
    required this.body,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? AppColors.primary : AppColors.surfaceVariant;
    final fg = isMe ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14).copyWith(
            topLeft: Radius.circular(isMe ? 14 : 0),
            topRight: Radius.circular(isMe ? 0 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTextStyles.bodySmall.copyWith(
                color: fg.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Note: Message DTO handled by ChatRepository; internal model kept unused.
/*
class _ChatMessage {

  final int id;

  final int conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const _ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  String get createdAtShort =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
}
*/
