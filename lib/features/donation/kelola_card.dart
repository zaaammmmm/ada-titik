import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/models/models.dart';

class KelolaCard extends StatelessWidget {
  final DonationRequest request;
  final VoidCallback onOpenDetail;
  const KelolaCard(
      {super.key, required this.request, required this.onOpenDetail});

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onOpenDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _statusChip(),
                _categoryChip(),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.title,
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              request.description,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            _progressRow(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Kelola →',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _progressRow() {
    final goal = request.goalAmount;
    final collected = request.collectedAmount;
    final unit = _inferUnitFromCategory(request.category);

    if (goal <= 0) {
      return Text(
        'Terkumpul: ${unit == 'Kg' ? '${collected.toStringAsFixed(0)} Kg' : 'Rp ${collected.toStringAsFixed(0)}'}',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      );
    }

    final pct = (collected / goal).clamp(0.0, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Terkumpul: ${unit == 'Kg' ? '${collected.toStringAsFixed(0)} Kg' : 'Rp ${collected.toStringAsFixed(0)}'}',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _statusChip() {
    final (bg, fg, label) = switch (request.status) {
      RequestStatus.open => (
          AppColors.statusOpenLight,
          AppColors.statusOpen,
          'Open'
        ),
      RequestStatus.onProgress => (
          AppColors.statusProgressLight,
          AppColors.statusProgress,
          'On Progress'
        ),
      RequestStatus.completed => (
          AppColors.statusCompletedLight,
          AppColors.statusCompleted,
          'Completed'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _categoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        request.category,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
