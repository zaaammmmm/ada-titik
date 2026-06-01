// lib/features/donation/departure_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/app_widgets.dart';
import 'data/donation_repository.dart';

/// Screen untuk komunitas/owner menindaklanjuti donatur yang menekan "Berangkat".
/// Dibuka dari tap notifikasi `donator_departed`.
///
/// FLOW LENGKAP (v4 — diperbaiki):
///   1. Donatur menekan "Berangkat" → state `requested` → owner dapat notifikasi.
///   2. Owner membuka screen ini:
///      a. Section "Menunggu Konfirmasi" (requested) → tombol "Accept".
///         State → `accepted`, donatur diberi notifikasi PARTICIPANT_ACCEPTED.
///      b. Section "Diterima — Siap Diselesaikan" (accepted) → tombol
///         "Selesaikan & Beri Poin". State → `completed`, +50 poin DIBERIKAN ke
///         donatur (butuh GPS owner ≤100m). INI yang sebelumnya hilang sehingga
///         poin tidak pernah masuk.
///   3. "Tutup Titik" (AppBar) → menyelesaikan titik (status Completed, GPS).
class DepartureReviewScreen extends ConsumerStatefulWidget {
  final String pointId;
  final String pointTitle;

  const DepartureReviewScreen({
    super.key,
    required this.pointId,
    required this.pointTitle,
  });

  @override
  ConsumerState<DepartureReviewScreen> createState() =>
      _DepartureReviewScreenState();
}

class _DepartureReviewScreenState extends ConsumerState<DepartureReviewScreen> {
  late final DonationRepository _repo;

  bool _loading = true;
  bool _processing = false;
  String? _error;

  List<Map<String, dynamic>> _requested = [];
  List<Map<String, dynamic>> _accepted = [];
  final Set<String> _selectedRequested = {};
  final Set<String> _selectedAccepted = {};

  @override
  void initState() {
    super.initState();
    _repo = const DonationRepository();
    _loadParticipants();
  }

  String _idOf(Map<String, dynamic> p) =>
      p['donator_id']?.toString() ?? p['id']?.toString() ?? '';

