import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'admin_report_detail_screen.dart';
import 'data/admin_repository.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _repository = const AdminRepository();
  final List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _reports.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;

    setState(() {
      if (_reports.isEmpty) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final nextPage = await _repository.getReports(
        status: null,
        page: _page,
        limit: _limit,
      );
      setState(() {
        _reports.addAll(nextPage);
        _hasMore = nextPage.length == _limit;
        if (_hasMore) _page += 1;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar laporan.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'Terverifikasi';
      case 'dismissed':
        return 'Ditolak';
      case 'pending':
        return 'Menunggu';
      default:
        return status?.toString() ?? 'Tidak diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daftar Laporan',
            style: AppTextStyles.brandTitle.copyWith(fontSize: 20)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppColors.primary,
            onPressed: () => _loadReports(reset: true),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada laporan tersedia.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _reports.length) {
                      return Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _loadReports,
                                child: const Text('Muat Lebih Banyak'),
                              ),
                      );
                    }
                    final report = _reports[index];
                    final title = report['title']?.toString() ??
                        report['reason']?.toString() ??
                        'Laporan tidak bernama';
                    final status = _statusLabel(report['status']?.toString());
                    final reportId = report['report_id']?.toString() ??
                        report['id']?.toString() ??
                        '-';
                    final createdAt = report['created_at']?.toString() ??
                        report['createdAt']?.toString() ??
                        '-';

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminReportDetailScreen(
                              report: report,
                              onActionComplete: () => _loadReports(reset: true),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
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
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('ID: $reportId',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text('Dibuat: $createdAt',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
