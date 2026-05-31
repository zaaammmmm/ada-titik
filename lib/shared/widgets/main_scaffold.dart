// lib/shared/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/home/home_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/chat/conversations_list_screen.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/community/data/community_repository.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/donation/add_titik_screen.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  bool _hasUnreadChat = false;
  bool _hasUnreadCommunity = false;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _refreshUnreadIndicators();
  }

  Future<void> _refreshUnreadIndicators() async {
    try {
      final chatRepo = const ChatRepository();
      final communityRepo = const CommunityRepository();

      final convs = await chatRepo.listConversations(page: 1, limit: 50);
      if (!mounted) return;
      final hasUnreadChat = convs.any((c) => c.unread);
      final unreadCount = convs.where((c) => c.unread).length;

      // Community indicator (baseline by timestamp/id order):
      // We'll consider it "new" if we can find posts newer than the previously cached first post.
      // If cache is empty (first run), we don't show dot.
      final posts =
          await communityRepo.getPosts(tab: 'terbaru', page: 1, limit: 10);
      if (!mounted) return;
      final hasUnreadCommunity = _isCommunityFeedNew(posts);

      setState(() {
        _hasUnreadChat = hasUnreadChat;
        _hasUnreadCommunity = hasUnreadCommunity;
        _unreadChatCount = unreadCount;
      });
    } catch (_) {
      // If API fails, keep dots off.
      if (!mounted) return;
      setState(() {
        _hasUnreadChat = false;
        _hasUnreadCommunity = false;
      });
    }
  }

  String? _communityBaselineFirstId;
  bool _isCommunityFeedNew(List<FeedPost> posts) {
    if (posts.isEmpty) return false;
    final firstId = posts.first.id;
    final baseline = _communityBaselineFirstId;

    if (baseline == null) {
      _communityBaselineFirstId = firstId;
      return false;
    }

    final isNew = firstId != baseline;
    if (isNew) _communityBaselineFirstId = firstId;
    return isNew;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddTitikSheet();

      return;
    }

    setState(() => _currentIndex = index);
  }

  Future<void> _showAddTitikSheet() async {
    // ✨ TODO C: Modal dengan dua opsi — "Tambahkan Titik" dan "Berdonasi"
    // Role guard (donatur / komunitas / admin)
    final repo = const DonationRepository();
    late final UserModel user;
    try {
      user = await repo.getProfile();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat profil untuk akses fitur.')),
      );
      return;
    }

    if (!context.mounted) return;

    final role = user.role.toLowerCase();
    final isKomunitas = role == 'komunitas';

    // ✨ Tampilkan modal bottom sheet dengan dua pilihan untuk semua role
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddActionSheet(
        isKomunitas: isKomunitas,
        onAddTitik: () {
          Navigator.pop(ctx);
          if (!context.mounted) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTitikScreen(),
          );
        },
        onBerdonasi: () {
          Navigator.pop(ctx);
          // Navigasi ke Active Requests untuk memilih titik yang ingin dibantu
          setState(() => _currentIndex = 3); // Maps tab
        },
      ),
    );
  }

  // Map tap index → actual screen (skip index 2 = FAB)
  final List<Widget?> _cachedScreens = <Widget?>[
    null, // Home
    null, // Community
    null, // Maps
    null, // Profile
  ];

  int get _displayIndex {
    if (_currentIndex < 2) return _currentIndex; // 0->0,1->1
    if (_currentIndex == 2) return 0; // FAB
    return _currentIndex - 1; // 3->2,4->3
  }

  @override
  Widget build(BuildContext context) {
    final displayIndex = _displayIndex;

    // Ensure current tab screen is created lazily.
    if (displayIndex >= 0 && displayIndex < _cachedScreens.length) {
      if (_cachedScreens[displayIndex] == null) {
        _cachedScreens[displayIndex] = switch (displayIndex) {
          0 => const HomeScreen(),
          1 => const CommunityScreen(),
          2 => const ConversationsListScreen(),
          3 => const ProfileScreen(),
          _ => const SizedBox.shrink(),
        };
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: displayIndex,
        children: List.generate(
          _cachedScreens.length,
          (i) => _cachedScreens[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(
                  0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
              _buildNavItem(
                1,
                Icons.people_rounded,
                Icons.people_outline_rounded,
                'Komunitas',
                showDot: _hasUnreadCommunity,
              ),
              _buildFABItem(),
              _buildNavItem(
                  3, Icons.chat_rounded, Icons.chat_outlined, 'Pesan',
                  showDot: _hasUnreadChat,
                  showCount: _unreadChatCount,
                ),
              _buildNavItem(
                4,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label, {
    bool showDot = false,
    int showCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final hasBadge = showDot || showCount > 0;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                if (hasBadge)
                  Positioned(
                    right: showCount > 0 ? -8 : -2,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      padding: showCount > 0
                          ? const EdgeInsets.symmetric(horizontal: 3, vertical: 1)
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: AppColors.urgencyHigh,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                      child: showCount > 0
                          ? Text(
                              showCount > 99 ? '99+' : showCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox(width: 6, height: 6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFABItem() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Add',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ TODO C: Modal sheet untuk tombol "+"
class _AddActionSheet extends StatelessWidget {
  final bool isKomunitas;
  final VoidCallback onAddTitik;
  final VoidCallback onBerdonasi;

  const _AddActionSheet({
    required this.isKomunitas,
    required this.onAddTitik,
    required this.onBerdonasi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Pilih Aksi',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 20),

          // Tambahkan Titik
          _ActionOption(
            icon: Icons.add_location_alt_rounded,
            label: 'Tambahkan Titik',
            subtitle: isKomunitas
                ? 'Buat titik bantuan baru di lokasimu'
                : 'Hanya komunitas yang dapat melakukan ini',
            enabled: isKomunitas,
            onTap: isKomunitas ? onAddTitik : null,
          ),
          const SizedBox(height: 12),

          // Berdonasi
          _ActionOption(
            icon: Icons.volunteer_activism_rounded,
            label: 'Berdonasi',
            subtitle: 'Lihat titik bantuan dan mulai berdonasi',
            enabled: true,
            onTap: onBerdonasi,
          ),
        ],
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primary : AppColors.textSecondary;
    final bg = enabled ? AppColors.primaryContainer : AppColors.surfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: enabled ? AppColors.primary : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: enabled
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withOpacity(0.7),
                      fontStyle: enabled ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (!enabled)
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
