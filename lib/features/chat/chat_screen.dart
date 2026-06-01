// lib/features/chat/chat_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_realtime_service.dart';
import 'data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? targetUserId;
  final int? contextId;
  final String contextType;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? contextTitle;
  final String? contextSummary;

  final String? initialMessage;
  final List<String>? quickMessages;

  const ChatScreen({
    super.key,
    this.targetUserId,
    this.contextId,
    this.contextType = 'post',
    this.otherUserName,
    this.otherUserAvatar,
    this.contextTitle,
    this.contextSummary,
    this.initialMessage,
    this.quickMessages,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late final ChatRepository _repo;
  late final AnimationController _sendButtonController;

  bool _loading = true;
  bool _sending = false;
  bool _isTyping = false;
  bool _canLoadMore = false;
  bool _loadingMore = false;
  bool _quickMessagesSent = false; // hide quick messages after first use

  int? _conversationId;
  List<ChatMessageDto> _messages = [];
  String? _errorMessage;

  // For date separators
  // Polling dinonaktifkan untuk realtime (Supabase Realtime)
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _repo = const ChatRepository();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _init();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _onScroll() {
    // Load more messages when scrolling to top
    if (_scrollController.position.pixels <= 100 &&
        _canLoadMore &&
        !_loadingMore) {
      _loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _pollingTimer?.cancel();
    _chatRealtime.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
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
        _canLoadMore = msgs.length >= 50;
      });

      await _repo.markAsRead(conversationId: conv.id);
      _scrollToBottomOnLoad();

      // Auto-send context summary message when opened from a titik (Shopee-style)
      // Only auto-send if this is a donation context with a title
      if (widget.contextTitle != null && widget.contextTitle!.isNotEmpty) {
        // Don't auto-send here; the quick message card handles the first message
        // Just ensure quick messages are shown
        setState(() => _quickMessagesSent = false);
      } else if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        // For Maps-style navigation, pre-fill the text field
        _textController.text = widget.initialMessage!;
        _onTextChanged();
      }

      // Subscribe realtime for new messages (Supabase Realtime)
      // Polling dinonaktifkan.
      _subscribeRealtime(conv.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  final SupabaseRealtimeService _chatRealtime = SupabaseRealtimeService();

  void _sendQuickMessage(String message) {
    _textController.text = message;
    _onTextChanged();
    setState(() => _quickMessagesSent = true);
    // Auto send
    Future.microtask(() => _send());
  }

  void _subscribeRealtime(int conversationId) {
    // Realtime subscription: append incoming message into UI.
    final realtime = _chatRealtime;
    realtime.subscribeToChatMessages(
      conversationId: conversationId.toString(),
      onInsert: (payload) {
        final newMessage = ChatMessageDto(
          id: (payload['id'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
          conversationId:
              (payload['conversation_id'] as num?)?.toInt() ?? conversationId,
          senderId: payload['sender_id']?.toString() ?? '',
          body: payload['body']?.toString() ?? '',
          createdAt: (() {
            final raw = payload['created_at']?.toString();
            final parsed = DateTime.tryParse(raw ?? '');
            if (parsed == null) return DateTime.now();
            // Normalize to local time so UI jam sesuai waktu perangkat.
            return parsed.isUtc ? parsed.toLocal() : parsed;
          })(),
        );

        if (!mounted) return;

        // Ambil userId dari auth — skip pesan kita sendiri karena
        // sudah di-handle di _send() via API response langsung.
        final myId = ref.read(authProvider).user?.id ?? '';
        if (newMessage.senderId == myId) return;

        setState(() {
          // Deduplicate berdasarkan id
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages = [..._messages, newMessage];
          }
        });
        _scrollToBottom();

        if (conversationId == _conversationId) {
          _repo.markAsRead(conversationId: conversationId);
        }
      },
      onError: (err) {
        // ignore; fallback handled by initial load
      },
    );
  }

  // void _startPolling() {
  //   _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
  //     if (_conversationId == null || !mounted) return;
  //     try {
  //       final msgs = await _repo.listMessages(
  //         conversationId: _conversationId!,
  //         limit: 50,
  //         before: null,
  //       );
  //       if (!mounted) return;
  //       if (msgs.length != _messages.length ||
  //           (msgs.isNotEmpty &&
  //               _messages.isNotEmpty &&
  //               msgs.last.id != _messages.last.id)) {
  //         setState(() => _messages = msgs);
  //         await _repo.markAsRead(conversationId: _conversationId!);
  //       }
  //     } catch (_) {}
  //   });
  // }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_conversationId == null || !mounted) return;
      try {
        final msgs = await _repo.listMessages(
          conversationId: _conversationId!,
          limit: 50,
          before: null,
        );
        if (!mounted) return;
        if (msgs.length != _messages.length ||
            (msgs.isNotEmpty &&
                _messages.isNotEmpty &&
                msgs.last.id != _messages.last.id)) {
          setState(() => _messages = msgs);
          await _repo.markAsRead(conversationId: _conversationId!);
        }
      } catch (_) {}
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_messages.isEmpty || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final older = await _repo.listMessages(
        conversationId: _conversationId!,
        limit: 30,
        before: _messages.first.id,
      );
      if (!mounted) return;
      setState(() {
        _messages = [...older, ..._messages];
        _canLoadMore = older.length >= 30;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _conversationId == null) return;

    // Optimistic UI: add temp message immediately
    final tempMsg = ChatMessageDto(
      id: -DateTime.now().millisecondsSinceEpoch, // temp negative id
      conversationId: _conversationId!,
      senderId: ref.read(authProvider).user?.id ?? '',
      body: body,
      createdAt: DateTime.now(),
    );

    setState(() {
      _sending = true;
      _messages = [..._messages, tempMsg];
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final confirmed = await _repo.sendMessage(
        conversationId: _conversationId!,
        body: body,
        senderId: tempMsg.senderId,
      );

      if (!mounted) return;
      // Upgrade temp message ke pesan yang sudah dikonfirmasi API.
      // Realtime tetap aktif untuk pesan dari lawan bicara,
      // tapi pesan kita TIDAK bergantung pada realtime event.
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (idx >= 0) {
          final updated = List<ChatMessageDto>.from(_messages);
          updated[idx] = confirmed;
          _messages = updated;
        } else if (!_messages.any((m) => m.id == confirmed.id)) {
          // Kalau sudah ditambahkan oleh realtime, skip duplikasi
          _messages = [..._messages, confirmed];
        }
        _sending = false;
      });

      _scrollToBottom();
      await _repo.markAsRead(conversationId: _conversationId!);
    } catch (e) {
      if (!mounted) return;
      // Tandai temp message sebagai gagal (tampilkan tetap, beri tahu user)
      setState(() {
        _messages = _messages.where((m) => m.id != tempMsg.id).toList();
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: AppColors.urgencyHigh,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  /// Scroll ke bawah saat layar pertama terbuka.
  /// Butuh dua frame: frame pertama ListView baru dibuat, frame kedua
  /// barulah maxScrollExtent mencerminkan konten yang sebenarnya.
  void _scrollToBottomOnLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated && max > 0) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    });
  }

  void _onLongPressMessage(ChatMessageDto msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptionsSheet(
        message: msg,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: msg.body));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pesan disalin'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Hari ini';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) return 'Kemarin';
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;
    final displayName = widget.otherUserName ?? 'Chat';
    final avatarUrl = widget.otherUserAvatar;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: _ChatAppBar(
        name: displayName,
        avatarUrl: avatarUrl,
        onBack: () => Navigator.pop(context),
        onRefresh: _init,
      ),
      body: Column(
        children: [
          // Load more indicator
          if (_loadingMore)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.transparent,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          // Quick Messages Card — Shopee-style, tampil ketika dibuka dari titik
          if (widget.contextTitle != null &&
              widget.contextTitle!.isNotEmpty &&
              !_quickMessagesSent &&
              _conversationId != null &&
              _messages.isEmpty)
            _QuickMessageCard(
              title: widget.contextTitle!,
              summary: widget.contextSummary,
              quickMessages: widget.quickMessages ??
                  const [
                    'Apakah titik bantuan ini masih aktif?',
                    'Berapa banyak yang masih dibutuhkan?',
                    'Saya ingin membantu, bagaimana caranya?',
                    'Apakah ada kebutuhan lain selain yang tertulis?',
                  ],
              onSendQuick: _sendQuickMessage,
            )
          else if (widget.contextTitle != null &&
              widget.contextTitle!.isNotEmpty &&
              (_quickMessagesSent || _messages.isNotEmpty))
            _ContextBanner(
              title: widget.contextTitle!,
              summary: widget.contextSummary,
            ),

          // Messages list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? _ErrorView(error: _errorMessage!, onRetry: _init)
                    : _messages.isEmpty
                        ? _EmptyChat(name: displayName)
                        : _MessagesList(
                            messages: _messages,
                            userId: userId,
                            scrollController: _scrollController,
                            formatTime: _formatTime,
                            isSameDay: _isSameDay,
                            formatDateSeparator: _formatDateSeparator,
                            onLongPress: _onLongPressMessage,
                          ),
          ),

          // Input bar
          _ChatInputBar(
            controller: _textController,
            focusNode: _focusNode,
            sending: _sending,
            isTyping: _isTyping,
            sendButtonController: _sendButtonController,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Message Card (Shopee-style) ────────────────────────────────────────

class _QuickMessageCard extends StatelessWidget {
  final String title;
  final String? summary;
  final List<String> quickMessages;
  final void Function(String message) onSendQuick;

  const _QuickMessageCard({
    required this.title,
    required this.quickMessages,
    required this.onSendQuick,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titik summary card header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (summary != null && summary!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          summary!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary.withOpacity(0.7),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick messages section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanya ke Komunitas',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickMessages.map((msg) {
                    return GestureDetector(
                      onTap: () => onSendQuick(msg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          msg,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Context Banner (Titik) ───────────────────────────────────────────────────

class _ContextBanner extends StatelessWidget {
  final String title;
  final String? summary;

  const _ContextBanner({required this.title, this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary != null && summary!.isNotEmpty)
                  Text(
                    summary!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Konteks',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String? avatarUrl;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const _ChatAppBar({
    required this.name,
    required this.avatarUrl,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: onBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _AvatarWidget(
            avatarUrl: avatarUrl,
            name: name,
            radius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Messages List ───────────────────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  final List<ChatMessageDto> messages;
  final String? userId;
  final ScrollController scrollController;
  final String Function(DateTime) formatTime;
  final bool Function(DateTime, DateTime) isSameDay;
  final String Function(DateTime) formatDateSeparator;
  final void Function(ChatMessageDto) onLongPress;

  const _MessagesList({
    required this.messages,
    required this.userId,
    required this.scrollController,
    required this.formatTime,
    required this.isSameDay,
    required this.formatDateSeparator,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Build items with date separators
    final List<dynamic> items = [];
    DateTime? prevDate;
    for (final msg in messages) {
      final msgDate =
          DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (prevDate == null || !isSameDay(prevDate, msgDate)) {
        items.add(msgDate); // date separator
      }
      items.add(msg);
      prevDate = msgDate;
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is DateTime) {
          return _DateSeparator(label: formatDateSeparator(item));
        }

        final msg = item as ChatMessageDto;
        final isMe = userId != null && msg.senderId == userId;
        final isTemp = msg.id < 0;

        // Group consecutive messages from same sender
        bool isFirst = true;
        bool isLast = true;
        if (index > 0 && items[index - 1] is ChatMessageDto) {
          final prev = items[index - 1] as ChatMessageDto;
          if (prev.senderId == msg.senderId) isFirst = false;
        }
        if (index < items.length - 1 && items[index + 1] is ChatMessageDto) {
          final next = items[index + 1] as ChatMessageDto;
          if (next.senderId == msg.senderId) isLast = false;
        }

        return _MessageBubble(
          msg: msg,
          isMe: isMe,
          isTemp: isTemp,
          isFirst: isFirst,
          isLast: isLast,
          time: formatTime(msg.createdAt),
          onLongPress: () => onLongPress(msg),
        );
      },
    );
  }
}

// ─── Date Separator ──────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFCCCCCC), height: 1)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCDCDC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF555555),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: Color(0xFFCCCCCC), height: 1)),
        ],
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageDto msg;
  final bool isMe;
  final bool isTemp;
  final bool isFirst;
  final bool isLast;
  final String time;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isTemp,
    required this.isFirst,
    required this.isLast,
    required this.time,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const myBg = AppColors.primary;
    const theirBg = Colors.white;
    final myFg = Colors.white;
    final theirFg = AppColors.textPrimary;

    final bg = isMe ? myBg : theirBg;
    final fg = isMe ? myFg : theirFg;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(!isMe && !isFirst ? 4 : 18),
      topRight: Radius.circular(isMe && !isFirst ? 4 : 18),
      bottomLeft: Radius.circular(!isMe && !isLast ? 4 : 18),
      bottomRight: Radius.circular(isMe && !isLast ? 4 : 18),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 6 : 2,
        top: isFirst ? 4 : 0,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: fg,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: fg.withOpacity(0.65),
                        fontSize: 10.5,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isTemp
                            ? Icons.access_time_rounded
                            : Icons.done_all_rounded,
                        size: 13,
                        color: isTemp
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.75),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool isTyping;
  final AnimationController sendButtonController;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.isTyping,
    required this.sendButtonController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F0),
          border: Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isTyping || sending)
                    ? AppColors.primary
                    : AppColors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: isTyping
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(23),
                  onTap: sending ? null : onSend,
                  child: Center(
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.send_rounded,
                              key: ValueKey(isTyping),
                              size: 20,
                              color: isTyping
                                  ? Colors.white
                                  : AppColors.primaryLight,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String name;
  const _EmptyChat({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mulai percakapan',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Kirim pesan pertamamu ke $name',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Gagal memuat pesan', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(
              error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar Widget ───────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const _AvatarWidget({
    required this.name,
    required this.radius,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryContainer,
      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            )
          : Text(
              initial,
              style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
    );
  }
}

// ─── Message Options Bottom Sheet ────────────────────────────────────────────

class _MessageOptionsSheet extends StatelessWidget {
  final ChatMessageDto message;
  final VoidCallback onCopy;

  const _MessageOptionsSheet({
    required this.message,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              message.body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copy_rounded, color: AppColors.primary),
            title: const Text('Salin pesan'),
            onTap: () {
              Navigator.pop(context);
              onCopy();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
