import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'data/admin_repository.dart';

class AdminReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onActionComplete;

  const AdminReportDetailScreen({
    super.key,
    required this.report,
    this.onActionComplete,
  });

  @override
  State<AdminReportDetailScreen> createState() =>
      _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  final _repository = const AdminRepository();
  late Map<String, dynamic> _report;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.report);
  }

  String _label(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'Terverifikasi';
      case 'dismissed':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu Verifikasi';
      default:
        return status?.toString() ?? 'Tidak diketahui';
    }
  }

  String _createdAt() {
    return _report['created_at']?.toString() ??
        _report['createdAt']?.toString() ??
        'Tidak tersedia';
  }

  String _string(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  Future<void> _setStatus(String status) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final reportId =
          _report['report_id']?.toString() ?? _report['id']?.toString();
      if (reportId == null || reportId.isEmpty) {
        throw StateError('ID laporan tidak tersedia');
      }
      await _repository.updateReportStatus(reportId: reportId, status: status);
      setState(() {
        _report['status'] = status;
      });
      widget.onActionComplete?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status laporan diperbarui menjadi $status.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deletePoint() async {
    if (_isActionLoading) return;
    final pointId = _report['point_id']?.toString();
    if (pointId == null || pointId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada point_id untuk dihapus.')),
      );
      return;
    }

    setState(() => _isActionLoading = true);
    try {
      await _repository.deletePoint(pointId);
      widget.onActionComplete?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titik berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus titik: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _label(_report['status']?.toString());
    final pointId = _string(_report['point_id']);
    final reportId = _string(_report['report_id'] ?? _report['id']);
    final title = _string(
        _report['title'] ?? _report['reason'] ?? 'Laporan titik bantuan');
    final description =
        _string(_report['description'] ?? _report['reason'] ?? '-');
    final reportedBy = _string(_report['reporter_name'] ??
        _report['reporter_email'] ??
        _report['reported_by'] ??
        _report['user_email'] ??
        _report['user_name']);
    final ownerName = _string(_report['owner_name']);

    final isPending = _report['status']?.toString().toLowerCase() == 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detail Laporan',
            style: AppTextStyles.brandTitle.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _detailChip('Status', status),
                      _detailChip('ID Laporan', reportId),
                      if (pointId != '-') _detailChip('Point ID', pointId),
                      _detailChip('Dibuat', _createdAt()),
                      if (reportedBy != '-')
                        _detailChip('Dilaporkan oleh', reportedBy),
                      if (ownerName != '-')
                        _detailChip('Pemilik titik', ownerName),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Deskripsi', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isActionLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPending) ...[
                    ElevatedButton(
                      onPressed: () => _setStatus('resolved'),
                      child: const Text('Tandai Terverifikasi'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _setStatus('dismissed'),
                      child: const Text('Tolak Laporan'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (pointId != '-') ...[
                    OutlinedButton(
                      onPressed: _deletePoint,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.urgencyHigh,
                        side: BorderSide(color: AppColors.urgencyHigh),
                      ),
                      child: const Text('Hapus Titik Invalid'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w700)),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
