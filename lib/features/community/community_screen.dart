// lib/features/community/community_screen.dart
//
// PERUBAHAN dari versi sebelumnya:
// - Integrasi Supabase Realtime untuk community_posts (migration v6):
//   subscribeToCommunityPosts() → auto-refresh feed saat ada INSERT baru.
// - Autorefresh timer tetap dipertahankan sebagai fallback.
// - Toast "Ada postingan baru!" muncul saat realtime event masuk.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_realtime_service.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/community/community_write_screen.dart';
import '../../features/community/comments_screen.dart';
import '../../features/community/feed_post_detail_screen.dart';
import '../../features/community/report_dialog.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  final List<String> _tabs = ['Terbaru', 'Populer', 'Diskusi'];

  Timer? _autoRefreshTimer;
  bool _appInForeground = true;
  final CommunityRepository _communityRepo = const CommunityRepository();
  final DonationRepository _donationRepo = const DonationRepository();

  // ✅ Realtime service untuk community_posts
  final SupabaseRealtimeService _realtimeService = SupabaseRealtimeService();
  bool _hasNewPost = false; // banner "ada postingan baru"

  // Optimistic like state
  final Map<String, bool> _likedByMeByPostId = {};
  final Map<String, int> _likesCountByPostId = {};
  final Map<String, bool> _likeLoadingByPostId = {};

  late Future<List<FeedPost>> _terbaruFuture;
  late Future<List<FeedPost>> _populerFuture;
  late Future<List<FeedPost>> _diskusiFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshAll();
    WidgetsBinding.instance.addObserver(this);

    // Autorefresh setiap 90 detik sebagai fallback
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (_appInForeground && mounted) _refreshAll();
    });

    // ✅ Subscribe Supabase Realtime untuk community_posts
    _realtimeService.subscribeToCommunityPosts(
      onInsert: () {
        if (!mounted) return;
        // Tampilkan banner "ada postingan baru" dan refresh tab Terbaru
        setState(() => _hasNewPost = true);
        // Jika user sedang di tab Terbaru → langsung refresh
        if (_tabController.index == 0) {
          setState(() {
            _terbaruFuture = _communityRepo.getPosts(tab: 'terbaru');
          });
        }
      },
    );
  }

  void _refreshAll() {
    setState(() {
      _hasNewPost = false;
      _terbaruFuture = _communityRepo.getPosts(tab: 'terbaru');
      _populerFuture = _communityRepo.getPosts(tab: 'populer');
      _diskusiFuture = _communityRepo.getPosts(tab: 'diskusi');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _realtimeService.unsubscribeFromCommunityPosts();
    super.dispose();
  }

  Future<void> _handleLike(String postId) async {
    HapticFeedback.mediumImpact(); // feedback taktil saat like
    final current = _likedByMeByPostId[postId];
    final currentCount = _likesCountByPostId[postId];

    setState(() {
      _likeLoadingByPostId[postId] = true;
      final nextLiked = current == null ? true : !current;
      final baseCount = currentCount ?? 0;
      final nextCount =
          nextLiked ? baseCount + 1 : (baseCount - 1).clamp(0, 1 << 30);
      _likedByMeByPostId[postId] = nextLiked;
      _likesCountByPostId[postId] = nextCount;
    });

    try {
      final result = await _communityRepo.toggleLike(postId);
      if (!mounted) return;
      setState(() {
        _likedByMeByPostId[postId] = result.liked;
        _likesCountByPostId[postId] = result.likesCount;
        _likeLoadingByPostId[postId] = false;
      });
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likeLoadingByPostId[postId] = false;
        if (current != null) _likedByMeByPostId[postId] = current;
        if (currentCount != null) _likesCountByPostId[postId] = currentCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal like postingan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdaTitikAppBar(
        title: 'Komunitas',
        onNotification: () {},
      ),
      body: Column(
        children: [
          // ✅ Banner "ada postingan baru" dari realtime
          if (_hasNewPost)
            GestureDetector(
              onTap: _refreshAll,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primary.withOpacity(0.12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Ada postingan baru — ketuk untuk refresh',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          TabBar(
            controller: _tabController,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            labelStyle: AppTextStyles.labelLarge,
            unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeed(_terbaruFuture),
                _buildFeed(_populerFuture),
                _buildFeed(_diskusiFuture),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _RoleFab(
        donationRepo: _donationRepo,
        onPostCreated: _refreshAll,
      ),
    );
  }

  Widget _buildFeed(Future<List<FeedPost>> future) {
    return FutureBuilder<List<FeedPost>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Gagal memuat komunitas.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refreshAll,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final feed = snapshot.data ?? [];

        final appliedFeed = feed.map((p) {
          final liked = _likedByMeByPostId.containsKey(p.id)
              ? _likedByMeByPostId[p.id]!
              : p.likedByMe;
          final likesCount = _likesCountByPostId.containsKey(p.id)
              ? _likesCountByPostId[p.id]!
              : p.likes;
          return FeedPost(
            id: p.id,
            authorName: p.authorName,
            authorAvatar: p.authorAvatar,
            authorRole: p.authorRole,
            content: p.content,
            timeAgo: p.timeAgo,
            type: p.type,
            imageUrl: p.imageUrl,
            likes: likesCount,
            comments: p.comments,
            tagLabel: p.tagLabel,
            likedByMe: liked,
            pointId: p.pointId,
            commentsList: p.commentsList,
          );
        }).toList();

        if (appliedFeed.isEmpty) {
          return const EmptyState(
            icon: Icons.forum_rounded,
            title: 'Jadi yang pertama bercerita',
            message:
                'Belum ada postingan di sini. Bagikan kabar, pertanyaan, atau kisah baikmu.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshAll(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: appliedFeed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final p = appliedFeed[index];
              return _FeedCard(
                post: p,
                isLikeLoading: _likeLoadingByPostId[p.id] ?? false,
                onLike: () => _handleLike(p.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FeedPostDetailScreen(
                      post: p,
                      onPostUpdated: (updated) {
                        // Update optimistic state di parent
                        setState(() {
                          _likedByMeByPostId[updated.id] = updated.likedByMe;
                          _likesCountByPostId[updated.id] = updated.likes;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RoleFab extends StatelessWidget {
  final DonationRepository donationRepo;
  final VoidCallback onPostCreated;

  const _RoleFab({
    required this.donationRepo,
    required this.onPostCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: donationRepo.getProfile(),
      builder: (context, snapshot) {
        final role = snapshot.data?.role.toLowerCase();
        final isKomunitas = role == 'komunitas' || role == 'community';
        if (isKomunitas != true) return const SizedBox.shrink();

        return FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityWriteScreen(),
              ),
            );
            if (result == true) onPostCreated();
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final bool isLikeLoading;
  final VoidCallback? onTap;

  const _FeedCard({
    required this.post,
    this.onLike,
    this.isLikeLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              UserAvatar(
                avatarUrl: post.authorAvatar,
                name: post.authorName,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: AppTextStyles.titleSmall),
                    Text(post.authorRole, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (post.tagLabel != null) _feedTag(post.type),
              PopupMenuButton<int>(
                tooltip: 'Opsi posting',
                onSelected: (value) async {
                  if (value == 1) {
                    await showDialog<bool>(
                      context: context,
                      builder: (context) => ReportDialog(
                        title: 'Laporkan Posting',
                        pointId: post.id,
                        defaultReason: null,
                        onSubmit: ({
                          required pointId,
                          required reason,
                        }) async {
                          await const CommunityRepository().reportPost(
                            postId: pointId,
                            reason: reason,
                          );
                        },
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<int>(
                    value: 1,
                    child: Text('Laporkan'),
                  ),
                ],
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
          ),

          // Gambar (jika ada)
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 260,
                    errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: AppColors.primaryContainer,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.textLight,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.00),
                              Colors.black.withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action row
          Row(
            children: [
              InkWell(
                onTap: isLikeLoading ? null : onLike,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      isLikeLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              post.likedByMe
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_outlined,
                              size: 18,
                              color: post.likedByMe
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                      const SizedBox(width: 4),
                      Text('${post.likes}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(postId: post.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('${post.comments}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              Text(
                post.timeAgo,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      ), // closes Container
    ); // closes GestureDetector
  }

  Widget _feedTag(FeedPostType type) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
}
