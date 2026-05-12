// lib/features/community/community_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final Future<List<FeedPost>> _feedFuture;
  final DonationRepository _repo = DonationRepository();
  final List<String> _tabs = ['Terbaru', 'Populer', 'Diskusi'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _feedFuture = _repo.getNearbyNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Community Aid',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(
              Icons.people_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
        bottom: TabBar(
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFeed(), _buildFeed(), _buildFeed()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildFeed() {
    return FutureBuilder<List<FeedPost>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gagal memuat komunitas. Silakan coba lagi.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final feed = snapshot.data ?? [];
        if (feed.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada pembaruan komunitas saat ini.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: feed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, index) => _FeedCard(post: feed[index]),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedPost post;
  const _FeedCard({required this.post});

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
              UserAvatar(avatarUrl: null, name: post.authorName, size: 38),
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
              const SizedBox(width: 4),
              Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
          ),
          // Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.primaryContainer,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.textLight,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Action row
          Row(
            children: [
              _actionBtn(Icons.thumb_up_outlined, '${post.likes}'),
              const SizedBox(width: 16),
              _actionBtn(Icons.chat_bubble_outline_rounded, '${post.comments}'),
              const Spacer(),
              Icon(
                Icons.share_outlined,
                size: 18,
                color: AppColors.textSecondary,
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

  Widget _actionBtn(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
