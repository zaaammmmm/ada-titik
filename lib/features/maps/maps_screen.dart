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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdaTitikAppBar(
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
                keepBuffer: 5,
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RequestDetailScreen(request: req),
                              ),
                            );
                          },
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
