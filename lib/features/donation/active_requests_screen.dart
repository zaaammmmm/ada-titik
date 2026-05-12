// lib/features/donation/active_requests_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'data/donation_repository.dart';
import '../../shared/models/models.dart';

import '../../shared/widgets/app_widgets.dart';
import 'request_detail_screen.dart';

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  bool _isListView = true;
  String _selectedFilter = 'All Types';
  final List<String> _filters = [
    'All Types',
    'Food & Water',
    'Medical',
    'Clothes',
    'Infra',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Requests'),
        leading: const BackButton(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Requests', style: AppTextStyles.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  'Find nearby community members in need of assistance.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                // View toggle
                Row(
                  children: [
                    _viewToggle(true, Icons.list_rounded, 'List'),
                    const SizedBox(width: 8),
                    _viewToggle(false, Icons.map_outlined, 'Map'),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterBtn('≡', 'Filters'),
                      const SizedBox(width: 8),
                      ..._filters.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChipWidget(
                            label: f,
                            isSelected: _selectedFilter == f,
                            onTap: () => setState(() => _selectedFilter = f),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Loading requests from backend...',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<DonationRequest>>(
              future: DonationRepository().getAll(
                status: RequestStatus.open,
                page: 1,
                limit: 20,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load requests',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'No requests found',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _RequestCard(
                      request: req,
                      isNearest: index == 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(request: req),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggle(bool isList, IconData icon, String label) {
    final isActive = _isListView == isList;
    return GestureDetector(
      onTap: () => setState(() => _isListView = isList),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Text('≡', style: AppTextStyles.labelMedium),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DonationRequest request;
  final bool isNearest;
  final VoidCallback onTap;
  const _RequestCard({
    required this.request,
    required this.isNearest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isNearest)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.navigation_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nearest to you',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: request.authorAvatar != null
                            ? NetworkImage(request.authorAvatar!)
                            : null,
                        backgroundColor: AppColors.primaryContainer,
                        child: request.authorAvatar == null
                            ? const Icon(Icons.person_rounded)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.authorName,
                            style: AppTextStyles.titleSmall,
                          ),
                          Text(request.timeAgo, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      UrgencyBadge(urgency: request.urgency),
                      _categoryChip(request.category),
                      _distanceChip(request.distanceKm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request.title, style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    request.description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'View Details',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
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

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }

  Widget _distanceChip(double km) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 2),
          Text(
            '${km.toStringAsFixed(1)} km',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
