import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../donation/data/donation_repository.dart';
import '../donation/request_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'me_repository.dart';

/// Screen baru untuk menampilkan "Aktivitas Anda" di profile.
/// Menampilkan aktivitas dari modul community:
/// - postingan user
/// - like yang diberikan user
/// - komentar yang diberikan user
///
/// Catatan: bila endpoint spesifik belum tersedia di backend, screen
/// akan menampilkan fallback/placeholder.
class UserActivityScreen extends ConsumerStatefulWidget {
  const UserActivityScreen({super.key});

  @override
  ConsumerState<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends ConsumerState<UserActivityScreen> {
  final _meRepo = const MeRepository();
  final _donationRepo = const DonationRepository();

  late Future<_ActivityBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ActivityBundle> _load() async {
    // Endpoint "aktivitas user" untuk community saat ini belum ada di FE.
    // Jadi kita buat bundle dengan cara aman:
    // - postingan: gunakan getPosts dan filter by authorName (fallback)
    // - like/komentar: gunakan placeholder sampai endpoint tersedia
    //
    // Agar tetap berguna, kita tampilkan postingan user dari feed komunitas.

    final user = await _tryGetProfile();

    // 1) Posting user
    final myPosts = await _meRepo.getMyCommunityPosts(page: 1, limit: 10);

    // Ambil beberapa item saja agar ringan.
    final limitedPosts = myPosts.take(8).toList();

    // 2) Like & komentar (endpoint /api/me/community/* v3.1)
    // Shape docs: like/comment response juga mengandung post_snapshot.
    final myLikes = await _meRepo.getMyCommunityLikes(page: 1, limit: 10);
    final myComments = await _meRepo.getMyCommunityComments(page: 1, limit: 10);

    final likedByMe = myLikes
        .map((p) => _ActivityLikeItem(
              postId: p.id,
              title: p.content,
              timeAgo: p.timeAgo,
            ))
        .take(8)
        .toList();

    final commented = myComments
        .map((p) => _ActivityCommentItem(
              postId: p.id,
              content: p.content,
              timeAgo: p.timeAgo,
            ))
        .take(8)
        .toList();

    // 3) Donation activities (accepted departures) - Fix #9
    final donationActivities =
        await _donationRepo.getUserActivity(page: 1, limit: 10);

    return _ActivityBundle(
      userName: user?.name,
      userPosts: limitedPosts,
      likedByMe: likedByMe,
      commented: commented,
      donationActivities: donationActivities,
    );
  }

  Future<UserModel?> _tryGetProfile() async {
    try {
      // DonationRepository punya getProfile.
      // AuthStorage juga ada, tapi kita tetap pakai endpoint profile.
      return await _donationRepo.getProfile();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Aktivitas Anda', style: AppTextStyles.headlineSmall),
        leading: const BackButton(),
      ),
      body: FutureBuilder<_ActivityBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat aktivitas.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _SectionHeader(
                    title: 'Aktivitas Donasi',
                    icon: Icons.volunteer_activism_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (data.donationActivities.isEmpty)
                    _EmptyState(message: 'Belum ada aktivitas donasi.')
                  else
                    ...data.donationActivities.map((a) => _DonationActivityTile(
                          activity: a,
                          onTap: () async {
                            if (a.pointId == null || a.pointId!.isEmpty) return;
                            try {
                              final req =
                                  await _donationRepo.getById(a.pointId!);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RequestDetailScreen(request: req),
                                ),
                              );
                            } catch (_) {}
                          },
                        )),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Postingan Anda',
                    icon: Icons.article_outlined,
                  ),
                  const SizedBox(height: 10),
                  if (data.userPosts.isEmpty)
                    _EmptyState(message: 'Belum ada postingan.')
                  else
                    ...data.userPosts.map((p) => _PostActivityTile(post: p)),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Like yang Anda Berikan',
                    icon: Icons.favorite_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (data.likedByMe.isEmpty)
                    _EmptyState(
                        message:
                            'Belum ada data like (endpoint belum tersedia).')
                  else
                    ...data.likedByMe.map((e) => _LikeActivityTile(item: e)),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Komentar Anda',
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  if (data.commented.isEmpty)
                    _EmptyState(
                        message:
                            'Belum ada data komentar (endpoint belum tersedia).')
                  else
                    ...data.commented.map((e) => _CommentActivityTile(item: e)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityBundle {
  final String? userName;
  final List<FeedPost> userPosts;
  final List<_ActivityLikeItem> likedByMe;
  final List<_ActivityCommentItem> commented;
  final List<ActivityItem> donationActivities;

  const _ActivityBundle({
    required this.userName,
    required this.userPosts,
    required this.likedByMe,
    required this.commented,
    this.donationActivities = const [],
  });
}

class _ActivityLikeItem {
  final String postId;
  final String title;
  final String timeAgo;

  const _ActivityLikeItem({
    required this.postId,
    required this.title,
    required this.timeAgo,
  });
}

class _ActivityCommentItem {
  final String postId;
  final String content;
  final String timeAgo;

  const _ActivityCommentItem({
    required this.postId,
    required this.content,
    required this.timeAgo,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PostActivityTile extends StatelessWidget {
  final FeedPost post;
  const _PostActivityTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.article_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.favorite_outline_rounded,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('${post.likes}', style: AppTextStyles.bodySmall),
                        const SizedBox(width: 16),
                        Icon(Icons.comment_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('${post.comments}',
                            style: AppTextStyles.bodySmall),
                        const Spacer(),
                        Text(post.timeAgo,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LikeActivityTile extends StatelessWidget {
  final _ActivityLikeItem item;
  const _LikeActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 4),
                Text(item.timeAgo,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentActivityTile extends StatelessWidget {
  final _ActivityCommentItem item;
  const _CommentActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.postId, style: AppTextStyles.titleSmall),
              ),
              Text(item.timeAgo,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DonationActivityTile extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;

  const _DonationActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.timeAgo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
