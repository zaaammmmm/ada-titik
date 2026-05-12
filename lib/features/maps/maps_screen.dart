// lib/features/maps/maps_screen.dart
import 'package:flutter/material.dart';

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
  Future<List<DonationRequest>> _loadNearby() async {
    // TODO: replace with real GPS coordinates.
    // Backend expects lat/lng + token (token is attached by ApiClient interceptor).
    const lat = -7.7956; // Yogyakarta
    const lng = 110.3695;

    final repo = DonationRepository();
    return repo.getNearby(lat: lat, lng: lng, radiusMeters: 5000);
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
          // Map placeholder
          _buildMapPlaceholder(context),

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

          // Heatmap overlay
          ..._buildHeatmapOverlay(context),

          // Markers from /api/donations/nearby
          ..._buildMarkers(context),

          // Cluster marker placeholder
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width * 0.45,
            child: _ClusterMarker(count: 12),
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

  Widget _buildMapPlaceholder(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xFF1B3A5C),
      child: CustomPaint(painter: _WorldMapPainter(), child: Container()),
    );
  }

  List<Widget> _buildHeatmapOverlay(BuildContext context) {
    // Public endpoint: no token required.
    final repo = DonationRepository();

    return [
      FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.getHeatmap(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final heat = snapshot.data!;

          // TODO: heatmap coordinate -> screen position.
          // For now, show dots weighted by `weight`.
          return Stack(
            children: [
              for (int i = 0; i < heat.length; i++)
                Positioned(
                  left: 20 + (i % 4) * 40.0,
                  top: 120 + (i ~/ 4) * 48.0,
                  child: _HeatmapDot(
                    color: _heatWeightColor(heat[i]['weight']),
                    size: _heatWeightSize(heat[i]['weight']),
                    opacity: _heatWeightOpacity(heat[i]['weight']),
                  ),
                ),
            ],
          );
        },
      ),
    ];
  }

  Color _heatWeightColor(dynamic weight) {
    final w = (weight is num) ? weight.toInt() : int.tryParse('$weight') ?? 0;
    return switch (w) {
      3 => AppColors.urgencyHigh,
      2 => AppColors.urgencyMedium,
      1 => AppColors.urgencyLow,
      _ => AppColors.primary,
    };
  }

  double _heatWeightSize(dynamic weight) {
    final w = (weight is num) ? weight.toInt() : int.tryParse('$weight') ?? 0;
    return switch (w) {
      3 => 18,
      2 => 14,
      1 => 10,
      _ => 12,
    };
  }

  double _heatWeightOpacity(dynamic weight) {
    final w = (weight is num) ? weight.toInt() : int.tryParse('$weight') ?? 0;
    return switch (w) {
      3 => 0.55,
      2 => 0.4,
      1 => 0.28,
      _ => 0.3,
    };
  }

  List<Widget> _buildMarkers(BuildContext context) {
    return [
      FutureBuilder<List<DonationRequest>>(
        future: _loadNearby(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final nearby = snapshot.data!;
          if (nearby.isEmpty) return const SizedBox.shrink();

          // TODO: map coordinate -> screen coordinate.
          // For now, show a simple stacked marker layout near top-left.
          return Stack(
            children: [
              for (int i = 0; i < nearby.length; i++)
                Positioned(
                  left: 18 + (i % 3) * 46.0,
                  top: 160 + (i ~/ 3) * 54.0,
                  child: _UrgencyMarker(
                    color: _urgencyColor(nearby[i].urgency),
                    icon: _urgencyIcon(nearby[i].urgency),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RequestDetailScreen(request: nearby[i]),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    ];
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

class _HeatmapDot extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _HeatmapDot({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  final int count;
  const _ClusterMarker({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          '$count',
          style: AppTextStyles.titleSmall.copyWith(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
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

class _WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A5F8F)
      ..style = PaintingStyle.fill;

    // Draw landmass blobs (simplified)
    final path = Path();

    // North America blob
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.18, size.height * 0.32),
        width: 70,
        height: 90,
      ),
    );
    // South America
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.23, size.height * 0.55),
        width: 45,
        height: 65,
      ),
    );
    // Europe
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.26),
        width: 55,
        height: 45,
      ),
    );
    // Africa
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: 55,
        height: 75,
      ),
    );
    // Asia
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.32),
        width: 120,
        height: 80,
      ),
    );
    // Australia
    path.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.8, size.height * 0.6),
        width: 55,
        height: 40,
      ),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
