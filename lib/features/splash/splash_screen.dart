import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Defer decision to next frame to allow authProvider.init() to run.
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());

    _controller.forward();
  }

  Future<void> _decide() async {
    if (_navigated) return;

    final auth = ref.read(authProvider);

    // Wait until init() completes.
    if (auth.loading) return;

    _navigated = true;

    if (!context.mounted) return;

    if (auth.user == null || auth.token == null) {
      context.go('/login');
      return;
    }

    context.go(auth.isAdmin ? '/admin' : '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Fix: re-trigger navigation after auth init finishes.
    // We cannot use ref.listen in initState.
    if (!_navigated && !auth.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
    }

    // Only render UI; redirection is handled in _decide().
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                Text(
                  'Ada Titik?',
                  style: AppTextStyles.brandTitle.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 200),
                Text(
                  'EMPOWERING LOCAL IMPACT',
                  style: AppTextStyles.captionUppercase,
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentLight.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 54),
          Positioned(
            top: 26,
            child: Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
          ),
          Positioned(
            top: 27,
            left: 54,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFF9A825),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
