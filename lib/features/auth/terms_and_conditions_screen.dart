import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan',
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Dengan menggunakan aplikasi Ada Titik, Anda setuju untuk mematuhi syarat dan ketentuan serta kebijakan privasi yang berlaku. Informasi yang Anda masukkan harus akurat dan sesuai kenyataan.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('1. Akun & Keamanan'),
              _sectionBody(
                'Anda bertanggung jawab untuk menjaga kerahasiaan kredensial akun Anda. Jika Anda menduga ada akses tanpa izin, segera hubungi tim kami.',
              ),
              const SizedBox(height: 18),
              _sectionTitle('2. Penggunaan Layanan'),
              _sectionBody(
                'Aplikasi digunakan untuk pelaporan titik bantuan dan penyaluran donasi secara bertanggung jawab. Konten yang melanggar hukum atau menyesatkan dapat ditindak sesuai kebijakan.',
              ),
              const SizedBox(height: 18),
              _sectionTitle('3. Kebijakan Privasi'),
              _sectionBody(
                'Data pengguna akan digunakan untuk operasional aplikasi, verifikasi, dan peningkatan layanan sesuai kebijakan privasi yang berlaku.',
              ),
              const SizedBox(height: 18),
              _sectionTitle('4. Perubahan Ketentuan'),
              _sectionBody(
                'Kami dapat memperbarui syarat dan ketentuan dari waktu ke waktu. Penggunaan aplikasi setelah perubahan dianggap sebagai persetujuan.',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Mengerti'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Versi demo — silakan sesuaikan isi resmi sesuai dokumen Anda.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTextStyles.titleMedium,
        ),
      );

  Widget _sectionBody(String text) => Text(
        text,
        style:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      );
}
