import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class MeRepository {
  const MeRepository();

  /// GET /api/me/community/posts
  Future<List<FeedPost>> getMyCommunityPosts({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/me/community/posts',
      query: {
        'page': page,
        'limit': limit,
      },
    );

    final data = (res.data?['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => _mapMyPost(e))
        .toList();
  }

  /// GET /api/me/community/likes
  Future<List<FeedPost>> getMyCommunityLikes({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/me/community/likes',
      query: {
        'page': page,
        'limit': limit,
      },
    );

    final data = (res.data?['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((likeRow) {
          final postSnapshot = likeRow['post_snapshot'];
          if (postSnapshot is! Map<String, dynamic>) {
            return null;
          }

          final snap = postSnapshot;
          final post = _mapMyPost(snap);

          // Keep like timestamp in timeAgo if available
          // Endpoint docs: likeRow has created_at (waktu like)
          final createdAtRaw = likeRow['created_at']?.toString();
          final timeAgo = createdAtRaw ?? post.timeAgo;

          return FeedPost(
            id: post.id,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            authorRole: post.authorRole,
            content: post.content,
            timeAgo: timeAgo,
            type: post.type,
            imageUrl: post.imageUrl,
            likes: post.likes,
            comments: post.comments,
            tagLabel: post.tagLabel,
            likedByMe: post.likedByMe,
            pointId: post.pointId,
            commentsList: post.commentsList,
          );
        })
        .whereType<FeedPost>()
        .toList();
  }

  /// GET /api/me/community/comments
  Future<List<FeedPost>> getMyCommunityComments({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/me/community/comments',
      query: {
        'page': page,
        'limit': limit,
      },
    );

    final data = (res.data?['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((commentRow) {
          final postSnapshot = commentRow['post_snapshot'];
          if (postSnapshot is! Map<String, dynamic>) {
            return null;
          }

          final snap = postSnapshot;
          final post = _mapMyPost(snap);

          final content = commentRow['content']?.toString() ?? '';
          final createdAtRaw = commentRow['created_at']?.toString();
          final timeAgo = createdAtRaw ?? post.timeAgo;

          // Put comment content into FeedPost.content temporarily
          return FeedPost(
            id: post.id,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            authorRole: post.authorRole,
            content: content,
            timeAgo: timeAgo,
            type: post.type,
            imageUrl: post.imageUrl,
            likes: post.likes,
            comments: post.comments,
            tagLabel: post.tagLabel,
            likedByMe: post.likedByMe,
            pointId: post.pointId,
            commentsList: post.commentsList,
          );
        })
        .whereType<FeedPost>()
        .toList();
  }

  FeedPost _mapMyPost(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final content = item['content']?.toString() ?? '';
    final typeStr = item['post_type']?.toString() ?? '';

    final type = _parsePostType(typeStr);

    final likes = (item['likes_count'] as num?)?.toInt() ??
        (item['likes'] as num?)?.toInt() ??
        0;
    final comments = (item['comments_count'] as num?)?.toInt() ??
        (item['comments'] as num?)?.toInt() ??
        0;

    final createdAtRaw =
        item['created_at']?.toString() ?? item['createdAt']?.toString() ?? '';

    return FeedPost(
      id: id,
      authorName: item['author_name']?.toString() ??
          item['authorName']?.toString() ??
          '',
      authorAvatar:
          item['author_avatar']?.toString() ?? item['authorAvatar']?.toString(),
      authorRole: item['author_role']?.toString() ??
          item['authorRole']?.toString() ??
          '',
      content: content,
      timeAgo: createdAtRaw,
      type: type,
      imageUrl: item['image_url']?.toString() ?? item['imageUrl']?.toString(),
      likes: likes,
      comments: comments,
      tagLabel: item['tag_label']?.toString() ?? item['tagLabel']?.toString(),
      likedByMe: item['liked_by_me'] == true || item['likedByMe'] == true,
      pointId: item['point_id']?.toString() ?? item['pointId']?.toString(),
    );
  }

  FeedPostType _parsePostType(String s) {
    return switch (s) {
      'bantuanDibutuhkan' => FeedPostType.bantuanDibutuhkan,
      'pertanyaan' => FeedPostType.pertanyaan,
      'updateKomunitas' => FeedPostType.updateKomunitas,
      'inspirasi' => FeedPostType.inspirasi,
      'kisahSukses' => FeedPostType.kisahSukses,
      _ => FeedPostType.updateKomunitas,
    };
  }
}
