// lib/features/admin/admin_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/mock_data.dart';
import '../../shared/models/models.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(context),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildVerifikasiLaporan(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryContainer,
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
      title: Text(
        'Community Aid',
        style: AppTextStyles.brandTitle.copyWith(fontSize: 20),
      ),
      centerTitle: false,
      titleSpacing: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          color: AppColors.primary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sistem Monitoring',
          style: AppTextStyles.displayMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ikhtisar kesehatan sistem dan laporan aktif.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _AdminActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Hapus Data Tidak Valid',
              color: AppColors.urgencyHigh,
              onTap: () => _showConfirmDialog(
                context,
                'Hapus Data Tidak Valid?',
                'Tindakan ini tidak dapat dibatalkan. Data yang tidak valid akan dihapus permanen.',
              ),
            ),
            const SizedBox(width: 10),
            _AdminActionButton(
              icon: Icons.monitor_outlined,
              label: 'Sistem Monitoring',
              color: AppColors.primary,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.headlineSmall),
        content: Text(content, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgencyHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        _StatCard(
          label: 'PERMINTAAN AKTIF',
          value: '1,248',
          sub: '+12% minggu ini',
          subIsPositive: true,
          icon: Icons.compare_arrows_rounded,
          iconBg: AppColors.surfaceVariant,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'LAPORAN TERVERIFIKASI',
          value: '892',
          sub: 'Menunggu: 156',
          subIsPositive: null,
          icon: Icons.verified_outlined,
          iconBg: AppColors.surfaceVariant,
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'ITEM DITANDAI',
          value: '34',
          sub: 'Memerlukan tindakan segera',
          subIsPositive: false,
          icon: Icons.flag_outlined,
          iconBg: const Color(0xFFFFEBEE),
          valueColor: AppColors.urgencyHigh,
          subIcon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildVerifikasiLaporan(BuildContext context) {
    final reports = MockData.adminReports;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verifikasi Laporan',
                style: AppTextStyles.headlineSmall,
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'LIHAT SEMUA',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(reports.length, (i) {
            final rep = reports[i];
            return Column(
              children: [
                _buildReportItem(context, rep),
                if (i < reports.length - 1)
                  const Divider(
                    height: 20,
                    color: AppColors.divider,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReportItem(BuildContext context, AdminReport report) {
    // Icon
    IconData iconData;
    Color iconColor;
    Color iconBg;

    switch (report.iconType) {
      case 'warning':
        iconData = Icons.warning_rounded;
        iconColor = AppColors.urgencyHigh;
        iconBg = AppColors.urgencyHighLight;
        break;
      case 'doc':
        iconData = Icons.description_outlined;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceVariant;
        break;
      case 'user':
        iconData = Icons.person_off_outlined;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceVariant;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = AppColors.textSecondary;
        iconBg = AppColors.surfaceVariant;
    }

    // Status badge
    Color statusColor;
    Color statusBg;

    switch (report.statusColor) {
      case 'orange':
        statusColor = AppColors.statusProgress;
        statusBg = AppColors.statusProgressLight;
        break;
      case 'yellow':
        statusColor = AppColors.urgencyMedium;
        statusBg = AppColors.urgencyMediumLight;
        break;
      case 'green':
        statusColor = AppColors.urgencyLow;
        statusBg = AppColors.urgencyLowLight;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBg = AppColors.surfaceVariant;
    }

    final isCompleted = report.statusColor == 'green';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(
                report.description,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.statusLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${report.id}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· ${report.timeAgo}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isCompleted ? 'Lihat Detail' : 'Tinjau',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool? subIsPositive; // null = neutral
  final IconData icon;
  final Color iconBg;
  final Color? valueColor;
  final IconData? subIcon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subIsPositive,
    required this.icon,
    required this.iconBg,
    this.valueColor,
    this.subIcon,
  });

  @override
  Widget build(BuildContext context) {
    Color subColor;
    if (subIsPositive == true) {
      subColor = AppColors.urgencyLow;
    } else if (subIsPositive == false) {
      subColor = AppColors.urgencyHigh;
    } else {
      subColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.captionUppercase,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (subIcon != null) ...[
                      Icon(subIcon, color: subColor, size: 14),
                      const SizedBox(width: 4),
                    ] else if (subIsPositive == true) ...[
                      Icon(Icons.trending_up, color: subColor, size: 14),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sub,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: subColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
        ],
      ),
    );
  }
}
