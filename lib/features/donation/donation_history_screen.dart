// lib/features/donation/donation_history_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/mock_data.dart';
import '../../shared/models/models.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: Text('Riwayat Donasi', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppColors.textPrimary,
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Donasi Saya'),
            Tab(text: 'Kelola Bantuan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDonationsTab(),
          _buildKelolaBantuanTab(),
        ],
      ),
    );
  }

  Widget _buildDonationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDonationCard(
          title: 'Donasi – Sembako RW 07',
          amount: 'Rp 150.000',
          date: 'Oct 20, 2023',
          status: RequestStatus.completed,
          category: 'Pangan',
        ),
        const SizedBox(height: 12),
        _buildDonationCard(
          title: 'Donasi – Obat Puskesmas Maguwo',
          amount: 'Rp 350.000',
          date: 'Oct 10, 2023',
          status: RequestStatus.completed,
          category: 'Medis',
        ),
        const SizedBox(height: 12),
        _buildDonationCard(
          title: 'Bantuan Tunai Pendidikan SD Mawar',
          amount: 'Rp 500.000',
          date: 'Oct 12, 2023',
          status: RequestStatus.completed,
          category: 'Pendidikan',
        ),
      ],
    );
  }

  Widget _buildDonationCard({
    required String title,
    required String amount,
    required String date,
    required RequestStatus status,
    required String category,
  }) {
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          _StatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildKelolaBantuanTab() {
    final histories = MockData.donationHistory;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: histories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _buildHistoryCard(histories[i]),
    );
  }

  Widget _buildHistoryCard(DonationHistory history) {
    final isProgress = history.status == RequestStatus.onProgress;

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontSize: 20,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Request ID: ${history.requestId}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: history.status),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Status Updates / Final Report
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              isProgress ? 'Status Updates' : 'Final Report',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Timeline
          ...history.updates.map((update) => _buildTimelineItem(update)),

          const SizedBox(height: 14),

          // Documentation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isProgress ? 'Documentation' : 'Official Documentation',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildDocumentation(history),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(StatusUpdate update) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: update.isActive ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
              if (!update.isActive)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.divider,
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.dateStr,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(update.description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentation(DonationHistory history) {
    final isProgress = history.status == RequestStatus.onProgress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isProgress) ...[
            // Image docs
            ...history.docImages.take(2).map(
              (url) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: 90,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 70,
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // PDF doc
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LPJ_Final.pdf',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Image doc
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                history.docImages.first,
                width: 80,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 64,
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;
    IconData? icon;

    switch (status) {
      case RequestStatus.open:
        color = AppColors.statusOpen;
        bg = AppColors.statusOpenLight;
        label = 'Open';
        icon = null;
        break;
      case RequestStatus.onProgress:
        color = AppColors.statusProgress;
        bg = AppColors.statusProgressLight;
        label = 'In Progress';
        icon = Icons.sync_rounded;
        break;
      case RequestStatus.completed:
        color = AppColors.statusCompleted;
        bg = AppColors.statusCompletedLight;
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
