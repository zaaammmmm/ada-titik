// lib/features/donation/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/supabase_realtime_service.dart';

import '../../features/donation/data/donation_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../chat/chat_screen.dart';
import 'edit_progress_screen.dart';
import 'rating_screen.dart';
import 'departure_review_screen.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final DonationRequest request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  late final DonationRepository _repo;
  late Future<DonationRequest> _detailFuture;

  late Future<List<Map<String, dynamic>>> _docsFuture;
  late Future<List<Map<String, dynamic>>> _ratingsFuture;

  String? _selectedReview;
  int? _selectedScore;
  bool _submittingRating = false;
  bool _hasShownRatingPrompt = false;

  // Auto-refresh
  // Status partisipasi donatur saat ini ('requested', 'accepted', 'completed', null)
  Map<String, dynamic>? _myParticipation;
  bool _loadingParticipation = false;

  @override
  void initState() {
    super.initState();
    _repo = const DonationRepository();
    _detailFuture = _repo.getById(widget.request.id);
    _docsFuture = _repo.getDocumentation(widget.request.id);
    _ratingsFuture = _repo.getRatings(widget.request.id);
    _loadMyParticipation();

    // No.3 FIX: Tidak ada polling. Refresh hanya via Supabase Realtime.
    // Realtime subscription untuk notifikasi participants
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRealtime();
    });
  }

  void _subscribeRealtime() {
    // Subscribe ke perubahan titik via Supabase realtime
    // Ketika ada update di donation_points (progress, status), auto-refresh
    final realtime = SupabaseRealtimeService();
    // Gunakan subscription notification sebagai trigger refresh
    final userId = ref.read(authProvider).user?.id ?? '';
    if (userId.isEmpty) return;
    realtime.subscribeToNotifications(
      currentUserId: userId,
      onInsert: (payload) {
        final pointId = payload['payload']?['point_id']?.toString();
        if (pointId == widget.request.id) {
          _refreshAll();
        }
      },
    );
  }

  void _refreshAll() {
    if (!mounted) return;
    setState(() {
      _detailFuture = _repo.getById(widget.request.id);
      _docsFuture = _repo.getDocumentation(widget.request.id);
    });
    _loadMyParticipation();
  }

  Future<void> _loadMyParticipation() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null || currentUser.role.toLowerCase() != 'donatur') {
      return;
    }
    setState(() => _loadingParticipation = true);
    try {
      final p = await _repo.getMyParticipation(widget.request.id);
      if (mounted) {
        final prevState = _myParticipation?['state']?.toString();
        setState(() => _myParticipation = p);

        // No.4 FIX: Jika baru saja berubah ke 'accepted', arahkan ke rating screen.
        final newState = p?['state']?.toString().toLowerCase();
        if (!_hasShownRatingPrompt &&
            newState == 'accepted' &&
            prevState?.toLowerCase() != 'accepted') {
          _hasShownRatingPrompt = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showRatingPrompt();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingParticipation = false);
  }

  void _showRatingPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Berangkat di-Accept! 🎉'),
        content: const Text(
          'Komunitas telah menerima keberangkatan Anda. '
          'Poin sudah ditambahkan ke akun Anda. '
          'Bagikan pengalaman Anda dengan memberikan rating.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    pointId: widget.request.id,
                    pointTitle: widget.request.title,
                    communityName: widget.request.authorName,
                  ),
                ),
              );
            },
            child: const Text('Beri Rating Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  static const List<String> _quickMessages = [
    'Apakah titik bantuan ini masih aktif?',
    'Berapa banyak bantuan yang masih dibutuhkan?',
    'Saya ingin berangkat membantu, bagaimana caranya?',
    'Apakah masih ada yang dibutuhkan selain yang tertulis?',
  ];

  void _openChatWithMessage(DonationRequest request, String? message) {
    final targetUserId = request.createdById;
    final contextIdInt = int.tryParse(request.id) ?? request.id.hashCode.abs();
    if (targetUserId == null || targetUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak dapat membuka chat: pemilik titik tidak dikenal.')),
      );
      return;
    }
    final defaultMessage = '📍 *${request.title}*\n'
        'Kategori: ${request.category}\n'
        'Lokasi: ${request.location.isNotEmpty ? request.location : "Lihat peta"}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          targetUserId: targetUserId,
          contextId: contextIdInt,
          contextType: 'donation_point',
          contextTitle: request.title,
          contextSummary:
              '${request.category} · ${request.location.isNotEmpty ? request.location : "Lihat peta"} · Target: ${request.goalUnit == 'Kg' ? '${request.goalAmount.toStringAsFixed(0)} Kg' : 'Rp ${request.goalAmount.toStringAsFixed(0)}'}',
          initialMessage: message ?? defaultMessage,
        ),
      ),
    );
  }

  LatLng _latLngFromRequest(DonationRequest request) =>
      LatLng(request.latitude, request.longitude);

  // ✅ FIXED: updateStatus sekarang mengirim koordinat GPS untuk status Completed
  Future<void> _updateStatus(RequestStatus next) async {
    double? userLat;
    double? userLng;

    if (next == RequestStatus.completed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mendapatkan lokasi GPS...')),
      );

      final pos = await LocationService.instance.getCurrentPosition();
      if (pos == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS tidak tersedia. Aktifkan GPS untuk menyelesaikan titik bantuan.',
            ),
          ),
        );
        return;
      }
      userLat = pos.latitude;
      userLng = pos.longitude;
    }

    try {
      await _repo.updateStatus(
        requestId: widget.request.id,
        status: next,
        userLat: userLat,
        userLng: userLng,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil diperbarui!')),
      );

      // Refresh detail dari backend
      setState(() {
        _detailFuture = _repo.getById(widget.request.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  Future<void> _handleNavigateHere() async {
    final lat = widget.request.latitude;
    final lng = widget.request.longitude;

    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps.')),
      );
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _submitRating() async {
    final score = _selectedScore;
    final review = _selectedReview?.trim();
    if (score == null) return;

    setState(() => _submittingRating = true);
    try {
      await _repo.createRating(
        pointId: widget.request.id,
        score: score,
        review: (review != null && review.isNotEmpty) ? review : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih! Rating berhasil dikirim.')),
      );

      setState(() {
        _ratingsFuture = _repo.getRatings(widget.request.id);
        _detailFuture = _repo.getById(widget.request.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim rating: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingRating = false);
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<String> _photoToDataUrl(XFile file) async {
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final parts = file.name.split('.');
    final ext = parts.isNotEmpty ? parts.last : 'jpg';
    final mime = switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpeg' || 'jpg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    return 'data:$mime;base64,$base64Str';
  }

  Future<void> _uploadDoc() async {
    final xfile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;

    try {
      final dataUrl = await _photoToDataUrl(xfile);
      await _repo.uploadDocumentation(
        pointId: widget.request.id,
        photoUrl: dataUrl,
        caption: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumentasi berhasil diunggah.')),
      );
      setState(() {
        _docsFuture = _repo.getDocumentation(widget.request.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah dokumentasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<DonationRequest>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final request = snapshot.data ?? widget.request;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          return CustomScrollView(
            slivers: [
              _buildAppBar(request),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (isLoading) const LinearProgressIndicator(minHeight: 2),
                    _buildHeader(request),
                    const SizedBox(height: 16),
                    _buildProgressCard(request),
                    const SizedBox(height: 16),
                    _buildRatingsSection(request, currentUser),
                    const SizedBox(height: 16),
                    _buildDocsSection(request, currentUser),
                    const SizedBox(height: 16),
                    _buildActionButtons(request, currentUser),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(DonationRequest request) {
    return SliverAppBar(
      expandedHeight: request.imageUrl != null ? 220 : 0,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Report icon (for non-owner)
        Builder(builder: (context) {
          final currentUser = ref.watch(authProvider).user;
          final isOwner = currentUser != null &&
              (currentUser.id == request.createdById || currentUser.isAdmin);
          final isNonOwner = currentUser != null && !isOwner;
          if (!isNonOwner) return const SizedBox.shrink();

          return IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.black),
            onPressed: () => _showReportDialog(request),
            tooltip: 'Laporkan',
          );
        }),
      ],
      flexibleSpace: request.imageUrl != null
          ? FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: request.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primaryContainer,
                  child: const Icon(Icons.image_outlined, size: 48),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(DonationRequest request) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            UrgencyBadge(urgency: request.urgency),
            StatusBadge(status: request.status),
            _categoryChip(request.category),
          ],
        ),
        const SizedBox(height: 12),
        // Enhanced Author Section with Role
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: request.authorAvatar,
                name: request.authorName,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.authorName,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Komunitas',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request.timeAgo,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(request.title, style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        Text(
          request.description,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
        if (request.location.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.location,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProgressCard(DonationRequest request) {
    final goal = request.goalAmount;
    final collected = request.collectedAmount;
    final progress = goal > 0 ? (collected / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toStringAsFixed(0);

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
          Text('Progress Donasi', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terkumpul: ${request.goalUnit == 'Kg' ? '${_formatNumber(collected)} Kg' : 'Rp ${_formatNumber(collected)}'}',
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
              minHeight: 8,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${request.goalUnit == 'Kg' ? '${_formatNumber(goal)} Kg' : 'Rp ${_formatNumber(goal)}'}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          if (request.avgRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  '${request.avgRating!.toStringAsFixed(1)} / 5',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingsSection(DonationRequest request, UserModel? currentUser) {
    final participationState =
        _myParticipation?['state']?.toString().toLowerCase();
    final hasAcceptedParticipant =
        participationState == 'accepted' || participationState == 'completed';
    final canRate = currentUser != null &&
        currentUser.role.toLowerCase() == 'donatur' &&
        (request.status == RequestStatus.completed || hasAcceptedParticipant);

    // Cek apakah user sudah pernah memberi rating (jika sudah ada di _ratingsFuture)
    final alreadyRated = _myParticipation?['has_rated'] == true ||
        _myParticipation?['rated'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rating & Ulasan', style: AppTextStyles.titleSmall),
        const SizedBox(height: 8),
        if (canRate && !alreadyRated) ...[
          _buildRatingInput(),
          const SizedBox(height: 12),
        ],
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _ratingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final ratings = snapshot.data ?? [];
            if (ratings.isEmpty) {
              return Text(
                'Belum ada ulasan.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: ratings.map((r) => _buildRatingTile(r)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRatingInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Beri Rating', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedScore = star),
                child: Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: (_selectedScore != null && star <= _selectedScore!)
                      ? const Color(0xFFF59E0B)
                      : AppColors.border,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => _selectedReview = v,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Tulis ulasan (opsional)...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedScore != null && !_submittingRating)
                  ? _submitRating
                  : null,
              child: _submittingRating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim Rating'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingTile(Map<String, dynamic> r) {
    final reviewer =
        r['reviewer_name']?.toString() ?? r['user_name']?.toString() ?? 'User';
    final score = (r['score'] as num?)?.toInt() ?? 0;
    final review = r['review']?.toString() ?? '';
    final time = r['created_at']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(avatarUrl: null, name: reviewer, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(reviewer, style: AppTextStyles.titleSmall),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        score,
                        (_) => const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
                if (review.isNotEmpty)
                  Text(review, style: AppTextStyles.bodySmall),
                Text(
                  time,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textLight, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocsSection(DonationRequest request, UserModel? currentUser) {
    // Hanya komunitas yang bisa upload dokumentasi
    final isKomunitas = currentUser?.role.toLowerCase() == 'komunitas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dokumentasi', style: AppTextStyles.titleSmall),
            if (isKomunitas)
              TextButton.icon(
                onPressed: _uploadDoc,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('Tambah'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _docsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return Text(
                'Belum ada dokumentasi.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              );
            }
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = docs[i]['photo_url']?.toString() ?? '';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 100,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(DonationRequest request, UserModel? currentUser) {
    final isOwner = currentUser != null &&
        (currentUser.id == request.createdById || currentUser.isAdmin);
    final isDonatur = currentUser?.role.toLowerCase() == 'donatur';

    final participationState = _myParticipation?['state']?.toString();
    final hasRequested = participationState == 'requested';
    final hasAccepted = participationState == 'accepted';
    final hasCompleted = participationState == 'completed';

    return Column(
      children: [
        // Map preview dulu untuk owner
        // Map preview yang bisa ditekan untuk navigasi
        GestureDetector(
          onTap: _handleNavigateHere,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _latLngFromRequest(widget.request),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.adatitik.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _latLngFromRequest(widget.request),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.urgencyHigh,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Overlay tombol navigasi
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(30),
                    color: AppColors.primary,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _handleNavigateHere,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.navigation_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Buka di Maps',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Ikon "tap to navigate" di pojok kiri atas
                // Positioned(
                //   top: 10,
                //   left: 10,
                //   child: Container(
                //     padding:
                //         const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //     decoration: BoxDecoration(
                //       color: Colors.white.withOpacity(0.9),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: const Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Icon(Icons.touch_app_rounded,
                //             size: 13, color: AppColors.primary),
                //         SizedBox(width: 4),
                //         Text(
                //           'Tap untuk navigasi',
                //           style: TextStyle(
                //               fontSize: 11,
                //               color: AppColors.primary,
                //               fontWeight: FontWeight.w600),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),

        // Edit Progress — owner, di bawah map (Fix #15)
        if (isOwner) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProgressScreen(request: request),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {
                    _detailFuture = _repo.getById(widget.request.id);
                  });
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Progress'),
            ),
          ),
        ],

        // ── DONATUR ─────────────────────────────────────────────────────
        if (isDonatur) ...[
          const SizedBox(height: 10),
          if (hasCompleted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.statusCompleted.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.statusCompleted.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.statusCompleted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Donasi Selesai — Poin diberikan!',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.statusCompleted),
                  ),
                ],
              ),
            ),
          ] else if (hasRequested) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.statusProgress.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.statusProgress.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.statusProgress,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Menunggu konfirmasi komunitas...',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.statusProgress,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await _repo.cancelDeparture(request.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Keberangkatan dibatalkan.')),
                        );
                        await _loadMyParticipation();
                        setState(() {
                          _detailFuture = _repo.getById(widget.request.id);
                        });
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal membatalkan: $e')),
                        );
                      }
                    },
                    child: const Text('Batalkan',
                        style: TextStyle(color: AppColors.urgencyHigh)),
                  ),
                ],
              ),
            ),
          ] else if (hasAccepted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Diterima! Sedang On Progress',
                      style: AppTextStyles.titleSmall
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ] else if (request.status == RequestStatus.open ||
              request.status == RequestStatus.onProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingParticipation
                    ? null
                    : () async {
                        try {
                          final pos = await LocationService.instance
                              .getCurrentPosition();
                          await _repo.sendDeparture(
                            pointId: request.id,
                            userLat: pos?.latitude,
                            userLng: pos?.longitude,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Sinyal 'Berangkat' terkirim! Menunggu konfirmasi komunitas.")),
                          );
                          await _loadMyParticipation();
                          setState(() {
                            _detailFuture = _repo.getById(widget.request.id);
                          });
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal Berangkat: $e')),
                          );
                        }
                      },
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Berangkat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusProgress,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],

        // ── OWNER ────────────────────────────────────────────────────────
        // NOTE: Tombol "Tindak Lanjut Donatur" tidak tampil kalau status request
        // tidak persis `onProgress`. Untuk owner, tampilkan saat proses sudah mulai
        // (onProgress) dan juga saat backend masih bertahan di `accepted`/varian.
        // Sesuaikan bila bisnis Anda punya state lain.
        if (isOwner &&
            (request.status == RequestStatus.onProgress ||
                request.status == RequestStatus.open)) ...[
          const SizedBox(height: 10),

          // Sama pattern seperti "Edit Progress": Navigator.push<bool> + refresh saat return true
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DepartureReviewScreen(
                      pointId: request.id,
                      pointTitle: request.title,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  setState(() {
                    _detailFuture = _repo.getById(widget.request.id);
                  });
                }
              },
              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: const Text('Tindak Lanjut Donatur'),
            ),
          ),

          const SizedBox(height: 10),
        ],

        // ── CHAT ─────────────────────────────────────────────────────────
        if (!isOwner) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openChatWithMessage(request, null),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Hubungi Komunitas'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showReportDialog(DonationRequest request) {
    final reportCategories = ReportCategory.values;
    ReportCategory? selectedCategory;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Laporkan Titik Bantuan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kategori Laporan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: StatefulBuilder(
                  builder: (ctx2, setState2) => DropdownButton<ReportCategory>(
                    value: selectedCategory,
                    hint: const Text('Pilih kategori...'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: reportCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.label),
                      );
                    }).toList(),
                    onChanged: (cat) => setState2(() => selectedCategory = cat),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Penjelasan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Jelaskan alasan pelaporan...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: selectedCategory != null &&
                    reasonController.text.trim().isNotEmpty
                ? () async {
                    Navigator.pop(ctx);
                    await _submitReport(
                      request.id,
                      selectedCategory!,
                      reasonController.text.trim(),
                    );
                  }
                : null,
            child: const Text('Kirim Laporan'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(
    String pointId,
    ReportCategory category,
    String reason,
  ) async {
    try {
      await _repo.createReportWithCategory(
        pointId: pointId,
        category: category.name,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terima kasih! Laporan Anda telah kami terima.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
        ),
      );
    }
  }

  Widget _categoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}Jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}Rb';
    return n.toStringAsFixed(0);
  }
}
