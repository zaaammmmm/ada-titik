// lib/features/maps/maps_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/models/mock_data.dart';
import '../donation/request_detail_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AdaTitikAppBar(onNotification: () {}),
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
          // Markers
          ..._buildMarkers(context),
          // Cluster marker
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

  List<Widget> _buildMarkers(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return [
      // Red urgent marker
      Positioned(
        top: size.height * 0.28,
        left: size.width * 0.2,
        child: _UrgencyMarker(
          color: AppColors.urgencyHigh,
          icon: Icons.warning_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RequestDetailScreen(request: MockData.activeRequests[0]),
            ),
          ),
        ),
      ),
      // Yellow normal marker
      Positioned(
        top: size.height * 0.43,
        left: size.width * 0.58,
        child: _UrgencyMarker(
          color: AppColors.urgencyMedium,
          icon: Icons.info_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RequestDetailScreen(request: MockData.activeRequests[1]),
            ),
          ),
        ),
      ),
      // Green completed marker
      Positioned(
        top: size.height * 0.54,
        left: size.width * 0.3,
        child: _UrgencyMarker(
          color: AppColors.urgencyLow,
          icon: Icons.check_circle_rounded,
          onTap: () {},
        ),
      ),
    ];
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
