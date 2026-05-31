// lib/features/donation/active_requests_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'data/donation_repository.dart';
import '../../shared/models/models.dart';

import '../../shared/widgets/app_widgets.dart';
import 'request_detail_screen.dart';
import '../chat/chat_screen.dart';
import '../../core/services/location_service.dart';
import 'dart:math' as math;

class ActiveRequestsScreen extends StatefulWidget {
  const ActiveRequestsScreen({super.key});

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  bool _isListView = true;

  Future<List<DonationRequest>> _fetchActiveRequests() async {
    final category = _selectedFilter == 'Semua' ? null : _selectedFilter;
    final repo = const DonationRepository();

    // NOTE: jika backend tidak bisa menerima parameter kategori atau status tertentu,
    // bagian ini harus disesuaikan.

    // Fetch dua status: Open + On Progress
    final openFuture = repo.getAll(
      status: RequestStatus.open,
      category: category,
    );
    final onProgressFuture = repo.getAll(
      status: RequestStatus.onProgress,
      category: category,
    );

    final results = await Future.wait([openFuture, onProgressFuture]);
    final combined = <String, DonationRequest>{};

    for (final list in results) {
      for (final r in list) {
        combined[r.id] = r;
      }
    }
// No 4 FIX: bila backend distance_meters kosong/0, hitung jarak di FE.
    var items = combined.values.toList();

    final userPos = await LocationService.instance.getCurrentPosition();
    if (userPos != null) {
      final userLat = userPos.latitude;
      final userLng = userPos.longitude;

      for (var i = 0; i < items.length; i++) {
        final req = items[i];
        if (req.distanceKm <= 0) {
          final dMeters = _haversineMeters(
            userLat,
            userLng,
            req.latitude,
            req.longitude,
          );

          items[i] = DonationRequest(
            id: req.id,
            title: req.title,
            description: req.description,
            authorName: req.authorName,
            authorAvatar: req.authorAvatar,
            createdById: req.createdById,
            urgency: req.urgency,
            status: req.status,
            category: req.category,
            location: req.location,
            latitude: req.latitude,
            longitude: req.longitude,
            timeAgo: req.timeAgo,
            imageUrl: req.imageUrl,
            goalAmount: req.goalAmount,
            collectedAmount: req.collectedAmount,
            tags: req.tags,
            goalText: req.goalText,
            avgRating: req.avgRating,
            distanceKm: dMeters / 1000.0,
            goalUnit: req.goalUnit,
          );
        }
      }
    }

// Fix 11: Apply urgency filter
    if (_selectedUrgency != 'Semua') {
      final targetUrgency = switch (_selectedUrgency) {
        'Urgent' => UrgencyLevel.urgent,
        'Normal' => UrgencyLevel.normal,
        'Rendah' => UrgencyLevel.low,
        _ => null,
      };

      if (targetUrgency != null) {
        items = items.where((r) => r.urgency == targetUrgency).toList();
      }
    }

    return items;
  }

  double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // earth radius in meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return r * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  String _selectedFilter = 'Semua';
  String _selectedUrgency = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Pangan',
    'Medis',
    'Pendidikan',
    'Infrastruktur',
    'Pakaian',
    'Lainnya',
  ];
  final List<String> _urgencyFilters = ['Semua', 'Urgent', 'Normal', 'Rendah'];

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
                  'Temukan anggota komunitas yang membutuhkan bantuan di sekitar Anda.',
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
                // ✅ FIXED: filter chips menggunakan label Indonesia yang sesuai backend
                // Category filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterBtn('≡', 'Kategori'),
                      const SizedBox(width: 8),
                      ..._filters.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChipWidget(
                            label: f,
                            isSelected: _selectedFilter == f,
                            onTap: () => setState(() {
                              _selectedFilter = f;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Urgency filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterBtn('🔥', 'Urgensi'),
                      const SizedBox(width: 8),
                      ..._urgencyFilters.map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChipWidget(
                            label: u,
                            isSelected: _selectedUrgency == u,
                            onTap: () => setState(() {
                              _selectedUrgency = u;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<List<DonationRequest>>(
              // No 1: setelah accept, backend bisa mengubah status dari 'Open' ke 'On Progress'.
              // Solusi: tampilkan gabungan Open + On Progress.
              future: _fetchActiveRequests(),
              // Key ensures rebuild when filters change
              key: ValueKey('$_selectedFilter-$_selectedUrgency'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gagal memuat permintaan.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _selectedFilter == 'Semua'
                            ? 'Tidak ada permintaan aktif saat ini.'
                            : 'Tidak ada permintaan aktif untuk kategori "$_selectedFilter".',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: requests.length,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      return _RequestCard(request: requests[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggle(bool isList, IconData icon, String label) {
    final isSelected = _isListView == isList;
    return GestureDetector(
      onTap: () => setState(() => _isListView = isList),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DonationRequest request;
  const _RequestCard({required this.request});

  Future<void> _openChat(BuildContext context) async {
    // Backend: Start/Get conversation
    // POST /api/chats { target_user_id, context_type, context_id }
    final targetUserId = request.createdById;
    if (targetUserId == null || targetUserId.isEmpty) return;

    // context_id expects integer for context_type='post' (matches backend validators)
    // Here, Donation uses donation_points id; backend expects numeric context_id.
    final postId = int.tryParse(request.id);
    if (postId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          targetUserId: targetUserId,
          contextId: postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestDetailScreen(request: request),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.network(
                  request.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    color: AppColors.primaryContainer,
                  ),
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
                  // Progress bar donasi
                  if (request.goalAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Terkumpul',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${((request.collectedAmount / request.goalAmount) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (request.collectedAmount / request.goalAmount)
                            .clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Lihat Detail →',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      // Hubungi Komunitas (Chat)
                    ],
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
