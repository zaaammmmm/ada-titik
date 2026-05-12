// lib/features/admin/admin_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/auth_storage.dart';
import '../auth/login_screen.dart';
import 'admin_report_detail_screen.dart';
import 'admin_reports_screen.dart';
import 'data/admin_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _repository = const AdminRepository();
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _statsFuture = _repository.getStats();
      _reportsFuture = _repository.getReports(status: 'pending', limit: 5);
    });
  }

  String _formatNumber(dynamic value) {
    if (value is num) {
      return value.toInt().toString();
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return '0';
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'Terverifikasi';
      case 'dismissed':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu Verifikasi';
      default:
        return status?.toString() ?? 'Unknown';
    }
  }

  String _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'green';
      case 'dismissed':
        return 'yellow';
      case 'pending':
        return 'orange';
      default:
        return 'neutral';
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Baru saja';
    return createdAt;
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await _repository.updateReportStatus(reportId: reportId, status: status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Laporan diperbarui menjadi $status.')),
      );
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui laporan: $e')),
      );
    }
  }

  Future<void> _deletePoint(String? pointId) async {
    if (pointId == null || pointId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada point_id untuk dihapus.')),
      );
      return;
    }

    try {
      await _repository.deletePoint(pointId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titik berhasil dihapus.')),
      );
      _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus titik: $e')),
      );
    }
  }

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
            // _buildLogoutButton(context),
            // const SizedBox(height: 24),
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
        'Admin Panel',
        style: AppTextStyles.brandTitle.copyWith(fontSize: 20),
      ),
      centerTitle: false,
      titleSpacing: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          color: const Color.fromARGB(255, 92, 26, 26),
          tooltip: 'Logout',
          onPressed: () async {
            await AuthStorage.clear();

            if (!context.mounted) return;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (_) => false,
            );
          },
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
              label: 'Hapus Titik Invalid',
              color: AppColors.urgencyHigh,
              onTap: () => _showInfoDialog(
                context,
                'Pilih laporan untuk menghapus titik invalid',
                'Gunakan tombol Tinjau di setiap laporan untuk menandai laporan valid atau tidak valid terlebih dahulu.',
              ),
            ),
            const SizedBox(width: 10),
            _AdminActionButton(
              icon: Icons.monitor_outlined,
              label: 'Refresh Data',
              color: AppColors.primary,
              onTap: _refreshData,
            ),
          ],
        ),
      ],
    );
  }

  void _showInfoDialog(
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
              'Tutup',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildLogoutButton(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 48,
  //     child: ElevatedButton.icon(
  //       onPressed: () async {
  //         await AuthStorage.clear();

  //         if (!context.mounted) return;

  //         Navigator.of(context).pushAndRemoveUntil(
  //           MaterialPageRoute(
  //             builder: (_) => const LoginScreen(),
  //           ),
  //           (_) => false,
  //         );
  //       },
  //       icon: const Icon(Icons.logout_rounded, size: 20),
  //       label: Text(
  //         'Logout Admin',
  //         style: AppTextStyles.buttonMedium.copyWith(
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.red.shade700,
  //         foregroundColor: Colors.white,
  //         elevation: 0,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(14),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Gagal memuat statistik admin',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalUsers = _formatNumber(stats['total_users']);
        final totalPoints = _formatNumber(stats['total_points']);
        final completedPoints = _formatNumber(stats['completed_points']);
        final pendingReports = _formatNumber(stats['pending_reports']);

        return Column(
          children: [
            _StatCard(
              label: 'TOTAL PENGGUNA',
              value: totalUsers,
              sub: 'Terdaftar di sistem',
              subIsPositive: null,
              icon: Icons.people_outlined,
              iconBg: AppColors.surfaceVariant,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'TOTAL TITIK',
              value: totalPoints,
              sub: 'Titik aktif publik',
              subIsPositive: null,
              icon: Icons.location_on_outlined,
              iconBg: AppColors.surfaceVariant,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'TITIK SELESAI',
              value: completedPoints,
              sub: 'Titik selesai',
              subIsPositive: true,
              icon: Icons.check_circle_outlined,
              iconBg: AppColors.surfaceVariant,
            ),
            const SizedBox(height: 12),
            _StatCard(
              label: 'LAPORAN PENDING',
              value: pendingReports,
              sub: 'Perlu verifikasi',
              subIsPositive: false,
              icon: Icons.report_outlined,
              iconBg: const Color(0xFFFFEBEE),
              valueColor: AppColors.urgencyHigh,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerifikasiLaporan(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Gagal memuat laporan: ${snapshot.error}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        final reports = snapshot.data ?? [];

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
                  Text('Verifikasi Laporan',
                      style: AppTextStyles.headlineSmall),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminReportsScreen(),
                      ),
                    ),
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
              if (reports.isEmpty)
                Text('Tidak ada laporan pending saat ini',
                    style: AppTextStyles.bodyMedium)
              else
                ...List.generate(reports.length, (i) {
                  final report = reports[i];
                  return Column(
                    children: [
                      _buildReportItem(context, report),
                      if (i < reports.length - 1)
                        const Divider(height: 20, color: AppColors.divider),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportItem(BuildContext context, Map<String, dynamic> report) {
    final reportId =
        report['report_id']?.toString() ?? report['id']?.toString() ?? '';
    final pointId = report['point_id']?.toString();
    final title = report['title']?.toString() ??
        report['reason']?.toString() ??
        'Laporan titik bantuan';
    final description = report['description']?.toString() ??
        report['reason']?.toString() ??
        'Tidak ada deskripsi';
    final status = report['status']?.toString() ?? 'pending';
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(status);
    final createdAt = _timeAgo(
        report['created_at']?.toString() ?? report['createdAt']?.toString());

    final iconData = report['icon'] != null
        ? Icons.report_gmailerrorred
        : Icons.report_outlined;

    final isPending = status.toLowerCase() == 'pending';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor == 'green'
                ? AppColors.urgencyLowLight
                : statusColor == 'yellow'
                    ? AppColors.urgencyMediumLight
                    : AppColors.urgencyHighLight,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 2),
              Text(description, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor == 'green'
                          ? AppColors.urgencyLowLight
                          : statusColor == 'yellow'
                              ? AppColors.urgencyMediumLight
                              : AppColors.statusProgressLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: statusColor == 'green'
                            ? AppColors.urgencyLow
                            : statusColor == 'yellow'
                                ? AppColors.urgencyMedium
                                : AppColors.statusProgress,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('ID: $reportId',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                  const SizedBox(width: 6),
                  Text('· $createdAt',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isPending) ...[
                    _ActionButton(
                      label: 'Resolve',
                      color: AppColors.primary,
                      onTap: () => _updateReportStatus(reportId, 'resolved'),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Dismiss',
                      color: AppColors.urgencyHigh,
                      onTap: () => _updateReportStatus(reportId, 'dismissed'),
                    ),
                  ],
                  _ActionButton(
                    label: isPending ? 'Tinjau' : 'Lihat Detail',
                    color: AppColors.surfaceVariant,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminReportDetailScreen(
                          report: report,
                          onActionComplete: _refreshData,
                        ),
                      ),
                    ),
                  ),
                  if (pointId != null && pointId.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'Hapus Titik',
                      color: AppColors.urgencyHighLight,
                      onTap: () => _deletePoint(pointId),
                    ),
                  ],
                ],
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == AppColors.surfaceVariant
            ? AppColors.textPrimary
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: color == AppColors.surfaceVariant
              ? AppColors.textPrimary
              : Colors.white,
          fontWeight: FontWeight.w600,
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (subIcon != null) ...[
                      Icon(subIcon, size: 12, color: subColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      sub,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: subColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
