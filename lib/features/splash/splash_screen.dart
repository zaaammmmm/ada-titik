import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_session.dart';

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

  static const _notifPermAskedKey = 'notification_permission_asked';

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

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // Init auth (cek token tersimpan → auto-login jika ada)
    await ref.read(authProvider.notifier).init();

    // Untuk akun yang sudah login: pulihkan + refresh Supabase token agar
    // realtime authenticated (RLS notifications/chat) tanpa harus login ulang.
    if (ref.read(authProvider).isAuthed) {
      await SupabaseSession.restore();
    }

    // Minta izin notifikasi hanya SEKALI saat pertama kali buka app
    await _requestNotificationPermissionOnce();

    _navigate();
  }

  /// Tampilkan dialog izin notifikasi hanya satu kali seumur hidup install.
  Future<void> _requestNotificationPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_notifPermAskedKey) ?? false;
    if (alreadyAsked) return; // sudah pernah ditanya, skip

    // Tandai sudah ditanya sebelum meminta agar tidak muncul lagi walau user close paksa
    await prefs.setBool(_notifPermAskedKey, true);

    if (!mounted) return;

    // Tampilkan dialog penjelasan sebelum OS permission dialog
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Notifikasi?'),
        content: const Text(
          'Ada Titik ingin mengirimkan notifikasi secara real-time agar Anda '
          'tidak melewatkan update donasi, konfirmasi keberangkatan, dan '
          'pemberitahuan titik bantuan baru di sekitar Anda.\n\n'
          'Notifikasi juga akan tetap aktif di latar belakang sehingga Anda '
          'selalu mendapat kabar terbaru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti saja'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await NotificationService.instance.requestPermission();
    }
  }

  void _navigate() {
    if (_navigated) return;
    if (!mounted) return;
    _navigated = true;

    final auth = ref.read(authProvider);
    if (auth.isAuthed) {
      context.go(auth.isAdmin ? '/admin' : '/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Ada Titik',
                  style: AppTextStyles.brandTitle.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 200),
                Text(
                  'GERAKKAN KEBAIKAN DI SEKITARMU',
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
              decoration: const BoxDecoration(
                color: Color(0xFFF9A825),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
