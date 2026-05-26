// lib/features/community/data/community_repository.dart
import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart' as AdaTitikDateUtils;

/// Repository resmi untuk seluruh operasi modul Komunitas.
/// Menggantikan pemakaian DonationRepository / getNearbyNotifications()
/// yang sebelumnya digunakan secara keliru di CommunityScreen.
class CommunityRepository {
  const CommunityRepository();

  // ─── GET /api/community/posts ───────────────────────────────────────────
  /// tab: 'terbaru' | 'populer' | 'diskusi'
  Future<List<FeedPost>> getPosts({
    String tab = 'terbaru',
    int page = 1,
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/community/posts',
      query: {'tab': tab, 'page': page, 'limit': limit},
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      throw Exception('Gagal memuat komunitas ($statusCode)');
    }

    final body = res.data ?? {};
    final data = (body['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().map(_mapPost).toList();
  }

  FeedPost _mapPost(Map<String, dynamic> item) {
    final typeStr = item['post_type']?.toString() ?? 'updateKomunitas';
    final type = _parsePostType(typeStr);

    return FeedPost(
      id: item['id']?.toString() ?? '',
      authorName: item['author_name']?.toString() ?? 'Anonim',
      authorAvatar: item['author_avatar']?.toString(),
      authorRole: item['author_role']?.toString() ?? 'komunitas',
      content: item['content']?.toString() ?? '',
      timeAgo: AdaTitikDateUtils.DateUtils.formatTimeAgo(
        item['created_at']?.toString() ?? item['createdAt']?.toString(),
      ),
      type: type,
      // API v3 memakai field: image_url
      imageUrl: item['image_url']?.toString(),
      likes: (item['likes_count'] as num?)?.toInt() ?? 0,
      comments: (item['comments_count'] as num?)?.toInt() ?? 0,
      tagLabel: _tagForType(type),
      likedByMe: item['liked_by_me'] == true,
    );
  }

  FeedPostType _parsePostType(String s) {
    return switch (s) {
      'bantuanDibutuhkan' => FeedPostType.bantuanDibutuhkan,
      'pertanyaan' => FeedPostType.pertanyaan,
      'inspirasi' => FeedPostType.inspirasi,
      'kisahSukses' => FeedPostType.kisahSukses,
      _ => FeedPostType.updateKomunitas,
    };
  }

  String? _tagForType(FeedPostType type) {
    return switch (type) {
      FeedPostType.bantuanDibutuhkan => 'BANTUAN DIBUTUHKAN',
      FeedPostType.pertanyaan => 'DISKUSI',
      FeedPostType.kisahSukses => 'KISAH SUKSES',
      FeedPostType.inspirasi => 'INSPIRASI',
      _ => null,
    };
  }

  // ─── POST /api/community/posts/:id/like ────────────────────────────────
  Future<({bool liked, int likesCount})> toggleLike(String postId) async {
    final id = int.tryParse(postId);
    if (id == null) throw ArgumentError('Post ID tidak valid: $postId');

    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/community/posts/$id/like',
      data: {},
    );

    final body = res.data ?? {};
    return (
      liked: body['liked'] == true,
      likesCount: (body['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  // ─── POST /api/community/posts ─────────────────────────────────────────
  Future<FeedPost> createPost({
    required String content,
    String postType = 'updateKomunitas',
    String? imageUrl,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Konten tidak boleh kosong.');
    }

    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/community/posts',
      data: {
        'content': content.trim(),
        'post_type': postType,
        if (imageUrl != null) 'image_url': imageUrl,
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode == 403) {
      throw Exception('Hanya akun komunitas yang bisa membuat postingan.');
    }
    if (statusCode != 201) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal membuat postingan ($statusCode)';
      throw Exception(msg);
    }

    final data = res.data?['data'];
    if (data is! Map<String, dynamic>) {
      // Beberapa backend mengirim response lain saat error upload gambar.
      // Hindari cast Map yang menyebabkan error tipe.
      final message =
          res.data?['message']?.toString() ?? res.data?['error']?.toString();
      throw Exception(message ?? 'Response format tidak sesuai');
    }
    return _mapPost(data);
  }

  // ─── GET /api/community/posts/:id/comments ─────────────────────────────
  Future<List<Map<String, dynamic>>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/community/posts/$postId/comments',
      query: {'page': page, 'limit': limit},
    );
    final data = (res.data?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  // ─── POST /api/community/posts/:id/comments ────────────────────────────
  Future<void> addComment(String postId, String content) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Komentar tidak boleh kosong.');
    }
    await ApiClient.post<Map<String, dynamic>>(
      '/api/community/posts/$postId/comments',
      data: {'content': content.trim()},
    );
  }

  // ─── Legacy: laporan titik (reuse endpoint /api/reports) ───────────────
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/api/reports',
      data: {
        'point_id': postId,
        'reason': reason,
      },
    );
  }
}
