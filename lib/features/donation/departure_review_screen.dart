// lib/features/donation/departure_review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import 'data/donation_repository.dart';

/// Screen khusus untuk komunitas/owner menindaklanjuti donatur yang
/// sudah menekan "Berangkat". Dibuka dari tap notifikasi `donator_departed`.
///
/// FLOW:
///   1. Donatur menekan "Berangkat" → sinyal dikirim → owner mendapat notifikasi.
///   2. Owner membuka screen ini dan menekan "Accept" → donatur diterima
///      (status participation -> accepted), poin ditambahkan ke kedua pihak.
///   3. Titik TETAP ADA sampai:
///      a. progress >= target (owner update via Edit Progress), ATAU
///      b. Owner menekan "Tutup Titik" di screen ini / di request detail.
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

class _DepartureReviewScreenState
    extends ConsumerState<DepartureReviewScreen> {
  late final DonationRepository _repo;

  bool _loading = true;
  bool _processing = false;
  String? _error;

  List<Map<String, dynamic>> _participants = [];
  Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _repo = const DonationRepository();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getParticipants(
        pointId: widget.pointId,
        state: 'requested',
      );
      setState(() {
        _participants = list;
        _selected = list
            .map((e) => e['donator_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Accept donatur terpilih — memberikan notifikasi & poin ke kedua pihak.
  /// Titik bantuan TIDAK ditutup — titik tetap ada sampai kondisi penutupan terpenuhi.
  Future<void> _acceptSelected() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 donatur.')),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final donatorIds = _selected.toList();

      // Accept → status participation menjadi 'accepted', poin diberikan
      await _repo.acceptParticipants(
        pointId: widget.pointId,
        donatorIds: donatorIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${donatorIds.length} donatur berhasil di-accept! '
            'Poin sudah dikirimkan ke kedua pihak.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      // Pop back dengan result true agar parent bisa refresh
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e')),
      );
      setState(() => _processing = false);
    }
  }

  /// Tutup titik secara manual — menutup titik tanpa syarat progress.
  Future<void> _closePoint() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Titik Bantuan?'),
        content: const Text(
          'Titik bantuan akan ditutup dan tidak akan muncul lagi di peta. '
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

    setState(() => _processing = true);
    try {
      await _repo.updateStatus(
        requestId: widget.pointId,
        status: RequestStatus.completed,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titik bantuan telah ditutup.'),
          backgroundColor: AppColors.statusCompleted,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menutup titik: $e')),
      );
      setState(() => _processing = false);
    }
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
        title: Text('Tindak Lanjut Donatur', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        actions: [
          // Tombol tutup titik di app bar
          TextButton.icon(
            onPressed: _processing ? null : _closePoint,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.urgencyHigh),
            label: const Text(
              'Tutup Titik',
              style: TextStyle(color: AppColors.urgencyHigh, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header titik
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.pointTitle,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Donatur berikut sudah menekan "Berangkat" dan menunggu konfirmasi Anda.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 6),
                // Info catatan penting
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.primary.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Setelah Accept, titik tetap aktif sampai progress tercukupi '
                          'atau Anda menekan "Tutup Titik".',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List donatur
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _participants.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),

          // Action button — hanya "Accept" (tidak complete sekaligus)
          if (!_loading && _participants.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _acceptSelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 22),
                    label: Text(
                      _processing
                          ? 'Memproses...'
                          : 'Accept Donatur (${_selected.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _participants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = _participants[i];
        final donatorId = p['donator_id']?.toString() ?? '';
        final name =
            p['donator_name']?.toString() ?? p['name']?.toString() ?? 'Donatur';
        final avatar = p['donator_avatar']?.toString() ??
            p['avatar_url']?.toString();
        final createdAt = p['created_at']?.toString() ?? '';
        final isSelected = _selected.contains(donatorId);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(donatorId);
              } else {
                _selected.add(donatorId);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
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
                              color: AppColors.statusProgress.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Menunggu',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.statusProgress,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              _relativeTime(createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textLight),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(isSelected),
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              'Tidak ada donatur yang menunggu',
              style: AppTextStyles.titleSmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Tampilkan tombol tutup titik juga di empty state
            OutlinedButton.icon(
              onPressed: _processing ? null : _closePoint,
              icon: const Icon(Icons.close_rounded, color: AppColors.urgencyHigh),
              label: const Text(
                'Tutup Titik Bantuan',
                style: TextStyle(color: AppColors.urgencyHigh),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.urgencyHigh),
              ),
            ),
          ],
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
