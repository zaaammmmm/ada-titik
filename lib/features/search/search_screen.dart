// lib/features/search/search_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/mock_data.dart';
import '../../shared/models/models.dart';
import '../donation/request_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Semua';
  String _selectedUrgency = 'Semua';
  String _selectedStatus = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Pangan',
    'Medis',
    'Pendidikan',
    'Infrastruktur',
    'Pakaian',
    'Lainnya',
  ];

  final List<String> _urgencies = ['Semua', 'Mendesak', 'Normal', 'Rendah'];
  final List<String> _statuses = ['Semua', 'Open', 'On Progress', 'Completed'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DonationRequest> get _filteredResults {
    return MockData.activeRequests.where((req) {
      final matchesQuery =
          _query.isEmpty ||
          req.title.toLowerCase().contains(_query.toLowerCase()) ||
          req.location.toLowerCase().contains(_query.toLowerCase()) ||
          req.category.toLowerCase().contains(_query.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'Semua' ||
          req.category.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          );

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Cari bantuan, kategori, lokasi...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter:',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDropdownChip('Urgensi', _urgencies, _selectedUrgency,
                    (v) => setState(() => _selectedUrgency = v!)),
                const SizedBox(width: 8),
                _buildDropdownChip('Status', _statuses, _selectedStatus,
                    (v) => setState(() => _selectedStatus = v!)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _buildDropdownChip(
    String label,
    List<String> items,
    String selected,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: AppTextStyles.labelSmall),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildResults() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil ditemukan',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau filter yang berbeda',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildResultCard(context, results[i]),
    );
  }

  Widget _buildResultCard(BuildContext context, DonationRequest req) {
    Color urgencyColor;
    Color urgencyBg;
    String urgencyLabel;

    switch (req.urgency) {
      case UrgencyLevel.urgent:
        urgencyColor = AppColors.urgencyHigh;
        urgencyBg = AppColors.urgencyHighLight;
        urgencyLabel = 'Mendesak';
        break;
      case UrgencyLevel.normal:
        urgencyColor = AppColors.urgencyMedium;
        urgencyBg = AppColors.urgencyMediumLight;
        urgencyLabel = 'Normal';
        break;
      case UrgencyLevel.low:
        urgencyColor = AppColors.urgencyLow;
        urgencyBg = AppColors.urgencyLowLight;
        urgencyLabel = 'Rendah';
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(request: req),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left urgency indicator
            Container(
              width: 4,
              height: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: urgencyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: urgencyBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          urgencyLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: urgencyColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        req.category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    req.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${req.location} · ${req.distanceKm} km',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
