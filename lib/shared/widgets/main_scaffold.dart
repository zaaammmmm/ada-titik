// lib/shared/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../features/home/home_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/maps/maps_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/donation/add_titik_screen.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddTitikSheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showAddTitikSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTitikScreen(),
    );
  }

  // Map tap index → actual screen (skip index 2 = FAB)
  static const List<Widget> _screens = [
    HomeScreen(),     // 0
    CommunityScreen(), // 1
    SizedBox(),       // 2 (FAB placeholder, not shown)
    MapsScreen(),     // 3
    ProfileScreen(),  // 4
  ];

  int get _displayIndex {
    if (_currentIndex < 2) return _currentIndex;
    if (_currentIndex == 2) return 0;
    return _currentIndex - 1; // 3→2, 4→3
  }

  List<Widget> get _stackScreens =>
      [_screens[0], _screens[1], _screens[3], _screens[4]];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _displayIndex,
        children: _stackScreens,
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
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(
                1,
                Icons.people_rounded,
                Icons.people_outline_rounded,
                'Community',
              ),
              _buildFABItem(),
              _buildNavItem(3, Icons.map_rounded, Icons.map_outlined, 'Maps'),
              _buildNavItem(
                4,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
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
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
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
