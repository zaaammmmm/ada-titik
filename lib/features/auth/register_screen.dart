import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import '../../shared/models/models.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  UserType _selectedType = UserType.individu;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  String? _inlineError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _roleForBackend() {
    switch (_selectedType) {
      case UserType.individu:
        return 'donatur';
      case UserType.organisasi:
        return 'komunitas';
    }
  }

  // ✅ FIXED: regex email yang benar (single backslash di Dart raw string)
  // Sebelumnya: r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$' — double-escape, tidak valid
  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email wajib diisi.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Format email tidak valid.';
    return null;
  }

  // ✅ FIXED: minimal 8 karakter (sesuai validasi backend), bukan 6
  String? _validatePassword(String? v) {
    final value = (v ?? '');
    if (value.isEmpty) return 'Password wajib diisi.';
    if (value.length < 8) return 'Password minimal 8 karakter.';
    return null;
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_agreedToTerms) {
      setState(() => _inlineError = 'Silakan setujui syarat & ketentuan.');
      return;
    }

    setState(() {
      _inlineError = null;
      _isLoading = true;
    });

    try {
      final name = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

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
        if (!mounted) return;
        context.go('/login');
        return;
      }

      final msg = (res.data?['message'] ?? res.data?['error'])?.toString();
      setState(
          () => _inlineError = msg ?? 'Register gagal (${res.statusCode}).');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final serverMsg = (e.response?.data is Map)
          ? ((e.response?.data as Map)['message'] ??
                  (e.response?.data as Map)['error'])
              ?.toString()
          : null;
      setState(() => _inlineError =
          serverMsg ?? 'Register gagal${status != null ? ' ($status)' : ''}.');
    } catch (_) {
      setState(
          () => _inlineError = 'Register gagal. Periksa koneksi/URL backend.');
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Create Account', style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Join the Ada Titik community to start\nmaking an impact.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline_rounded,
                    controller: _nameCtrl,
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Nama wajib diisi.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _formField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 14),
                  _formField(
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordCtrl,
                    obscure: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 14),
                  _formField(
                    label: 'Konfirmasi Password',
                    icon: Icons.lock_outline_rounded,
                    controller: _confirmPasswordCtrl,
                    obscure: true,
                    validator: (v) {
                      final value = (v ?? '');
                      if (value.isEmpty)
                        return 'Konfirmasi password wajib diisi.';
                      if (value != _passwordCtrl.text) {
                        return 'Konfirmasi password tidak sesuai.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gunakan minimal 8 karakter kombinasi huruf dan angka.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 16),
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
                      onPressed:
                          (_agreedToTerms && !_isLoading) ? _register : null,
                      child: Text(
                          _isLoading ? 'Mendaftarkan...' : 'Daftar Sekarang'),
                    ),
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
                        onTap: () => context.go('/login'),
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

  Widget _formField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 18),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
