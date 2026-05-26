// lib/features/community/community_write_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'data/community_repository.dart';

/// Screen untuk membuat postingan komunitas baru.
/// Hanya bisa diakses oleh user dengan role 'komunitas'.
/// Endpoint: POST /api/community/posts
class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  String _selectedType = 'updateKomunitas';
  bool _isSubmitting = false;
  XFile? _selectedImage;

  // Mapping key (backend value) -> label tampilan
  final Map<String, String> _postTypes = {
    'updateKomunitas'   : 'Update Komunitas',
    'bantuanDibutuhkan' : 'Bantuan Dibutuhkan',
    'pertanyaan'        : 'Pertanyaan / Diskusi',
    'inspirasi'         : 'Inspirasi',
    'kisahSukses'       : 'Kisah Sukses',
  };

  Future<String> _imageToDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final ext = file.name.split('.').last;
    final mime = switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpeg' || 'jpg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,$base64Str';
  }

  Future<void> _pickImage(ImageSource source) async {
    final res = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (res != null) {
      setState(() => _selectedImage = res);
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageToDataUrl(_selectedImage!);
      }

      await const CommunityRepository().createPost(
        content: content,
        postType: _selectedType,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      // Kirim `true` sebagai signal ke CommunityScreen untuk refresh feed
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dibuat!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat postingan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text('Buat Posting', style: AppTextStyles.headlineSmall),
        leading: const BackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Kirim',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilih jenis postingan
            Text('Jenis Postingan', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: _postTypes.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedType = v ?? _selectedType),
            ),
            const SizedBox(height: 16),

            // Area tulis konten
            Text('Konten', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                maxLength: 5000,
                decoration: InputDecoration(
                  hintText:
                      'Tulis update, cerita, atau pertanyaan Anda di sini...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),

            // Image picker
            Text('Gambar (Opsional)', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: () => _pickImage(ImageSource.gallery),
                onLongPress: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 32, color: AppColors.textLight),
                      const SizedBox(height: 6),
                      Text('Tambah gambar (tap/gallery, long press/camera)',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
