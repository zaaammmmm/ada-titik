// lib/features/donation/edit_progress_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';
import 'data/donation_repository.dart';

/// Screen untuk komunitas/owner mengedit goal_amount dan collected_amount titiknya.
class EditProgressScreen extends StatefulWidget {
  final DonationRequest request;

  const EditProgressScreen({super.key, required this.request});

  @override
  State<EditProgressScreen> createState() => _EditProgressScreenState();
}

class _EditProgressScreenState extends State<EditProgressScreen> {
  late final TextEditingController _goalController;
  late final TextEditingController _collectedController;
  final _repo = const DonationRepository();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.request.goalAmount > 0
          ? widget.request.goalAmount.toInt().toString()
          : '',
    );
    _collectedController = TextEditingController(
      text: widget.request.collectedAmount > 0
          ? widget.request.collectedAmount.toInt().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _collectedController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final goalText = _goalController.text.trim().replaceAll('.', '');
    final collectedText = _collectedController.text.trim().replaceAll('.', '');

    final goal = double.tryParse(goalText);
    final collected = double.tryParse(collectedText);

    if (goal == null && collected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan minimal satu nilai.')),
      );
      return;
    }

    if (goal != null && goal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target tidak boleh negatif.')),
      );
      return;
    }

    if (collected != null && collected < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terkumpul tidak boleh negatif.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _repo.updateProgress(
        pointId: widget.request.id,
        goalAmount: goal,
        collectedAmount: collected,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress berhasil diperbarui!'),
          backgroundColor: AppColors.statusCompleted,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  String _urgencyFromProgress(double? goal, double? collected) {
    if (goal == null || goal <= 0) return 'Mendesak';
    final c = collected ?? widget.request.collectedAmount;
    final progress = (c / goal).clamp(0.0, 1.0);
    if (progress >= 0.80) return 'Rendah';
    if (progress >= 0.33) return 'Normal';
    return 'Mendesak';
  }

  @override
  Widget build(BuildContext context) {
    final goal = double.tryParse(_goalController.text.replaceAll('.', '')) ??
        widget.request.goalAmount;
    final collected =
        double.tryParse(_collectedController.text.replaceAll('.', '')) ??
            widget.request.collectedAmount;

    final progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);
    final urgencyPreview = _urgencyFromProgress(goal, collected);

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
        title: Text('Edit Progress', style: AppTextStyles.headlineSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titik info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.request.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress preview
            _buildProgressPreview(
                progress, pct, collected, goal, urgencyPreview),
            const SizedBox(height: 24),

            // Form
            Text('Target Donasi', style: AppTextStyles.titleSmall),

            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Contoh: 50',
                prefixText: null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            Text('Sudah Terkumpul', style: AppTextStyles.titleSmall),

            const SizedBox(height: 8),
            TextField(
              controller: _collectedController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Contoh: 50',
                prefixText: null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),

            // Info urgency auto
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Urgency akan otomatis berubah ke "$urgencyPreview" '
                      'berdasarkan persentase yang diisikan.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _submitting ? 'Menyimpan...' : 'Simpan Progress',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressPreview(
    double progress,
    String pct,
    double collected,
    double goal,
    String urgencyLabel,
  ) {
    Color urgencyColor;
    Color urgencyBg;
    switch (urgencyLabel) {
      case 'Rendah':
        urgencyColor = AppColors.statusCompleted;
        urgencyBg = AppColors.statusCompletedLight;
        break;
      case 'Normal':
        urgencyColor = AppColors.urgencyMedium;
        urgencyBg = AppColors.urgencyMediumLight;
        break;
      default:
        urgencyColor = AppColors.urgencyHigh;
        urgencyBg = AppColors.urgencyHighLight;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preview Progress', style: AppTextStyles.titleSmall),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: urgencyBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  urgencyLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terkumpul: ${_inferUnitFromCategory(widget.request.category) == 'Kg' ? '${_formatNumber(collected)} Kg' : 'Rp ${_formatNumber(collected)}'}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                '$pct%',
                style:
                    AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${_inferUnitFromCategory(widget.request.category) == 'Kg' ? '${_formatNumber(goal)} Kg' : 'Rp ${_formatNumber(goal)}'}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _inferUnitFromCategory(String category) {
    final c = category.toLowerCase().trim();
    if (c.contains('pangan') || c.contains('medis') || c.contains('pakaian')) {
      return 'Kg';
    }
    if (c.contains('food') || c.contains('water') || c.contains('makanan')) {
      return 'Kg';
    }
    return 'Rp';
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}Jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}Rb';
    return n.toStringAsFixed(0);
  }
}
