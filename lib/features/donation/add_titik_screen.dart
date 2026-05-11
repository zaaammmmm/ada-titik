// lib/features/donation/add_titik_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';

class AddTitikScreen extends StatefulWidget {
  const AddTitikScreen({super.key});

  @override
  State<AddTitikScreen> createState() => _AddTitikScreenState();
}

class _AddTitikScreenState extends State<AddTitikScreen> {
  UrgencyLevel _selectedUrgency = UrgencyLevel.urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Text(
                    'Tambahkan Titik',
                    style: AppTextStyles.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Evidence
                  _sectionLabel('Photo Evidence'),
                  const SizedBox(height: 8),
                  _photoUploadBox(),
                  const SizedBox(height: 18),
                  // Title
                  _sectionLabel('Title of Need'),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g., Bottled water needed for 5 families',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Goals
                  _sectionLabel('Goals'),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g., 10Kg',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description
                  _sectionLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Provide details about the situation...',
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Urgency Level
                  _sectionLabel('Urgency Level'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _urgencyOption(
                        UrgencyLevel.low,
                        'Low',
                        AppColors.urgencyLow,
                      ),
                      const SizedBox(width: 10),
                      _urgencyOption(
                        UrgencyLevel.normal,
                        'Normal',
                        AppColors.urgencyMedium,
                      ),
                      const SizedBox(width: 10),
                      _urgencyOption(
                        UrgencyLevel.urgent,
                        'Urgent',
                        AppColors.urgencyHigh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Location
                  _sectionLabel('Location'),
                  const SizedBox(height: 8),
                  _locationPicker(),
                  const SizedBox(height: 24),
                  // Publish button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.location_on_rounded, size: 18),
                    label: const Text('Publish Point'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: AppTextStyles.titleSmall);
  }

  Widget _photoUploadBox() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 32,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 6),
          Text('Tap to upload or take a photo', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _urgencyOption(UrgencyLevel level, String label, Color color) {
    final isSelected = _selectedUrgency == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedUrgency = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationPicker() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFC8DFC4),
      ),
      child: Stack(
        children: [
          // Map background simulation
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CustomPaint(painter: _GridMapPainter(), child: Container()),
          ),
          // Pin
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.urgencyHigh,
              size: 40,
            ),
          ),
          // Pin location button
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text('Pin Location', style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9DC99A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Roads
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, 0),
      Offset(size.width * 0.6, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );

    final yellow = Paint()
      ..color = const Color(0xFFE6C84E)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      yellow,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      yellow,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
