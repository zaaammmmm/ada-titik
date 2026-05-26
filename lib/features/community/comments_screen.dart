import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/community/data/community_repository.dart';

import '../../shared/widgets/app_widgets.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommunityRepository _repo = const CommunityRepository();
  late Future<List<Map<String, dynamic>>> _future;

  final _controller = TextEditingController();
  bool _submitting = false;

  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _future = _repo.getComments(widget.postId, page: _page, limit: _limit);
  }

  Future<void> _refresh() async {
    setState(() {
      _page = 1;
      _future = _repo.getComments(widget.postId, page: _page, limit: _limit);
    });
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.addComment(widget.postId, content);
      _controller.clear();
      await _refresh();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar berhasil dikirim')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Komentar', style: AppTextStyles.headlineSmall),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Gagal memuat komentar.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Belum ada komentar. Jadilah yang pertama!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      final authorName =
                          c['author_name']?.toString() ?? 'Anonim';
                      final authorRole = c['author_role']?.toString();
                      final authorAvatar = c['author_avatar']?.toString();
                      final content = c['content']?.toString() ?? '';
                      final createdAt = c['created_at']?.toString() ??
                          c['createdAt']?.toString() ??
                          '';

                      return _CommentTile(
                        authorName: authorName,
                        authorRole: authorRole,
                        avatarUrl: authorAvatar,
                        content: content,
                        createdAt: createdAt,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tulis komentar...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(0),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String authorName;
  final String? authorRole;
  final String? avatarUrl;
  final String content;
  final String createdAt;

  const _CommentTile({
    required this.authorName,
    required this.authorRole,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(avatarUrl: avatarUrl, name: authorName, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    authorName,
                    style: AppTextStyles.titleSmall,
                  ),
                  if (authorRole != null && authorRole!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      authorRole!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
              ),
              const SizedBox(height: 6),
              if (createdAt.isNotEmpty)
                Text(
                  createdAt,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}
