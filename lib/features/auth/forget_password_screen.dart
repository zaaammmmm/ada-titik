// lib/features/auth/forget_password_screen.dart
//
// PERUBAHAN dari versi sebelumnya:
// - Tampilkan tombol "Masukkan Token Reset" setelah request berhasil
//   (untuk dev: jika ada dev_reset_token di response, tampilkan langsung di dialog).
// - Navigasi ke /reset-password setelah 200 OK.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/app_widgets.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _inlineError;
  bool _requestSent = false;   // sudah berhasil kirim forgot-password
  String? _devToken;           // dev_reset_token dari response (jika ada)
  String? _devExpiresAt;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();

    setState(() {
      _inlineError = null;
      _isLoading = true;
    });

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'email': email},
      );

      final body = res.data ?? {};

      // Backend selalu return 200 (anti email-enumeration)
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _requestSent = true;
          // Dev mode: token ikut di response jika RESET_TOKEN_IN_RESPONSE=true
          _devToken = body['dev_reset_token']?.toString();
          _devExpiresAt = body['expires_at']?.toString();
        });
        return;
      }

      final msg = (body['message'] ?? body['error'])?.toString();
      setState(() => _inlineError = msg ?? 'Gagal mengirim permintaan reset.');
    } on DioException catch (e) {
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
      } else {
        setState(() =>
            _inlineError = serverMsg ?? 'Gagal reset password ($status).');
      }
    } catch (_) {
      setState(() => _inlineError = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToResetScreen() {
    // Kirim token awal jika tersedia (dev mode), supaya field sudah terisi
    context.push('/reset-password', extra: _devToken);
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppLogo(size: 72),
              const SizedBox(height: 14),
              Text(
                'Reset password',
                style: AppTextStyles.brandTitle.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan email Anda. Kami akan mengirim instruksi reset password.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              if (_requestSent) _buildSuccessView() else _buildForm(emailRegex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusCompletedLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.statusCompleted, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Jika email terdaftar, instruksi reset password telah dikirim.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.statusCompleted),
                ),
              ),
            ],
          ),
        ),

        // Dev mode: tampilkan token jika ada
        if (_devToken != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.developer_mode,
                        size: 16, color: Color(0xFFF57F17)),
                    const SizedBox(width: 6),
                    Text(
                      'DEV MODE — Token Reset',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFF57F17),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _devToken!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFF37474F),
                  ),
                ),
                if (_devExpiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Berlaku hingga: $_devExpiresAt',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToResetScreen,
            child: const Text('Masukkan Token & Reset Password'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _requestSent = false;
              _devToken = null;
            });
          },
          child: const Text('Kirim Ulang'),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Kembali ke Login'),
        ),
      ],
    );
  }

  Widget _buildForm(RegExp emailRegex) {
    return Form(
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
              if (!emailRegex.hasMatch(value)) {
                return 'Format email tidak valid.';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined,
                  color: AppColors.textLight, size: 20),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_inlineError != null) ...[
            const SizedBox(height: 12),
            Text(
              _inlineError!,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetLink,
              child: Text(_isLoading ? 'Mengirim...' : 'Kirim Instruksi'),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }
}
