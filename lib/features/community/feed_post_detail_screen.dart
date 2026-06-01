// lib/features/community/feed_post_detail_screen.dart
//
// Screen detail untuk satu postingan community feed.
// Menampilkan konten lengkap, like, komentar, dan laporan —
// sama seperti sosial media pada umumnya.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import 'data/community_repository.dart';
import 'report_dialog.dart';

class FeedPostDetailScreen extends StatefulWidget {
  final FeedPost post;
  /// Dipanggil ketika terjadi perubahan like/komentar agar parent bisa refresh
  final void Function(FeedPost updatedPost)? onPostUpdated;

  const FeedPostDetailScreen({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  State<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends State<FeedPostDetailScreen> {
  final CommunityRepository _repo = const CommunityRepository();

  late FeedPost _post;
  bool _likeLoading = false;

  late Future<List<Map<String, dynamic>>> _commentsFuture;
  final TextEditingController _commentCtrl = TextEditingController();
  bool _submittingComment = false;
  bool _showFullContent = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _loadComments() {
    setState(() {
      _commentsFuture = _repo.getComments(_post.id, page: 1, limit: 50);
    });
  }

  Future<void> _handleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);

    final prevLiked = _post.likedByMe;
    final prevCount = _post.likes;

    // Optimistic update
    setState(() {
      _post = FeedPost(
        id: _post.id,
        authorName: _post.authorName,
        authorAvatar: _post.authorAvatar,
        authorRole: _post.authorRole,
        content: _post.content,
        timeAgo: _post.timeAgo,
        type: _post.type,
        imageUrl: _post.imageUrl,
        likes: prevLiked ? (prevCount - 1).clamp(0, 999999) : prevCount + 1,
        comments: _post.comments,
        tagLabel: _post.tagLabel,
        likedByMe: !prevLiked,
        pointId: _post.pointId,
        commentsList: _post.commentsList,
      );
    });

    try {
      final result = await _repo.toggleLike(_post.id);
      if (!mounted) return;
      setState(() {
        _post = FeedPost(
          id: _post.id,
          authorName: _post.authorName,
          authorAvatar: _post.authorAvatar,
          authorRole: _post.authorRole,
          content: _post.content,
          timeAgo: _post.timeAgo,
          type: _post.type,
          imageUrl: _post.imageUrl,
          likes: result.likesCount,
          comments: _post.comments,
          tagLabel: _post.tagLabel,
          likedByMe: result.liked,
          pointId: _post.pointId,
          commentsList: _post.commentsList,
        );
      });
      widget.onPostUpdated?.call(_post);
    } catch (_) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _post = FeedPost(
            id: _post.id,
            authorName: _post.authorName,
            authorAvatar: _post.authorAvatar,
            authorRole: _post.authorRole,
            content: _post.content,
            timeAgo: _post.timeAgo,
            type: _post.type,
            imageUrl: _post.imageUrl,
            likes: prevCount,
            comments: _post.comments,
            tagLabel: _post.tagLabel,
            likedByMe: prevLiked,
            pointId: _post.pointId,
            commentsList: _post.commentsList,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _likeLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      await _repo.addComment(_post.id, content);
      _commentCtrl.clear();
      // Update comment count
      setState(() {
        _post = FeedPost(
          id: _post.id,
          authorName: _post.authorName,
          authorAvatar: _post.authorAvatar,
          authorRole: _post.authorRole,
          content: _post.content,
          timeAgo: _post.timeAgo,
          type: _post.type,
          imageUrl: _post.imageUrl,
          likes: _post.likes,
          comments: _post.comments + 1,
          tagLabel: _post.tagLabel,
          likedByMe: _post.likedByMe,
          pointId: _post.pointId,
          commentsList: _post.commentsList,
        );
      });
      _loadComments();
      widget.onPostUpdated?.call(_post);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar terkirim!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  Future<void> _handleReport() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => ReportDialog(
        title: 'Laporkan Posting',
        pointId: _post.id,
        defaultReason: null,
        onSubmit: ({required pointId, required reason}) async {
          await _repo.reportPost(postId: pointId, reason: reason);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        title: Text('Postingan', style: AppTextStyles.headlineSmall),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Opsi',
            onSelected: (v) {
              if (v == 1) _handleReport();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Laporkan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadComments(),
              child: CustomScrollView(
                slivers: [
                  // Post card
                  SliverToBoxAdapter(child: _buildPostBody()),
                  // Divider section
                  SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Komentar (${_post.comments})',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Comments list
                  _buildCommentsList(),
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ),
          // Input komentar
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostBody() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              UserAvatar(
                avatarUrl: _post.authorAvatar,
                name: _post.authorName,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post.authorName, style: AppTextStyles.titleSmall),
                    Text(_post.authorRole,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Tag & waktu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_post.tagLabel != null) _buildTag(_post.type),
                  const SizedBox(height: 4),
                  Text(
                    _post.timeAgo,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Konten teks
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showFullContent || _post.content.length < 300
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.content,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                GestureDetector(
                  onTap: () => setState(() => _showFullContent = true),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Selengkapnya',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            secondChild: Text(
              _post.content,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            ),
          ),

          // Gambar
          if (_post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppColors.primaryContainer,
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        color: AppColors.textLight, size: 44),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Action row — like & comment count
          Row(
            children: [
              // Like button
              GestureDetector(
                onTap: _likeLoading ? null : _handleLike,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _post.likedByMe
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _likeLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _post.likedByMe
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_outlined,
                              size: 16,
                              color: _post.likedByMe
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                      const SizedBox(width: 6),
                      Text(
                        '${_post.likes} Suka',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _post.likedByMe
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: _post.likedByMe
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Comment count (dekoratif, scroll ke bawah)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${_post.comments} Komentar',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(FeedPostType type) {
    final (label, bg, fg) = switch (type) {
      FeedPostType.bantuanDibutuhkan => (
          'BANTUAN DIBUTUHKAN',
          AppColors.statusOpenLight,
          AppColors.statusOpen,
        ),
      FeedPostType.pertanyaan => (
          'PERTANYAAN',
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
        ),
      FeedPostType.updateKomunitas => (
          'UPDATE KOMUNITAS',
          const Color(0xFFF3E5F5),
          const Color(0xFF6A1B9A),
        ),
      FeedPostType.inspirasi => (
          'INSPIRASI',
          AppColors.statusProgressLight,
          AppColors.statusProgress,
        ),
      FeedPostType.kisahSukses => (
          'KISAH SUKSES',
          AppColors.statusCompletedLight,
          AppColors.statusCompleted,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: fg, fontSize: 9),
      ),
    );
  }

  Widget _buildCommentsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 40, color: AppColors.textLight),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar.\nJadi yang pertama berkomentar!',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final c = comments[i];
              return _CommentTile(comment: c);
            },
            childCount: comments.length,
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tulis komentar...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.4), width: 1.5),
                ),
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _submittingComment
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _submitComment,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(10),
                    ),
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final author = comment['author_name']?.toString() ??
        comment['user_name']?.toString() ??
        'Anonim';
    final avatar = comment['author_avatar']?.toString() ??
        comment['user_avatar']?.toString();
    final content = comment['content']?.toString() ??
        comment['body']?.toString() ??
        '';
    final rawTime = comment['created_at']?.toString() ?? '';
    final timeAgo = rawTime.isNotEmpty
        ? _formatTime(rawTime)
        : comment['time_ago']?.toString() ?? '';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(avatarUrl: avatar, name: author, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(author,
                          style: AppTextStyles.titleSmall.copyWith(
                              fontSize: 13)),
                      Text(
                        timeAgo,
                        style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
