// lib/features/donation/add_titik_screen.dart
//
// Layar untuk membuat titik donasi baru.
//
// Perubahan v2 (lokasi + izin):
//   • Tombol "Gunakan Lokasi Saya" sekarang:
//       - Menampilkan loading indicator saat mencari GPS.
//       - Menangani semua kasus: serviceDisabled, permissionDenied,
//         permissionDeniedForever, pluginUnavailable, dan timeout.
//       - Menampilkan dialog aksi yang sesuai (buka Settings, pilih manual).
//   • Izin kamera/galeri diminta secara eksplisit sebelum membuka picker.
//   • Koordinat yang dipilih ditampilkan dengan format yang rapi.

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/location_service.dart';
import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';
import 'location_picker_screen.dart';

class _UnitChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _UnitChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

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

  UrgencyLevel _selectedUrgency = UrgencyLevel.urgent;
  double _latitude = LocationService.defaultCenter.latitude;
  double _longitude = LocationService.defaultCenter.longitude;
  bool _locationSet = false; // apakah lokasi sudah dipilih user (bukan default)

  bool _gettingLocation = false;
  bool _isSubmitting = false;

  String _selectedCategory = 'Food & Water';
  String _goalUnit = 'Rp'; // 'Rp' or 'Kg' - fix #15

  final List<String> _categories = [
    'Food & Water',
    'Medical',
    'Education',
    'Infrastructure',
    'Clothes',
    'Other',
  ];

  final _repository = const DonationRepository();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  // ─── Foto ────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    // Minta izin sebelum membuka picker
    if (source == ImageSource.camera) {
      final status = await ph.Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        _showPermissionDialog(
          title: 'Izin Kamera Diperlukan',
          message: 'Izinkan akses kamera untuk mengambil foto bukti.',
          onOpenSettings: () => ph.openAppSettings(),
        );
        return;
      }
    } else {
      // Galeri
      bool granted = false;
      final photos = await ph.Permission.photos.request();
      if (photos.isGranted) {
        granted = true;
      } else {
        final storage = await ph.Permission.storage.request();
        granted = storage.isGranted;
      }
      if (!granted) {
        if (!mounted) return;
        _showPermissionDialog(
          title: 'Izin Galeri Diperlukan',
          message: 'Izinkan akses galeri foto untuk memilih bukti gambar.',
          onOpenSettings: () => ph.openAppSettings(),
        );
        return;
      }
    }

    final res = await _picker.pickImage(source: source, imageQuality: 85);
    if (res == null) return;
    if (!mounted) return;
    setState(() => _pickedPhoto = res);
  }

  Future<String> _photoToDataUrl(XFile file) async {
    final bytes = await File(file.path).readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = file.name.split('.').lastOrNull ?? 'jpg';
    final mime = switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,$base64Str';
  }

  // ─── Lokasi ──────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation) return;
    setState(() => _gettingLocation = true);

    final result = await LocationService.instance.getLocationWithStatus();

    if (!mounted) return;
    setState(() => _gettingLocation = false);

    switch (result.status) {
      case LocationStatus.success:
        setState(() {
          _latitude = result.position!.latitude;
          _longitude = result.position!.longitude;
          _locationSet = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Lokasi berhasil didapatkan!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );

      case LocationStatus.serviceDisabled:
        _showLocationActionDialog(
          title: 'GPS Tidak Aktif',
          message:
              'Layanan lokasi (GPS) dinonaktifkan. Aktifkan GPS di pengaturan perangkat Anda, atau pilih lokasi manual di peta.',
          actions: [
            _DialogAction(
              label: 'Buka Pengaturan Lokasi',
              isPrimary: true,
              onTap: () => LocationService.instance.openLocationSettings(),
            ),
            _DialogAction(
              label: 'Pilih Manual di Peta',
              onTap: _openMapPicker,
            ),
          ],
        );

      case LocationStatus.permissionDenied:
        _showLocationActionDialog(
          title: 'Izin Lokasi Diperlukan',
          message:
              'Aplikasi memerlukan izin lokasi untuk menentukan posisi titik donasi Anda secara otomatis.',
          actions: [
            _DialogAction(
              label: 'Izinkan Akses Lokasi',
              isPrimary: true,
              onTap: () => LocationService.instance.getLocationWithStatus(),
            ),
            _DialogAction(
              label: 'Pilih Manual di Peta',
              onTap: _openMapPicker,
            ),
          ],
        );

      case LocationStatus.permissionDeniedForever:
        _showLocationActionDialog(
          title: 'Izin Lokasi Diblokir',
          message:
              'Izin lokasi telah diblokir secara permanen. Buka Pengaturan Aplikasi untuk mengaktifkan kembali, atau pilih lokasi manual di peta.',
          actions: [
            _DialogAction(
              label: 'Buka Pengaturan Aplikasi',
              isPrimary: true,
              onTap: () => LocationService.instance.openAppSettings(),
            ),
            _DialogAction(
              label: 'Pilih Manual di Peta',
              onTap: _openMapPicker,
            ),
          ],
        );

      case LocationStatus.pluginUnavailable:
        // Linux desktop: plugin GPS tidak tersedia
        _showLocationActionDialog(
          title: 'GPS Tidak Tersedia',
          message:
              'Layanan lokasi tidak tersedia di perangkat ini. Silakan pilih lokasi secara manual di peta.',
          actions: [
            _DialogAction(
              label: 'Pilih di Peta',
              isPrimary: true,
              onTap: _openMapPicker,
            ),
          ],
        );

      case LocationStatus.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            action: SnackBarAction(
              label: 'Pilih di Peta',
              onPressed: _openMapPicker,
            ),
          ),
        );
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialPosition: LatLng(_latitude, _longitude),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locationSet = true;
    });
  }

  // ─── Dialog helpers ───────────────────────────────────────────────────────

  void _showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onOpenSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showLocationActionDialog({
    required String title,
    required String message,
    required List<_DialogAction> actions,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.urgencyHigh),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ...actions.map(
            (a) => a.isPrimary
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      a.onTap();
                    },
                    child: Text(a.label),
                  )
                : OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      a.onTap();
                    },
                    child: Text(a.label),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<DonationRequest> _createDonation() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) throw Exception('Judul titik tidak boleh kosong.');
    if (description.isEmpty) throw Exception('Deskripsi tidak boleh kosong.');
    if (_pickedPhoto == null) throw Exception('Foto bukti wajib diunggah.');
    if (!_locationSet) {
      throw Exception(
          'Pilih lokasi terlebih dahulu (gunakan GPS atau pilih di peta).');
    }

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
      goalUnit: _goalUnit,
    );

    final dataUrl = await _photoToDataUrl(_pickedPhoto!);
    await _repository.uploadDocumentation(
      pointId: created.id,
      photoUrl: dataUrl,
      caption: null,
    );

    // ✅ Setelah upload dokumentasi, re-fetch donasi untuk mendapatkan image_url terbaru
    // Backend akan memproses gambar dan menyimpan URL-nya
    final updatedDonation = await _repository.getById(created.id);
    return updatedDonation;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
          const Divider(height: 1),
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                    children: _categories.map((c) {
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
                  _sectionLabel('Goals / Target'),
                  const SizedBox(height: 8),
                  // Unit selector (Rp / Kg)
                  Row(
                    children: [
                      _UnitChip(
                        label: 'Rp (Rupiah)',
                        isSelected: _goalUnit == 'Rp',
                        onTap: () => setState(() => _goalUnit = 'Rp'),
                      ),
                      const SizedBox(width: 8),
                      _UnitChip(
                        label: 'Kg (Kilogram)',
                        isSelected: _goalUnit == 'Kg',
                        onTap: () => setState(() => _goalUnit = 'Kg'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _goalUnit == 'Rp' ? 'e.g., 5000000' : 'e.g., 50',
                      prefixText: _goalUnit == 'Rp' ? 'Rp ' : null,
                      suffixText: _goalUnit == 'Kg' ? ' Kg' : null,
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
                  // Location
                  _sectionLabel('Location'),
                  const SizedBox(height: 4),
                  if (!_locationSet)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Pilih lokasi titik donasi ini menggunakan GPS atau peta.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _locationPicker(),
                  const SizedBox(height: 28),
                  // Publish button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                await _createDonation();
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Titik berhasil dibuat!'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Gagal membuat titik: $e')),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.location_on_rounded, size: 18),
                      label: Text(
                          _isSubmitting ? 'Menyimpan...' : 'Publish Point'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────

  String _mapCategoryToBackend(String uiValue) {
    return switch (uiValue) {
      'Food & Water' => 'Pangan',
      'Medical' => 'Medis',
      'Education' => 'Pendidikan',
      'Infrastructure' => 'Infrastruktur',
      'Clothes' => 'Pakaian',
      'Other' => 'Lainnya',
      _ => 'Umum',
    };
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTextStyles.titleSmall);

  Widget _photoUploadBox() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickPhoto(ImageSource.gallery),
            borderRadius: BorderRadius.circular(12),
            child: _photoTile(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _pickPhoto(ImageSource.camera),
            borderRadius: BorderRadius.circular(12),
            child: _photoTile(
              icon: Icons.photo_camera_outlined,
              label: 'Kamera',
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoTile({required IconData icon, required String label}) {
    final picked = _pickedPhoto != null;
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: picked
            ? AppColors.primary.withOpacity(0.06)
            : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: picked ? AppColors.primary : AppColors.border,
          width: picked ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            picked ? Icons.check_circle_rounded : icon,
            color: picked ? AppColors.primary : AppColors.textLight,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            picked ? 'Dipilih ✓' : label,
            style: AppTextStyles.bodySmall.copyWith(
              color: picked ? AppColors.primary : AppColors.textSecondary,
              fontWeight: picked ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tombol aksi lokasi
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // GPS
              Expanded(
                child: InkWell(
                  onTap: _gettingLocation ? null : _useCurrentLocation,
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_gettingLocation)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          const Icon(Icons.my_location_rounded,
                              size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _gettingLocation ? 'Mencari...' : '📍 Lokasi Saya',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.divider),
              // Peta
              Expanded(
                child: InkWell(
                  onTap: _openMapPicker,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                            fontSize: 13,
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
        // Preview
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: _locationSet
                          ? AppColors.urgencyHigh
                          : AppColors.textLight,
                      size: 40,
                    ),
                    if (!_locationSet)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Lokasi belum dipilih',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
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
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _locationSet
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _locationSet
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 14,
                        color: _locationSet
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _locationSet
                            ? 'Lat: ${_latitude.toStringAsFixed(5)}, Lng: ${_longitude.toStringAsFixed(5)}'
                            : 'Gunakan GPS atau pilih di peta',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _locationSet
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _DialogAction {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _DialogAction({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });
}

class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9DC99A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.2, 0),
        Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.6, 0),
        Offset(size.width * 0.6, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.35),
        Offset(size.width, size.height * 0.35), paint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.7), paint);

    final yellow = Paint()
      ..color = const Color(0xFFE6C84E)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.4, 0),
        Offset(size.width * 0.4, size.height), yellow);
    canvas.drawLine(Offset(0, size.height * 0.5),
        Offset(size.width, size.height * 0.5), yellow);
  }

  @override
  bool shouldRepaint(_) => false;
}
