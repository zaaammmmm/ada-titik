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
        data: {
          'email': email,
        },
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Permintaan reset password berhasil. Cek email Anda.'),
          ),
        );
        context.go('/login');
        return;
      }

      final msg = (res.data?['message'] ?? res.data?['error'])?.toString();
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
              Form(
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
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: const Icon(Icons.email_outlined,
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
                        child: Text(
                            _isLoading ? 'Mengirim...' : 'Kirim Instruksi'),
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
          ),
        ),
      ),
    );
  }
}
