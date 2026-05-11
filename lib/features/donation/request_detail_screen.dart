// lib/features/donation/request_detail_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

class RequestDetailScreen extends StatelessWidget {
  final DonationRequest request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  request.imageUrl != null
                      ? Image.network(
                          request.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Urgency badge
                  Positioned(
                    top: 100,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.urgencyHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            request.urgency == UrgencyLevel.urgent
                                ? 'High Urgency'
                                : 'Normal',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(request.title, style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 10),
                  // Meta
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(request.timeAgo, style: AppTextStyles.bodySmall),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(request.authorName, style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress
                  DonationProgressBar(
                    collected: request.collectedAmount,
                    goal: request.goalAmount,
                    collectedLabel:
                        '${request.collectedAmount.toInt()} Terkumpul',
                    goalLabel:
                        request.goalText ??
                        'Goal: ${request.goalAmount.toInt()}',
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Description
                  Text('Description', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    request.description,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: request.tags
                        .map((t) => TagChip(label: t))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Location
                  Text('Location Detail', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  // Map placeholder
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFD7ECD4),
                    ),
                    child: Stack(
                      children: [
                        // Simulated map roads
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _MapPainter(),
                            child: Container(),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            color: AppColors.urgencyHigh,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.location,
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              'Dekat Warung Bu Agus, Depok, Sleman, Yogyakarta.',
                              style: AppTextStyles.bodySmall,
                            ),
                            Text(
                              'Jarak : ${request.distanceKm} Km',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Take Action
                  Text('Take Action', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Your help is crucial. Navigate to the location to provide assistance or materials.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Navigate button
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Navigate Here'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.handshake_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Offer Help Online',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Icon(
          Icons.medical_services_rounded,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6C84E)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    // Simulate roads
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      paint,
    );

    final thin = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      thin,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.7, size.height),
      thin,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
