// lib/features/chat/conversations_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/app_widgets.dart';
import 'chat_screen.dart';
import 'data/chat_repository.dart';
import '../../core/services/supabase_realtime_service.dart';
import '../../core/providers/auth_provider.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState
    extends ConsumerState<ConversationsListScreen> {
  final ChatRepository _repo = const ChatRepository();

  bool _loading = true;
  String? _error;
  List<ChatConversationDto> _convs = const [];
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();

    // Realtime subscription for chat conversations (preview/unread badge).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null || userId.isEmpty) return;

      final realtime = SupabaseRealtimeService();
      await realtime.subscribeToChatConversations(
        currentUserId: userId,
        onUpsert: (payload) {
          if (!mounted) return;
          final conv = _mapConversationFromRealtime(payload);
          setState(() {
            final idx = _convs.indexWhere((c) => c.id == conv.id);
            if (idx >= 0) {
              _convs = [
                ..._convs.sublist(0, idx),
                conv,
                ..._convs.sublist(idx + 1),
              ];
            } else {
              _convs = [conv, ..._convs];
            }
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _repo.listConversations(page: 1, limit: 50);
      if (!mounted) return;
      setState(() {
        _convs = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ChatConversationDto> get _filtered {
    if (_searchQuery.isEmpty) return _convs;
    final q = _searchQuery.toLowerCase();
    return _convs.where((c) {
      return c.otherUserName.toLowerCase().contains(q) ||
          c.lastMessageBody.toLowerCase().contains(q);
    }).toList();
  }

  int get _unreadCount => _convs.where((c) => c.unread).length;

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
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
    return '${dt.day} ${months[dt.month]}';
  }

  void _openChat(ChatConversationDto c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          targetUserId: c.otherUserId,
          contextType: c.contextType,
          contextId: c.contextId,
          otherUserName: c.otherUserName,
          otherUserAvatar: c.otherUserAvatar,
        ),
      ),
    );
  }

  ChatConversationDto _mapConversationFromRealtime(Map<String, dynamic> row) {
    // Expect fields similar to listConversations REST contract.
    final unreadCount = (row['unread_count'] as num?)?.toInt() ?? 0;

    final lastAtRaw = row['last_activity_at']?.toString();
    final lastAt = lastAtRaw != null
        ? DateTime.tryParse(lastAtRaw) ?? DateTime.now()
        : DateTime.now();

    return ChatConversationDto(
      id: (row['id'] as num).toInt(),
      contextType: row['context_type']?.toString() ?? 'post',
      contextId: (row['context_id'] as num).toInt(),
      otherUserId: row['other_user_id']?.toString() ?? '',
      otherUserName: row['other_user_name']?.toString() ?? 'User',
      otherUserAvatar: row['other_user_avatar']?.toString() ?? '',
      lastActivityAt: lastAt,
      lastMessageBody: row['last_message_body']?.toString() ?? '',
      unread: unreadCount > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _showSearch
          ? _SearchAppBar(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              onClose: () => setState(() {
                _showSearch = false;
                _searchQuery = '';
                _searchController.clear();
              }),
            ) as PreferredSizeWidget
          : _ConvsAppBar(
              unreadCount: _unreadCount,
              onSearch: () => setState(() => _showSearch = true),
              onRefresh: _load,
            ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: _buildList(),
                ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return _searchQuery.isNotEmpty
          ? _NoResultsView(query: _searchQuery)
          : _EmptyConvsView();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 76,
        color: AppColors.divider,
      ),
      itemBuilder: (context, index) {
        final c = items[index];
        return _ConversationTile(
          conv: c,
          relativeTime: _formatRelativeTime(c.lastActivityAt),
          onTap: () => _openChat(c),
        );
      },
    );
  }
}

// ─── App Bars ─────────────────────────────────────────────────────────────────

class _ConvsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;
  final VoidCallback onSearch;
  final VoidCallback onRefresh;

  const _ConvsAppBar({
    required this.unreadCount,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'Pesan',
            style: AppTextStyles.brandTitle.copyWith(fontSize: 20),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.urgencyHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
          onPressed: onSearch,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchAppBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
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
        onPressed: onClose,
      ),
      title: TextField(
        controller: controller,
        autofocus: true,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Cari percakapan...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textLight,
          ),
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ChatConversationDto conv;
  final String relativeTime;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conv,
    required this.relativeTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = conv.otherUserName.isNotEmpty
        ? conv.otherUserName[0].toUpperCase()
        : '?';

    return Material(
      color: conv.unread
          ? AppColors.primaryContainer.withOpacity(0.4)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryContainer,
                    child: conv.otherUserAvatar.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              conv.otherUserAvatar,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                initial,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            initial,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.otherUserName,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: conv.unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          relativeTime,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: conv.unread
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontSize: 11,
                            fontWeight:
                                conv.unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessageBody.isEmpty
                                ? 'Belum ada pesan'
                                : conv.lastMessageBody,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: conv.unread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: conv.unread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Context type badge
                    _ContextBadge(contextType: conv.contextType),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Context Badge ───────────────────────────────────────────────────────────

class _ContextBadge extends StatelessWidget {
  final String contextType;
  const _ContextBadge({required this.contextType});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (contextType.toLowerCase()) {
      case 'post':
        bg = AppColors.statusOpenLight;
        fg = AppColors.statusOpen;
        label = 'Postingan';
        icon = Icons.article_rounded;
        break;
      case 'donation':
        bg = AppColors.urgencyLowLight;
        fg = AppColors.urgencyLow;
        label = 'Donasi';
        icon = Icons.volunteer_activism_rounded;
        break;
      default:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = contextType;
        icon = Icons.chat_bubble_outline_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: fg),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: fg,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ─── Empty & Error Views ─────────────────────────────────────────────────────

class _EmptyConvsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada percakapan',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai chat dari halaman titik bantuan\natau detail postingan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;
  const _NoResultsView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Tidak ditemukan', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Tidak ada percakapan dengan kata kunci "$query"',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('Gagal memuat percakapan', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(error,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
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
