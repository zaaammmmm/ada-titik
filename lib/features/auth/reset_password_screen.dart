// lib/features/auth/reset_password_screen.dart
//
// Screen untuk memasukkan token reset + password baru.
// Dipanggil dari ForgetPasswordScreen setelah user mendapat token
// (saat ini via server console / dev_reset_token di response).
//
// Route: /reset-password?token=<plaintext_token>
// Endpoint: POST /api/auth/reset-password

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/app_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// Token plaintext yang didapat dari email / dev_reset_token response.
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _inlineError;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _tokenCtrl = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _inlineError = null;
      _isLoading = true;
    });

    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        '/api/auth/reset-password',
        data: {
          'token': _tokenCtrl.text.trim(),
          'new_password': _passwordCtrl.text,
        },
      );

      final body = res.data ?? {};
      final success = body['success'] == true;

      if (res.statusCode == 200 && success) {
        if (!mounted) return;
        setState(() => _success = true);
        return;
      }

      // Error dari backend (400 dengan success: false)
      final errMsg = body['error']?.toString() ??
          body['message']?.toString() ??
          'Gagal mereset password.';
      setState(() => _inlineError = errMsg);
    } on DioException catch (e) {
      final body = e.response?.data;
      final serverMsg = (body is Map)
          ? (body['error'] ?? body['message'])?.toString()
          : null;

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        setState(() => _inlineError =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      } else {
        setState(() => _inlineError =
            serverMsg ?? 'Gagal reset password (${e.response?.statusCode}).');
      }
    } catch (_) {
      setState(() => _inlineError = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _success ? _buildSuccessState() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.statusCompletedLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 44,
            color: AppColors.statusCompleted,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Berhasil Direset!',
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Silakan login dengan password baru Anda.',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ke Halaman Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogo(size: 72),
        const SizedBox(height: 14),
        Text(
          'Buat Password Baru',
          style: AppTextStyles.brandTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan token reset dan password baru Anda.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Token field
              Text('TOKEN RESET', style: AppTextStyles.captionUppercase),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tokenCtrl,
                autocorrect: false,
                keyboardType: TextInputType.text,
                validator: (v) {
                  final val = (v ?? '').trim();
                  if (val.isEmpty) return 'Token wajib diisi.';
                  if (val.length < 16) return 'Token terlalu pendek.';
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Paste token dari email/console server',
                  prefixIcon: Icon(Icons.vpn_key_outlined,
                      color: AppColors.textLight, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // New password
              Text('PASSWORD BARU', style: AppTextStyles.captionUppercase),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                validator: (v) {
                  if ((v ?? '').length < 8) {
                    return 'Password minimal 8 karakter.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Min. 8 karakter',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textLight, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password
              Text('KONFIRMASI PASSWORD',
                  style: AppTextStyles.captionUppercase),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                validator: (v) {
                  if ((v ?? '') != _passwordCtrl.text) {
                    return 'Password tidak cocok.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Ulangi password baru',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textLight, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textLight,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
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

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: Text(_isLoading ? 'Menyimpan...' : 'Reset Password'),
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
        ),
      ],
    );
  }
}
