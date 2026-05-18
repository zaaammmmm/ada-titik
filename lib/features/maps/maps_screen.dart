// lib/features/maps/maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
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
  final MapController _mapController = MapController();
  final LatLng _center = const LatLng(-7.7956, 110.3695); // Yogyakarta

  Future<List<DonationRequest>> _loadNearby() async {
    final repo = DonationRepository();
    return repo.getNearby(lat: _center.latitude, lng: _center.longitude, radiusMeters: 5000);
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
                userAgentPackageName: 'com.example.ada_titik',
              ),
              FutureBuilder<List<DonationRequest>>(
                future: _loadNearby(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  final nearby = snapshot.data!;
                  return MarkerLayer(
                    markers: nearby.map((req) {
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
                                builder: (_) => RequestDetailScreen(request: req),
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

          // Search bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: AppSearchBar(
              hint: 'Search locations, or keywords...',
              showFilter: true,
            ),
          ),

          // FAB
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
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
