// lib/features/donation/rating_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'data/donation_repository.dart';

/// Screen yang muncul setelah donatur di-accept oleh komunitas.
/// Memungkinkan donatur memberikan rating untuk titik bantuan.
class RatingScreen extends StatefulWidget {
  final String pointId;
  final String pointTitle;
  final String communityName;

  const RatingScreen({
    super.key,
    required this.pointId,
    required this.pointTitle,
    required this.communityName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int? _selectedScore;
  final _reviewController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  final _repo = const DonationRepository();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedScore == null) return;
    setState(() => _submitting = true);
    try {
      await _repo.createRating(
        pointId: widget.pointId,
        score: _selectedScore!,
        review: _reviewController.text.trim().isNotEmpty
            ? _reviewController.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim rating: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Beri Rating'),
        leading: const BackButton(),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.statusCompleted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 64,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Terima kasih!',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Rating Anda telah dikirim dan membantu komunitas berkembang.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pointTitle,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'oleh ${widget.communityName}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Bagaimana pengalaman Anda?', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Berikan rating untuk komunitas yang membuat titik bantuan ini.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedScore = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.star_rounded,
                    size: 48,
                    color: (_selectedScore != null && star <= _selectedScore!)
                        ? const Color(0xFFF59E0B)
                        : AppColors.border,
                  ),
                ),
              );
            }),
          ),

          if (_selectedScore != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                _scoreLabel(_selectedScore!),
                style: AppTextStyles.titleSmall.copyWith(
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          Text('Ulasan (opsional)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalaman Anda membantu titik ini...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedScore != null && !_submitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kirim Rating'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Lewati'),
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int score) {
    return switch (score) {
      1 => 'Sangat Buruk',
      2 => 'Buruk',
      3 => 'Cukup',
      4 => 'Baik',
      5 => 'Sangat Baik',
      _ => '',
    };
  }
}
