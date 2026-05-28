import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/app_widgets.dart';
import 'chat_screen.dart';
import 'data/chat_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdaTitikAppBar(
        showAvatar: false,
        title: 'Chat',
        onNotification: null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gagal memuat percakapan',
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Coba lagi'),
                        )
                      ],
                    ),
                  ),
                )
              : _convs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded,
                                size: 44, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada percakapan. Mulai chat dari halaman titik bantuan / detail.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        itemCount: _convs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final c = _convs[index];
                          return GestureDetector(
                            onTap: () {
                              // Masuk ke thread chat dengan men-trigger startConversation
                              // sesuai target dan context dari backend.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    targetUserId: c.otherUserId,
                                    contextType: c.contextType,
                                    contextId: c.contextId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  _ChatUserAvatar(
                                    avatarUrl: c.otherUserAvatar,
                                    name: c.otherUserName,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c.otherUserName,
                                                style: AppTextStyles.titleSmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (c.unread)
                                              Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.urgencyHigh,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.lastMessageBody,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ChatUserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;

  const _ChatUserAvatar({
    required this.avatarUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primaryContainer,
      child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _InitialAvatar(name: name);
                },
              ),
            )
          : _InitialAvatar(name: name),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String name;

  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Text(
      initial,
      style: AppTextStyles.titleMedium.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
