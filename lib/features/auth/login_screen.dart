// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../core/network/auth_storage.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final navigator = Navigator.of(context);

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);
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
        if (token is String && token.isNotEmpty) {
          await AuthStorage.writeToken(token);
        }

        Widget nextScreen = const MainScaffold();

        try {
          final profile = await DonationRepository().getProfile();
          if (profile.isAdmin) {
            nextScreen = const AdminScreen();
          }
        } catch (_) {
          // Fallback to default main scaffold if profile fetch fails.
        }

        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      } else {
        _showError('Login gagal (${res.statusCode})');
      }
    } catch (e) {
      _showError('Login gagal. Periksa koneksi/URL backend.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Logo
              AppLogo(size: 80),
              const SizedBox(height: 20),
              // Title
              Text(
                'Ada Titik?',
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
              // Form
              _buildForm(),
              const SizedBox(height: 20),
// Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: Text(_isLoading ? 'Logging in...' : 'Login'),
              ),

              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'atau lanjut dengan',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),
              // Social login
              Row(
                children: [
                  Expanded(
                    child: _socialBtn(Icons.g_mobiledata_rounded, 'Google'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _socialBtn(Icons.apple_rounded, 'Apple')),
                ],
              ),
              const SizedBox(height: 32),
              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
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

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EMAIL', style: AppTextStyles.captionUppercase),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.textLight,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PASSWORD', style: AppTextStyles.captionUppercase),
              Text(
                'Lupa Password?',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textLight,
                size: 20,
              ),
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
        ],
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: _login,
      icon: Icon(icon, size: 20, color: AppColors.textPrimary),
      label: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
