// lib/features/auth/register_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  UserType _selectedType = UserType.individu;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _roleForBackend() {
    // Postman schema.sql uses: role in ('donatur', 'komunitas', 'admin')
    switch (_selectedType) {
      case UserType.individu:
        return 'donatur';
      case UserType.organisasi:
        return 'komunitas';
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register'),
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

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Semua field wajib diisi.');
      return;
    }

    if (!_agreedToTerms) {
      _showError('Silakan setujui syarat & ketentuan.');
      return;
    }

    if (password.length < 8) {
      _showError('Password minimal 8 karakter.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Konfirmasi password tidak sesuai.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': _roleForBackend(),
        },
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        // Backend spec: Response 201: userId (no token expected)
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
          (_) => false,
        );
      } else {
        _showError('Register gagal (${res.statusCode}).');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      _showError('Register gagal${status != null ? ' ($status)' : ''}.');
    } catch (_) {
      _showError('Register gagal. Periksa koneksi/URL backend.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Create Account', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  'Join the Ada Titik? community to start\nmaking an impact.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // User Type Selection
                Text('Daftar Sebagai', style: AppTextStyles.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _typeCard(
                        UserType.individu,
                        Icons.person_rounded,
                        'Individu',
                        'Relawan / Donatur',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _typeCard(
                        UserType.organisasi,
                        Icons.business_rounded,
                        'Organisasi',
                        'Lembaga / Komunitas',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _formField(
                  'Nama Lengkap',
                  Icons.person_outline_rounded,
                  'Trikarta',
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 14),
                _formField(
                  'Email',
                  Icons.email_outlined,
                  'a@example.com',
                  type: TextInputType.emailAddress,
                  controller: _emailCtrl,
                ),
                const SizedBox(height: 14),
                _formField(
                  'Password',
                  Icons.lock_outline_rounded,
                  '••••••••',
                  obscure: true,
                  controller: _passwordCtrl,
                ),
                const SizedBox(height: 14),
                _formField(
                  'Konfirmasi Password',
                  Icons.lock_outline_rounded,
                  '••••••••',
                  obscure: true,
                  controller: _confirmPasswordCtrl,
                ),
                const SizedBox(height: 6),
                Text(
                  'Gunakan kombinasi huruf dan angka.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                // Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall,
                          children: [
                            const TextSpan(text: 'Saya menyetujui '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const TextSpan(text: ' yang berlaku.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_agreedToTerms && !_isLoading) ? _register : null,
                  child:
                      Text(_isLoading ? 'Mendaftarkan...' : 'Daftar Sekarang'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login',
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
      ),
    );
  }

  Widget _typeCard(
    UserType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isSelected ? AppColors.primary : AppColors.surfaceVariant,
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: AppTextStyles.titleSmall),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    IconData icon,
    String hint, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 18),
          ),
        ),
      ],
    );
  }
}
