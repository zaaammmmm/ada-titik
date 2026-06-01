import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_globals.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_storage.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_session.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _inlineError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    setState(() {
      _inlineError = null;
      _isLoading = true;
    });

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (res.statusCode == 200) {
        final token = res.data?['token'];

        if (token is! String || token.isEmpty) {
          setState(() => _inlineError = 'Token tidak ditemukan dari backend.');
          return;
        }

        try {
          await AuthStorage.writeToken(token);
        } catch (e) {
          setState(() => _inlineError = 'Gagal menyimpan sesi login.');
          return;
        }

        // Pasang Supabase token → realtime authenticated (RLS notifications/chat).
        final supabaseToken = res.data?['supabase_token'];
        if (supabaseToken is String && supabaseToken.isNotEmpty) {
          await SupabaseSession.setToken(supabaseToken);
        }

        final profile = await DonationRepository().getProfile();

        if (!mounted) return;

        ref.read(authProvider.notifier).setTokenAndUser(
              token: token,
              user: profile,
            );

        if (!mounted) return;

        // Routing + alert berbasis role.
        final dest = profile.isAdmin ? '/admin' : '/home';
        context.go(dest);
        _showRoleWelcome(profile);

        return;
      }

      if (res.statusCode == 401) {
        setState(() => _inlineError = 'Email atau password salah.');
        return;
      }

      final msg = (res.data?['message'] ?? res.data?['error'])?.toString();
      setState(() => _inlineError = msg ?? 'Login gagal (${res.statusCode}).');
    } on DioException catch (e) {
      // DioException pada web umumnya karena CORS atau network error
      final status = e.response?.statusCode;
      final serverMsg = (e.response?.data is Map)
          ? ((e.response?.data as Map)['message'] ??
                  (e.response?.data as Map)['error'])
              ?.toString()
          : null;

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        setState(() => _inlineError =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        setState(() => _inlineError =
            'Koneksi timeout. Server mungkin sedang sibuk, coba lagi.');
      } else {
        setState(() => _inlineError =
            serverMsg ?? 'Login gagal${status != null ? ' ($status)' : ''}.');
      }
    } catch (e) {
      setState(
          () => _inlineError = 'Terjadi kesalahan tak terduga. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Alert sambutan berbasis role — tampil setelah pindah ke halaman tujuan
  /// (pakai messenger global agar tidak hilang saat navigasi).
  void _showRoleWelcome(UserModel user) {
    final firstName = user.name.trim().split(' ').first;
    final (String message, IconData icon, Color color) = switch (user.role.toLowerCase()) {
      'admin' => (
          'Selamat datang, Admin $firstName. Ada laporan menunggu ditinjau.',
          Icons.shield_rounded,
          AppColors.primary,
        ),
      'komunitas' => (
          'Halo, $firstName! Kelola titik & terhubung dengan para donatur.',
          Icons.diversity_3_rounded,
          AppColors.primary,
        ),
      _ => (
          'Selamat datang kembali, $firstName! Yuk lihat siapa yang butuh bantuan hari ini.',
          Icons.volunteer_activism_rounded,
          AppColors.primary,
        ),
    };

    rootMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              AppLogo(size: 80),
              const SizedBox(height: 20),
              Text(
                'Ada Titik',
                style: AppTextStyles.brandTitle.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Masuk untuk mulai salurkan\nkepedulian Anda secara nyata',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _buildForm(emailRegex),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: Text(_isLoading ? 'Masuk…' : 'Masuk'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau lanjut dengan',
                        style: AppTextStyles.bodySmall),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _socialBtn(Icons.g_mobiledata_rounded, 'Google')),
                  const SizedBox(width: 12),
                  Expanded(child: _socialBtn(Icons.apple_rounded, 'Apple')),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      )),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      'Daftar Sekarang',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(RegExp emailRegex) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMAIL', style: AppTextStyles.captionUppercase),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email wajib diisi.';
                if (!emailRegex.hasMatch(value))
                  return 'Format email tidak valid.';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppColors.textLight, size: 20),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PASSWORD', style: AppTextStyles.captionUppercase),
                GestureDetector(
                  onTap: () => context.go('/forget-password'),
                  child: Text(
                    'Lupa Password?',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              autocorrect: false,
              enableSuggestions: false,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Password wajib diisi.';
                if (value.length < 6) return 'Password minimal 6 karakter.';
                return null;
              },
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: AppColors.textLight, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 10),
              Text(
                _inlineError!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label) {
    return Tooltip(
      message: 'Segera hadir',
      child: OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        label: Text(
          label,
          style:
              AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
