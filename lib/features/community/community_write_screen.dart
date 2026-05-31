// lib/features/community/community_write_screen.dart
//
// PERUBAHAN dari versi sebelumnya:
// - Upload gambar 2 langkah sesuai kontrak API v3.3:
//   Langkah 1: POST /api/community/posts/image (multipart) → dapat image_url publik
//   Langkah 2: POST /api/community/posts (JSON, sertakan image_url)
// - Progress indicator saat upload gambar.
// - Hapus konversi base64 yang tidak perlu (sudah tidak dipakai).

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_client.dart';
import 'data/community_repository.dart';

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
  bool _isUploadingImage = false;
  XFile? _selectedImage;
  String? _uploadedImageUrl; // URL publik dari Supabase setelah upload

  final Map<String, String> _postTypes = {
    'updateKomunitas': 'Update Komunitas',
    'bantuanDibutuhkan': 'Bantuan Dibutuhkan',
    'pertanyaan': 'Pertanyaan / Diskusi',
    'inspirasi': 'Inspirasi',
    'kisahSukses': 'Kisah Sukses',
  };

  Future<void> _pickImage(ImageSource source) async {
    final res = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (res != null) {
      setState(() {
        _selectedImage = res;
        _uploadedImageUrl = null; // reset jika ganti gambar
      });
      // Langsung upload setelah pilih
      await _uploadImage(res);
    }
  }

  /// Langkah 1: Upload ke POST /api/community/posts/image (multipart)
  /// → backend simpan ke bucket Supabase community-posts
  /// → return { image_url: "https://..." }
  Future<void> _uploadImage(XFile file) async {
    setState(() => _isUploadingImage = true);
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final res = await ApiClient.post<Map<String, dynamic>>(
        '/api/community/posts/image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.statusCode == 201) {
        final url = res.data?['image_url']?.toString();
        if (url != null && url.isNotEmpty) {
          setState(() => _uploadedImageUrl = url);
          return;
        }
      }

      final errMsg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal upload gambar (${res.statusCode}).';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errMsg)),
      );
      // Rollback pilihan gambar jika upload gagal
      setState(() => _selectedImage = null);
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMsg = (e.response?.data is Map)
          ? ((e.response?.data as Map)['error'] ??
                  (e.response?.data as Map)['message'])
              ?.toString()
          : null;
      final msg = serverMsg ?? 'Gagal upload gambar. Periksa koneksi Anda.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      setState(() => _selectedImage = null);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal upload gambar.')),
      );
      setState(() => _selectedImage = null);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Langkah 2: POST /api/community/posts (JSON) dengan image_url yang sudah di-upload
  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten tidak boleh kosong.')),
      );
      return;
    }

    // Jika gambar dipilih tapi belum selesai upload, tunggu
    if (_selectedImage != null && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gambar masih diproses, mohon tunggu...')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await const CommunityRepository().createPost(
        content: content,
        postType: _selectedType,
        imageUrl: _uploadedImageUrl, // null jika tidak ada gambar
      );
      if (!mounted) return;
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
              onPressed: (_isSubmitting || _isUploadingImage) ? null : _submit,
              child: (_isSubmitting)
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
            // Jenis postingan
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
            Row(
              children: [
                Text('Gambar (Opsional)', style: AppTextStyles.titleSmall),
                if (_isUploadingImage) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 4),
                  Text('Mengupload...',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
                if (_uploadedImageUrl != null && !_isUploadingImage) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.cloud_done_outlined,
                      size: 16, color: AppColors.statusCompleted),
                  const SizedBox(width: 4),
                  Text('Tersimpan',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.statusCompleted)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_selectedImage!.path),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (_isUploadingImage)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black38,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isUploadingImage)
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
                onTap: _isUploadingImage
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                onLongPress: _isUploadingImage
                    ? null
                    : () => _pickImage(ImageSource.camera),
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
                      Text(
                        'Tambah gambar (tap/gallery, long press/camera)',
                        style: AppTextStyles.bodySmall,
                      ),
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
