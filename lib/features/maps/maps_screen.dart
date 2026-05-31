// lib/features/maps/maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/location_service.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../donation/data/donation_repository.dart';
import '../donation/request_detail_screen.dart';
import '../chat/chat_screen.dart';
import '../notification/notification_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late Future<List<DonationRequest>> _nearbyFuture;
  final MapController _mapController = MapController();

  LatLng _center = LocationService.defaultCenter;

  Position? _userPosition;
  bool _loadingGps = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _nearbyFuture = _loadNearby();

    _initGps();
  }

  Future<void> _initGps() async {
    if (!mounted) return;
    setState(() {
      _loadingGps = true;
    });

    final pos = await LocationService.instance.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      setState(() {
        _userPosition = pos;
        _center = LocationService.positionToLatLng(pos);
        _loadingGps = false;
        _nearbyFuture = _loadNearby();
      });

      _mapController.move(_center, 14);
    } else {
      setState(() {
        _userPosition = null;
        _center = LocationService.defaultCenter;
        _loadingGps = false;
        _nearbyFuture = _loadNearby();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktifkan GPS untuk pengalaman terbaik'),
        ),
      );
    }
  }

  Future<List<DonationRequest>> _loadNearby() async {
    final repo = DonationRepository();
    return repo.getNearby(
      lat: _center.latitude,
      lng: _center.longitude,
      radiusMeters: 5000,
      statuses: [RequestStatus.open, RequestStatus.onProgress],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdaTitikAppBar(
        title: 'Maps',
        showAvatar: false,
        onNotification: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          if (_loadingGps)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),

          // Interactive Map using flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.adatitik.app',
                // Batasi pemakaian agar tidak terlalu banyak request tile
                minZoom: 3,
                maxZoom: 17,
                keepBuffer: 3,
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LocationService.positionToLatLng(_userPosition!),
                      width: 44,
                      height: 44,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              FutureBuilder<List<DonationRequest>>(
                future: _nearbyFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final nearby = snapshot.data!;
                  final query = _searchQuery.trim().toLowerCase();
                  final filtered = query.isEmpty
                      ? nearby
                      : nearby.where((r) {
                          return r.title.toLowerCase().contains(query) ||
                              r.description.toLowerCase().contains(query) ||
                              r.category.toLowerCase().contains(query) ||
                              r.location.toLowerCase().contains(query);
                        }).toList();

                  return MarkerLayer(
                    markers: filtered.map((req) {
                      // Adjust mock data to scatter around the center for demo purposes
                      // If the backend returns real data, this will place markers correctly
                      return Marker(
                        point: LatLng(req.latitude, req.longitude),
                        width: 44,
                        height: 44,
                        child: _UrgencyMarker(
                          color: _urgencyColor(req.urgency),
                          icon: _urgencyIcon(req.urgency),
                          onTap: () => _showPointBottomSheet(context, req),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),

          // FAB: kembali ke lokasiku
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () {
                if (_userPosition == null) return;
                _mapController.move(_center, 14);
              },
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Lokasiku'),
            ),
          ),

          // Search (client-side filter for markers)

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textLight),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  hintText: 'Search lokasi / kategori / keyword...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showPointBottomSheet(BuildContext context, DonationRequest req) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PointBottomSheet(request: req),
    );
  }

  Color _urgencyColor(UrgencyLevel u) {
    return switch (u) {
      UrgencyLevel.urgent => AppColors.urgencyHigh,
      UrgencyLevel.normal => AppColors.urgencyMedium,
      UrgencyLevel.low => AppColors.urgencyLow,
    };
  }

  IconData _urgencyIcon(UrgencyLevel u) {
    return switch (u) {
      UrgencyLevel.urgent => Icons.warning_rounded,
      UrgencyLevel.normal => Icons.info_outline_rounded,
      UrgencyLevel.low => Icons.eco_rounded,
    };
  }
}

class _UrgencyMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _UrgencyMarker({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Bottom sheet Shopee-style yang muncul saat marker titik di-tap di peta.
/// Menampilkan info titik + tombol "Hubungi Komunitas" dengan konteks titik
/// (judul, kategori, lokasi) yang langsung masuk ke chat bubble.
class _PointBottomSheet extends StatelessWidget {
  final DonationRequest request;
  const _PointBottomSheet({required this.request});

  static const List<String> _quickMessages = [
    'Apakah titik bantuan ini masih aktif?',
    'Berapa banyak bantuan yang masih dibutuhkan?',
    'Saya ingin berangkat membantu, bagaimana caranya?',
    'Apakah masih ada yang dibutuhkan selain yang tertulis?',
  ];

  void _openChat(BuildContext context, {String? initialMessage}) {
    final targetUserId = request.createdById;
    final postId = int.tryParse(request.id);
    if (targetUserId == null || targetUserId.isEmpty || postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka chat untuk titik ini.')),
      );
      return;
    }
    Navigator.pop(context); // tutup bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          targetUserId: targetUserId,
          contextId: postId,
          contextType: 'donation_point',
          contextTitle: request.title,
          contextSummary:
              '${request.category} · ${request.location.isNotEmpty ? request.location : "Lihat peta"}',
          initialMessage: initialMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Titik info card (konteks seperti Shopee)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: request.imageUrl != null
                      ? Image.network(
                          request.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderThumb(),
                        )
                      : _placeholderThumb(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${request.category} · ${request.authorName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              request.location.isNotEmpty
                                  ? request.location
                                  : 'Lihat peta',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Tanya ke Komunitas',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),

          // Quick message chips (Shopee-style)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickMessages.map((msg) {
              return GestureDetector(
                onTap: () => _openChat(context, initialMessage: msg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(request: request),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Lihat Detail'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Hubungi Komunitas'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.primaryContainer,
      child: const Icon(
        Icons.volunteer_activism_rounded,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}
