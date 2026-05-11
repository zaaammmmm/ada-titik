// lib/features/notification/notification_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifikasi', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Tandai Semua',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSectionLabel('Hari Ini'),
          _buildNotifItem(
            icon: Icons.location_on_rounded,
            iconBg: AppColors.urgencyHighLight,
            iconColor: AppColors.urgencyHigh,
            title: 'Bantuan Mendesak Terdekat',
            subtitle:
                'Ada permintaan tabung oksigen baru di Jl. Kaliurang KM 5, hanya 0.3 km dari lokasi Anda.',
            time: '30 mnt lalu',
            isUnread: true,
          ),
          _buildNotifItem(
            icon: Icons.check_circle_rounded,
            iconBg: AppColors.statusCompletedLight,
            iconColor: AppColors.statusCompleted,
            title: 'Donasi Berhasil Disalurkan',
            subtitle:
                'Sembako untuk RW 07 Condong Catur telah berhasil diterima oleh penerima manfaat.',
            time: '2 jam lalu',
            isUnread: true,
          ),
          _buildNotifItem(
            icon: Icons.people_rounded,
            iconBg: AppColors.primaryContainer,
            iconColor: AppColors.primary,
            title: 'Komentar Baru di Post Anda',
            subtitle:
                'Ahmad Ridwan dan 3 orang lainnya mengomentari postingan distribusi sembako Anda.',
            time: '4 jam lalu',
            isUnread: false,
          ),
          _buildSectionLabel('Kemarin'),
          _buildNotifItem(
            icon: Icons.volunteer_activism_rounded,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            title: 'Permintaan Donasi Baru',
            subtitle:
                'Perbaikan Atap Sekolah Dasar 04 membutuhkan bantuan Anda. Dana terkumpul 62%.',
            time: 'Kemarin, 14:32',
            isUnread: false,
          ),
          _buildNotifItem(
            icon: Icons.verified_rounded,
            iconBg: AppColors.primaryContainer,
            iconColor: AppColors.primary,
            title: 'Akun Terverifikasi',
            subtitle:
                'Selamat! Akun Anda telah berhasil diverifikasi sebagai Verified Member.',
            time: 'Kemarin, 09:00',
            isUnread: false,
          ),
          _buildSectionLabel('Minggu Ini'),
          _buildNotifItem(
            icon: Icons.sync_rounded,
            iconBg: AppColors.statusProgressLight,
            iconColor: AppColors.statusProgress,
            title: 'Status Bantuan Diperbarui',
            subtitle:
                'Bantuan Sembako Warga Isolasi RW 07 kini berstatus "On Progress". Estimasi selesai 2 hari.',
            time: '3 hari lalu',
            isUnread: false,
          ),
          _buildNotifItem(
            icon: Icons.campaign_rounded,
            iconBg: AppColors.urgencyMediumLight,
            iconColor: AppColors.urgencyMedium,
            title: 'Pengumuman Komunitas',
            subtitle:
                'Gerakan Jumat Berbagi akan diadakan minggu ini. Daftarkan diri Anda sebagai relawan sekarang!',
            time: '5 hari lalu',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: AppTextStyles.captionUppercase.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotifItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      color: isUnread ? AppColors.primaryContainer.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textLight,
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
