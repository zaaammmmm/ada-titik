// lib/shared/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';

// ─── App Logo Widget ──────────────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.location_on_rounded,
          color: AppColors.primary,
          size: size * 0.55,
        ),
      ),
    );
  }
}

// ─── Urgency Badge ────────────────────────────────────────────────────────────
class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;
  final bool compact;
  const UrgencyBadge({super.key, required this.urgency, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (urgency) {
      UrgencyLevel.urgent => (
          '! High Urgency',
          AppColors.urgencyHighLight,
          AppColors.urgencyHigh,
        ),
      UrgencyLevel.normal => (
          '! Normal',
          AppColors.urgencyMediumLight,
          AppColors.urgencyMedium,
        ),
      UrgencyLevel.low => (
          'Low',
          AppColors.urgencyLowLight,
          AppColors.urgencyLow,
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (status) {
      RequestStatus.open => (
          'Open Request',
          AppColors.statusOpenLight,
          AppColors.statusOpen,
          Icons.radio_button_on_rounded,
        ),
      RequestStatus.onProgress => (
          'In Progress',
          AppColors.statusProgressLight,
          AppColors.statusProgress,
          Icons.sync_rounded,
        ),
      RequestStatus.completed => (
          'Completed',
          AppColors.statusCompletedLight,
          AppColors.statusCompleted,
          Icons.check_circle_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String hint;
  final bool showFilter;
  final VoidCallback? onTap;
  const AppSearchBar({
    super.key,
    required this.hint,
    this.showFilter = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hint,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ),
            if (showFilter) ...[
              Container(width: 1, height: 20, color: AppColors.divider),
              const SizedBox(width: 10),
              Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineMedium),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }
}

// ─── App Bar Brand ────────────────────────────────────────────────────────────
class AdaTitikAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showAvatar;
  final String title;
  final VoidCallback? onNotification;

  const AdaTitikAppBar({
    super.key,
    this.showAvatar = true,
    this.title = 'Ada Titik?',
    this.onNotification,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    // NOTE: avatar user login diambil dari AuthProvider melalui wrapper widget
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: showAvatar
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _AuthUserAvatar(size: 36),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.brandTitle.copyWith(fontSize: 20),
      ),
      actions: [
        IconButton(
          onPressed: onNotification,
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 26,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.urgencyHigh,
                    shape: BoxShape.circle,
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

class _AuthUserAvatar extends ConsumerWidget {
  final double size;
  const _AuthUserAvatar({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return UserAvatar(
        avatarUrl: null,
        name: '',
        size: size,
      );
    }

    return UserAvatar(
      avatarUrl: user.avatarUrl,
      name: user.name,
      size: size,
    );
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────
class TagChip extends StatelessWidget {
  final String label;
  const TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────
class DonationProgressBar extends StatelessWidget {
  final double collected;
  final double goal;
  final String collectedLabel;
  final String goalLabel;
  const DonationProgressBar({
    super.key,
    required this.collected,
    required this.goal,
    required this.collectedLabel,
    required this.goalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal > 0) ? (collected / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              collectedLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(goalLabel, style: AppTextStyles.labelSmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Category Filter Chip ─────────────────────────────────────────────────────
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
