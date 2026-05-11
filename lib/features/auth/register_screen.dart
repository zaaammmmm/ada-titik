// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/main_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserType _selectedType = UserType.individu;
  bool _agreedToTerms = false;

  void _register() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
      (_) => false,
    );
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
                ),
                const SizedBox(height: 14),
                _formField(
                  'Email',
                  Icons.email_outlined,
                  'a@example.com',
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _formField(
                  'Password',
                  Icons.lock_outline_rounded,
                  '••••••••',
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _formField(
                  'Konfirmasi Password',
                  Icons.lock_outline_rounded,
                  '••••••••',
                  obscure: true,
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
                  onPressed: _agreedToTerms ? _register : null,
                  child: const Text('Daftar Sekarang'),
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
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleSmall),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 18),
          ),
        ),
      ],
    );
  }
}