  Future<void> _loadParticipants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Muat kedua state sekaligus.
      final results = await Future.wait([
        _repo.getParticipants(pointId: widget.pointId, state: 'requested'),
        _repo.getParticipants(pointId: widget.pointId, state: 'accepted'),
      ]);
      if (!mounted) return;
      setState(() {
        _requested = results[0];
        _accepted = results[1];
        // Default: semua requested terpilih (untuk accept cepat).
        _selectedRequested
          ..clear()
          ..addAll(_requested.map(_idOf).where((id) => id.isNotEmpty));
        // Accepted default semua terpilih untuk diselesaikan sekaligus.
        _selectedAccepted
          ..clear()
          ..addAll(_accepted.map(_idOf).where((id) => id.isNotEmpty));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Ambil GPS owner; tampilkan pesan jelas jika gagal.
  Future<({double lat, double lng})?> _getGps() async {
    final result = await LocationService.instance.getLocationWithStatus();
    if (!result.isSuccess || result.position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.urgencyHigh,
          ),
        );
      }
      return null;
    }
    return (lat: result.position!.latitude, lng: result.position!.longitude);
  }

  // ─── Accept (requested → accepted) ────────────────────────────────────────
  Future<void> _acceptSelected() async {
    if (_selectedRequested.isEmpty) {
      _snack('Pilih minimal 1 donatur untuk diterima.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _processing = true);
    final ids = _selectedRequested.toList();
    try {
      await _repo.acceptParticipants(pointId: widget.pointId, donatorIds: ids);
      if (!mounted) return;
      _snack('${ids.length} donatur diterima. Mereka mendapat notifikasi.',
          success: true);
      await _loadParticipants(); // reconcile dari server, bukan optimistik buta
      if (mounted) setState(() => _processing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _snack('Gagal menerima donatur: $e');
    }
  }

  // ─── Complete (accepted → completed) → POIN DIBERIKAN ─────────────────────
  Future<void> _completeSelected() async {
    if (_selectedAccepted.isEmpty) {
      _snack('Pilih minimal 1 donatur untuk diselesaikan.');
      return;
    }
    final gps = await _getGps();
    if (gps == null) return; // pesan sudah ditampilkan

    HapticFeedback.mediumImpact();
    setState(() => _processing = true);
    final ids = _selectedAccepted.toList();
    try {
      await _repo.completeParticipants(
        pointId: widget.pointId,
        donatorIds: ids,
        userLat: gps.lat,
        userLng: gps.lng,
      );
      if (!mounted) return;
      _snack('Donasi ${ids.length} donatur selesai! +50 poin diberikan ke '
          'masing-masing donatur. 🎉', success: true);
      await _loadParticipants();
      if (mounted) setState(() => _processing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _snack('Gagal menyelesaikan donasi: $e');
    }
  }

  // ─── Tutup titik (status → Completed, owner + geo-fence) ───────────────────
  Future<void> _closePoint() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Titik Bantuan?'),
        content: const Text(
          'Titik akan diselesaikan dan tidak muncul lagi di peta. Pastikan Anda '
          'berada di lokasi titik (maks 100m) dan donasi telah selesai. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.urgencyHigh,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tutup Titik'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final gps = await _getGps();
    if (gps == null) return;

    setState(() => _processing = true);
    try {
      await _repo.closePoint(
        pointId: widget.pointId,
        userLat: gps.lat,
        userLng: gps.lng,
      );
      if (!mounted) return;
      _snack('Titik bantuan telah diselesaikan.', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _snack('Gagal menutup titik: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppColors.primary : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text('Tindak Lanjut Donatur', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _processing ? null : _closePoint,
            icon: const Icon(Icons.flag_rounded,
                size: 18, color: AppColors.urgencyHigh),
            label: const Text(
              'Tutup Titik',
              style: TextStyle(
                  color: AppColors.urgencyHigh, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadParticipants,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'Menunggu Konfirmasi',
                        subtitle:
                            'Donatur yang sudah menekan "Berangkat". Terima untuk melanjutkan.',
                        icon: Icons.hourglass_top_rounded,
                        items: _requested,
                        selected: _selectedRequested,
                        emptyText: 'Tidak ada donatur yang menunggu konfirmasi.',
                        badgeText: 'Menunggu',
                        badgeColor: AppColors.statusProgress,
                      ),
                      if (_requested.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _primaryButton(
                          label: 'Terima Donatur (${_selectedRequested.length})',
                          icon: Icons.check_rounded,
                          onPressed: _processing ? null : _acceptSelected,
                        ),
                      ],
                      const SizedBox(height: 28),
                      _buildSection(
                        title: 'Diterima — Siap Diselesaikan',
                        subtitle:
                            'Saat donatur tiba & donasi diberikan, selesaikan untuk '
                            'mengirim +50 poin ke donatur.',
                        icon: Icons.volunteer_activism_rounded,
                        items: _accepted,
                        selected: _selectedAccepted,
                        emptyText: 'Belum ada donatur yang diterima.',
                        badgeText: 'Diterima',
                        badgeColor: AppColors.primary,
                      ),
                      if (_accepted.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _primaryButton(
                          label:
                              'Selesaikan & Beri Poin (${_selectedAccepted.length})',
                          icon: Icons.card_giftcard_rounded,
                          color: AppColors.primary,
                          onPressed: _processing ? null : _completeSelected,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.pointTitle,
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Set<String> selected,
    required String emptyText,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.titleSmall),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${items.length}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: badgeColor, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyText,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          )
        else
          ...items.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _participantTile(p, selected, badgeText, badgeColor),
              )),
      ],
    );
  }

  Widget _participantTile(Map<String, dynamic> p, Set<String> selected,
      String badgeText, Color badgeColor) {
    final id = _idOf(p);
    final name =
        p['donator_name']?.toString() ?? p['name']?.toString() ?? 'Donatur';
    final avatar = p['donator_avatar']?.toString() ?? p['avatar_url']?.toString();
    final createdAt = p['created_at']?.toString() ?? '';
    final isSelected = selected.contains(id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            selected.remove(id);
          } else {
            selected.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            UserAvatar(avatarUrl: avatar, name: name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(badgeText,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (createdAt.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(_relativeTime(createdAt),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textLight)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : AppColors.border,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    Color color = AppColors.primary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: _processing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 22),
        label: Text(
          _processing ? 'Memproses…' : label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.urgencyHigh),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadParticipants,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(String isoString) {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
