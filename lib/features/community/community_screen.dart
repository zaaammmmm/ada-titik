// lib/features/community/community_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/community/community_write_screen.dart';
import '../../features/community/comments_screen.dart';

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
  // ✅ FIXED: gunakan CommunityRepository yang benar, bukan DonationRepository
  final CommunityRepository _communityRepo = const CommunityRepository();
  // Tetap butuh DonationRepository untuk cek role user di FAB
  final DonationRepository _donationRepo = const DonationRepository();

  // optimistic like state per post
  final Map<String, bool> _likedByMeByPostId = {};
  final Map<String, int> _likesCountByPostId = {};
  final Map<String, bool> _likeLoadingByPostId = {};

  // ✅ FIXED: satu future per tab — bukan satu future yang sama untuk semua tab
  late Future<List<FeedPost>> _terbaruFuture;
  late Future<List<FeedPost>> _populerFuture;
  late Future<List<FeedPost>> _diskusiFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _refreshAll();
    WidgetsBinding.instance.addObserver(this);
    // ✨ TODO L: Autorefresh Community Feed setiap 90 detik
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 90), (_) {
      if (_appInForeground && mounted) _refreshAll();
    });
  }

  // ✅ FIXED: load dari /api/community/posts dengan tab parameter yang benar
  void _refreshAll() {
    setState(() {
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
    super.dispose();
  }

  Future<void> _handleLike(String postId) async {
    final current = _likedByMeByPostId[postId];
    final currentCount = _likesCountByPostId[postId];

    // set loading + optimistic toggle
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

      // tetap refresh agar data lain (mis. comments) sinkron
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likeLoadingByPostId[postId] = false;
        // rollback ke nilai sebelumnya jika ada
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

// ✅ FIXED: terima future sebagai parameter agar setiap tab berbeda
  Widget _buildFeed(Future<List<FeedPost>> future) {
    // optimistic UI uses local maps
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

        // apply optimistic maps onto feed items
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada postingan di tab ini.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
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
              );
            },
          ),
        );
      },
    );
  }
}

// ✅ FIXED: FAB dipisah jadi widget tersendiri agar stateful sendiri
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
            // Jika post berhasil dibuat, refresh feed
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

  const _FeedCard({
    required this.post,
    this.onLike,
    this.isLikeLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    Text(
                      post.authorName,
                      style: AppTextStyles.titleSmall,
                    ),
                    Text(
                      post.authorRole,
                      style: AppTextStyles.bodySmall,
                    ),
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
                      builder: (context) {
                        return ReportDialog(
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
                        );
                      },
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
          // Content
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
          ),
          // Instagram-like Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // image
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
                  // subtle gradient for depth
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
// Like button
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                      Text(
                        '${post.likes}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

// Comment button
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
                      Text(
                        '${post.comments}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Time
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
    );
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
