// lib/features/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/notification_service.dart';
import 'login_screen.dart';

class _OnboardingPage {
  final String title;
  final String description;
  final Color bgColor;
  final Color illustrationBg;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.illustrationBg,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _notifPermissionRequested = false;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Temukan Titik\nBantuan',
      description:
          'Cari lokasi bantuan makanan, medis, atau pakaian terdekat dari posisi Anda dengan mudah melalui peta interaktif.',
      bgColor: Color(0xFFE8F5F0),
      illustrationBg: Color(0xFF26A69A),
    ),
    _OnboardingPage(
      title: 'Berbagi ke\nSesama',
      description:
          'Jadilah bagian dari perubahan. Laporkan titik bantuan atau salurkan donasi anda langsung kepada yang membutuhkan.',
      bgColor: Color(0xFFF5F7F6),
      illustrationBg: Color(0xFFFFFFFF),
    ),
    _OnboardingPage(
      title: 'Transparansi\nKomunitas',
      description:
          'Pantau setiap bantuan yang tersalurkan melalui dokumentasi foto dan sistem verifikasi berbasis lokasi.',
      bgColor: Color(0xFFF5F7F6),
      illustrationBg: Color(0xFFDCEEEB),
    ),
    // Halaman ke-4: izin notifikasi
    _OnboardingPage(
      title: 'Aktifkan\nNotifikasi',
      description:
          'Agar tidak ketinggalan update donasi dan pesan penting, aktifkan notifikasi sekarang.',
      bgColor: Color(0xFFF0F4FF),
      illustrationBg: Color(0xFFD6E4FF),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Minta izin notifikasi, lalu arahkan ke Setelan sistem jika diperlukan.
  Future<void> _requestNotificationPermission() async {
    if (_notifPermissionRequested) {
      _goToLogin();
      return;
    }
    _notifPermissionRequested = true;

    final status = await NotificationService.instance.requestPermission();

    if (!mounted) return;

    if (status == NotificationPermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notifikasi aktif! Anda akan mendapat update terbaru.'),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _goToLogin();
    } else if (status == NotificationPermissionStatus.deniedForever) {
      // Izin ditolak permanen — arahkan ke setelan sistem agar user bisa
      // mengaktifkan notifikasi background secara manual.
      if (!mounted) return;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Buka Setelan Notifikasi'),
          content: const Text(
            'Izin notifikasi diblokir. Buka Setelan perangkat untuk mengaktifkan '
            'notifikasi Ada Titik! termasuk notifikasi background (saat app tidak aktif).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lewati'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Buka Setelan'),
            ),
          ],
        ),
      );
      if (shouldOpen == true) {
        // Buka halaman setelan notifikasi sistem perangkat
        await NotificationService.instance.openSystemNotificationSettings();
      }
      if (mounted) _goToLogin();
    } else {
      // Denied (bukan permanen) — tampilkan dialog penjelasan dengan opsi
      // langsung ke setelan agar user bisa aktifkan notifikasi background.
      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Notifikasi Dinonaktifkan'),
          content: const Text(
            'Tanpa notifikasi, Anda mungkin ketinggalan update donasi dan pesan penting.\n\n'
            'Anda bisa mengaktifkan notifikasi kapan saja di Setelan perangkat → '
            'Ada Titik! → Notifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: const Text('Lewati'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'settings'),
              child: Text(
                'Buka Setelan',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
      if (action == 'settings') {
        await NotificationService.instance.openSystemNotificationSettings();
      }
      if (mounted) _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isNotifPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: _pages[_currentPage].bgColor,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => _buildPage(context, index, size),
          ),
          Positioned(
            top: 56,
            right: 20,
            child: GestureDetector(
              onTap: _goToLogin,
              child: Text(
                'Lewati',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(isNotifPage: isNotifPage),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, int index, Size size) {
    final page = _pages[index];
    return Column(
      children: [
        const SizedBox(height: 80),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildIllustration(index, page),
          ),
        ),
        const Expanded(flex: 4, child: SizedBox()),
      ],
    );
  }

  Widget _buildIllustration(int index, _OnboardingPage page) {
    if (index == 0) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: page.illustrationBg,
          shape: BoxShape.circle,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 240,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Positioned(
                        left: 20.0 + i * 38,
                        bottom: 20,
                        child: Container(
                          width: 28,
                          height: 50.0 + (i % 3) * 20,
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(0.3 + i * 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 30,
                      right: 40,
                      child: _MapMarker(
                        icon: Icons.restaurant_rounded,
                        color: Colors.orange,
                        label: 'FOOD\nHELP',
                      ),
                    ),
                    Positioned(
                      top: 60,
                      left: 20,
                      child: _MapMarker(
                        icon: Icons.medical_services_rounded,
                        color: Colors.blue,
                        label: 'MEDICAL\nAID',
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 20,
                      child: _MapMarker(
                        icon: Icons.volunteer_activism_rounded,
                        color: AppColors.accent,
                        label: 'CLOTHES\nDONATION',
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 50,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ADA TITIK',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Find and offer help in your community',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (index == 1) {
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'COMMUNITY & CARE',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Person3D(color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite_rounded,
                      color: Colors.pink, size: 28),
                  const SizedBox(width: 8),
                  _Person3D(color: const Color(0xFFF57C00)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'VOLUNTEER. DONATE. SUPPORT.',
                style:
                    AppTextStyles.captionUppercase.copyWith(fontSize: 9),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppColors.primary
                          : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (index == 2) {
      return Container(
        decoration: BoxDecoration(
          color: page.illustrationBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.accent.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 100, height: 8, color: AppColors.accentLight),
                      const SizedBox(height: 6),
                      Container(
                          width: 60,
                          height: 8,
                          color:
                              AppColors.accentLight.withOpacity(0.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'TRUST, TRANSPARENCY,\nTRACKING IMPACT',
                style: AppTextStyles.captionUppercase.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'VERIFIED',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Halaman notifikasi (index == 3)
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: page.illustrationBg,
          shape: BoxShape.circle,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Titik baru di dekatmu!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_rounded,
                        color: Colors.teal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pesan baru dari komunitas',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBottomSheet({required bool isNotifPage}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_pages[_currentPage].title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: 12),
          Text(
            _pages[_currentPage].description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          if (isNotifPage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifikasi dibutuhkan agar Anda tetap mendapat update '
                      'donasi & pesan bahkan saat app ditutup.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              if (isNotifPage)
                Row(
                  children: [
                    TextButton(
                      onPressed: _goToLogin,
                      child: Text(
                        'Lewati',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon:
                          const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Aktifkan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(130, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: AppTextStyles.buttonMedium,
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _nextPage,
                  icon:
                      const Icon(Icons.chevron_right_rounded, size: 20),
                  label: const Text('Lanjut'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: AppTextStyles.buttonMedium,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MapMarker({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: Colors.white.withOpacity(0.8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Person3D extends StatelessWidget {
  final Color color;
  const _Person3D({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.3),
          child: Icon(Icons.person_rounded, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
