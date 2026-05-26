import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class ReportDialog extends StatefulWidget {
  final String title;
  final String pointId;
  final String? defaultReason;
  final Future<void> Function({required String pointId, required String reason})
      onSubmit;

  const ReportDialog({
    super.key,
    required this.title,
    required this.pointId,
    this.defaultReason,
    required this.onSubmit,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  static const List<String> _categories = [
    'Penipuan',
    'Lokasi Tidak Sesuai',
    'Bantuan Fiktif',
    'Spam',
    'Lainnya',
  ];

  late String _selectedCategory;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
    _reasonController.text = widget.defaultReason ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: AppTextStyles.titleSmall),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alasan laporan akan dikirim ke admin. Pastikan deskripsinya jelas.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
              decoration: InputDecoration(
                labelText: 'Kategori Laporan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis alasan laporan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final reason = _reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Alasan laporan tidak boleh kosong')),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);
                  try {
                    await widget.onSubmit(
                        pointId: widget.pointId, reason: '[$_selectedCategory] $reason');
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Kirim Laporan'),
        ),
      ],
    );
  }
}