// lib/features/donation/add_titik_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import 'dart:io';
import 'dart:convert';

import 'package:latlong2/latlong.dart';

import 'package:image_picker/image_picker.dart';

import '../../features/donation/data/donation_repository.dart';
import 'location_picker_screen.dart';
import '../../core/services/location_service.dart';

class AddTitikScreen extends StatefulWidget {
  const AddTitikScreen({super.key});

  @override
  State<AddTitikScreen> createState() => _AddTitikScreenState();
}

class _AddTitikScreenState extends State<AddTitikScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();

  final _picker = ImagePicker();
  XFile? _pickedPhoto;

  // Requirement: urgency level tidak ditampilkan saat add titik komunitas,
  // dan default selalu urgent.
  UrgencyLevel _selectedUrgency = UrgencyLevel.urgent;
  double _latitude = -7.7956;
  double _longitude = 110.3695;

  // Category selection (UI labels)
  String _selectedCategory = 'Food & Water';

  final List<String> _categories = [
    'Semua',
    'Food & Water',
    'Medical',
    'Education',
    'Infrastructure',
    'Clothes',
    'Other',
  ];

  final _repository = const DonationRepository();

  Future<void> _pickPhoto(ImageSource source) async {
    final res = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (res == null) return;
    setState(() => _pickedPhoto = res);
  }

  Future<String> _photoToDataUrl(XFile file) async {
    // Backend expects `photo_url`. Without a backend upload service,
    // we send a data URL as a portable representation.
    final bytes = await File(file.path).readAsBytes();
    final base64Str = base64Encode(bytes);
    final parts = file.name.split('.');
    final ext = parts.isNotEmpty ? parts.last : 'jpg';
    final mime = switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpeg' || 'jpg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,$base64Str';
  }

  Future<void> _createDonation() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      throw Exception('Title and description are required');
    }

    if (_pickedPhoto == null) {
      throw Exception('Photo Evidence is required');
    }

    // 1) create donation point
    final created = await _repository.createDonation(
      title: title,
      description: description,
      latitude: _latitude,
      longitude: _longitude,
      urgency: _selectedUrgency,
      category: _mapCategoryToBackend(_selectedCategory),
      goalAmount: double.tryParse(
            _goalController.text.trim().replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0.0,
    );

    // 2) upload documentation (photo evidence)
    final dataUrl = await _photoToDataUrl(_pickedPhoto!);
    await _repository.uploadDocumentation(
      pointId: created.id,
      photoUrl: dataUrl,
      caption: null,
    );
  }

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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Bottled water needed for 5 families',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Category
                  _sectionLabel('Category'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.where((c) => c != 'Semua').map((c) {
                      final isSelected = _selectedCategory == c;
                      return ChoiceChip(
                        label: Text(c),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = c),
                        selectedColor: AppColors.primary.withOpacity(0.12),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Goals
                  _sectionLabel('Goals'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _goalController,
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
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Provide details about the situation...',
                      filled: true,
                      fillColor: Colors.white,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Urgency level tidak ditampilkan (default urgent)
                  const SizedBox(height: 18),
                  // Location
                  _sectionLabel('Location'),
                  const SizedBox(height: 8),
                  _locationPicker(),
                  const SizedBox(height: 24),
                  // Publish button
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _createDonation();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Titik berhasil dibuat!')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membuat titik: $e')),
                        );
                      }
                    },
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

  String _mapCategoryToBackend(String uiValue) {
    // Map UI label to backend category value.
    // Backend currently uses strings like: Pangan, Medis, Pendidikan, Infrastruktur, Pakaian.
    return switch (uiValue) {
      'Food & Water' => 'Pangan',
      'Medical' => 'Medis',
      'Education' => 'Pendidikan',
      'Infrastructure' => 'Infrastruktur',
      'Clothes' => 'Pakaian',
      'Other' => 'Lainnya',
      // If someone picks 'Semua', fallback to generic
      'Semua' => 'Umum',
      _ => 'Umum',
    };
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: AppTextStyles.titleSmall);
  }

  Widget _photoUploadBox() {
    return InkWell(
      onTap: () => _pickPhoto(ImageSource.gallery),
      onLongPress: () => _pickPhoto(ImageSource.camera),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: _pickedPhoto == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 32,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to upload or take a photo',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              )
            : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Photo selected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    try {
                      final pos =
                          await LocationService.instance.getCurrentPosition();
                      if (!context.mounted) return;
                      if (pos == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Aktifkan GPS untuk menentukan lokasi.'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _latitude = pos.latitude;
                        _longitude = pos.longitude;
                      });
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal mendapatkan lokasi saat ini.'),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.my_location_rounded,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          '📍 Gunakan Lokasi Saya',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: AppColors.divider),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initialPosition: LatLng(_latitude, _longitude),
                        ),
                      ),
                    );

                    if (!context.mounted) return;
                    if (result == null) return;
                    setState(() {
                      _latitude = result.latitude;
                      _longitude = result.longitude;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.map_rounded,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          '🗺 Pilih di Peta',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFC8DFC4),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: _GridMapPainter(),
                  child: Container(),
                ),
              ),
              Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppColors.urgencyHigh,
                  size: 40,
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Koordinat: ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
