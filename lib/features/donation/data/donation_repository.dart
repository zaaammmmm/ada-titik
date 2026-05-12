import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class DonationRepository {
  const DonationRepository();

  // --- Heatmap ---
  /// Heatmap publik: GET /api/analytics/heatmap
  /// Response contract (from Postman): data[] items contain:
  /// - longitude: number
  /// - latitude: number
  /// - weight: 1..3  (1=Rendah, 2=Normal, 3=Mendesak)
  Future<List<Map<String, dynamic>>> getHeatmap() async {
    final res =
        await ApiClient.get<Map<String, dynamic>>('/api/analytics/heatmap');
    final body = res.data;
    final data = (body?['data'] as List?) ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => {
              'latitude': (e['latitude'] ?? e['lat'])?.toString() != null
                  ? (e['latitude'] ?? e['lat'])
                  : e['latitude'],
              'longitude': (e['longitude'] ?? e['lng'] ?? e['lon']),
              'weight': e['weight'],
            })
        .toList();
  }

  // --- Profile ---
  Future<UserModel> getProfile() async {
    final res = await ApiClient.get<Map<String, dynamic>>('/api/users/profile');
    final body = res.data;
    final data =
        body?['data'] ?? body; // support either {data: {...}} or direct model
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected response format for profile');
    }

    // Defensive mapping (keys may vary slightly)
    final id = data['id']?.toString() ?? '';
    final name =
        data['name']?.toString() ?? data['full_name']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final avatarUrl =
        data['avatar_url']?.toString() ?? data['avatarUrl']?.toString();
    final bio = data['bio']?.toString() ?? data['about']?.toString();

    final rawRole =
        data['role']?.toString() ?? data['type']?.toString() ?? 'donatur';
    final role = rawRole.toLowerCase();

    final type = switch (role) {
      'komunitas' => UserType.organisasi,
      'organisasi' => UserType.organisasi,
      'organization' => UserType.organisasi,
      'org' => UserType.organisasi,
      _ => UserType.individu,
    };

    final isVerified = data['is_verified'] == true || data['verified'] == true;

    final donationCount = (data['donation_count'] ?? data['donationCount'])
            is num
        ? (data['donation_count'] ?? data['donationCount']).toString().isEmpty
            ? 0
            : (data['donation_count'] ?? data['donationCount']).toInt()
        : (data['donationCount'] is int ? data['donationCount'] as int : 0);

    final communityPoints =
        (data['community_points'] ?? data['communityPoints']) is num
            ? (data['community_points'] ?? data['communityPoints']).toInt()
            : 0;

    final pointsHelped = (data['points_helped'] ?? data['pointsHelped']) is num
        ? (data['points_helped'] ?? data['pointsHelped']).toInt()
        : 0;

    final totalDonation =
        (data['total_donation'] ?? data['totalDonation']) is num
            ? (data['total_donation'] ?? data['totalDonation']).toDouble()
            : 0.0;

    return UserModel(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      type: type,
      isVerified: isVerified,
      bio: bio,
      role: role,
      donationCount: donationCount,
      pointsHelped: pointsHelped,
      totalDonation: totalDonation,
      communityPoints: communityPoints,
    );
  }

  UrgencyLevel _urgencyFromBackend(String? v) {
    final s = (v ?? '').trim();
    switch (s) {
      case 'Mendesak':
        return UrgencyLevel.urgent;
      case 'Normal':
        return UrgencyLevel.normal;
      case 'Rendah':
        return UrgencyLevel.low;
      default:
        return UrgencyLevel.normal;
    }
  }

  RequestStatus _statusFromBackend(String? v) {
    final s = (v ?? '').trim();
    switch (s) {
      case 'Open':
        return RequestStatus.open;
      case 'On Progress':
        return RequestStatus.onProgress;
      case 'Completed':
        return RequestStatus.completed;
      default:
        return RequestStatus.open;
    }
  }

  DonationRequest _mapDonation(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';

    final title = item['title']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';

    // Backend schema: donation_points.created_by -> users.id.
    // In JSON, commonly the creator/user may be embedded (author, createdBy, user).
    // We defensively try multiple keys.
    final authorName = item['author_name']?.toString() ??
        item['created_by_name']?.toString() ??
        item['authorName']?.toString() ??
        item['user_name']?.toString() ??
        'Unknown';

    final authorAvatar = item['author_avatar']?.toString() ??
        item['authorAvatar']?.toString() ??
        item['avatar_url']?.toString();

    final urgency = _urgencyFromBackend(item['urgency']?.toString());
    final status = _statusFromBackend(item['status']?.toString());

    final category = item['category']?.toString() ?? 'Umum';

    // Location: backend uses PostGIS geometry (Point, 4326).
    // JSON may come as longitude/latitude keys.
    double _toDouble(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      return fallback;
    }

    // Note: helper above is used below.

    final longitude = _toDouble(item['longitude'],
        _toDouble(item['lng'], _toDouble(item['lon'], 110.3695)));

    final latitude = _toDouble(item['latitude'],
        _toDouble(item['lat'], _toDouble(item['geo_lat'], -7.7956)));

    final location = item['location']?.toString() ?? 'Lokasi belum tersedia';

    // These are UI-specific convenience fields.
    final distanceKm = (item['distance_km'] is num)
        ? (item['distance_km'] as num).toDouble()
        : (item['distanceKm'] is num)
            ? (item['distanceKm'] as num).toDouble()
            : (item['distance_meters'] is num)
                ? ((item['distance_meters'] as num).toDouble() / 1000.0)
                : 0.3;

    final timeAgo = item['time_ago']?.toString() ??
        item['timeAgo']?.toString() ??
        item['created_at']?.toString() ??
        'Baru';

    final imageUrl = item['image_url']?.toString() ??
        item['imageUrl']?.toString() ??
        item['photo_url']?.toString();

    final goalAmount = (item['goal_amount'] is num)
        ? (item['goal_amount'] as num).toDouble()
        : (item['goalAmount'] is num)
            ? (item['goalAmount'] as num).toDouble()
            : (item['goal'] is num)
                ? (item['goal'] as num).toDouble()
                : 5000000.0;

    final collectedAmount = (item['collected_amount'] is num)
        ? (item['collected_amount'] as num).toDouble()
        : (item['collectedAmount'] is num)
            ? (item['collectedAmount'] as num).toDouble()
            : 2500000.0;

    final avgRating = (item['avg_rating'] is num)
        ? (item['avg_rating'] as num).toDouble()
        : (item['avgRating'] is num)
            ? (item['avgRating'] as num).toDouble()
            : (item['avg_score'] is num)
                ? (item['avg_score'] as num).toDouble()
                : null;

    final tagsRaw = item['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        if (t == null) continue;
        tags.add(t.toString());
      }
    }

    final goalText =
        item['goal_text']?.toString() ?? item['goalText']?.toString();

    return DonationRequest(
      id: id,
      title: title,
      description: description,
      authorName: authorName,
      authorAvatar: authorAvatar,
      urgency: urgency,
      status: status,
      category: category,
      location: location,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      timeAgo: timeAgo,
      imageUrl: imageUrl,
      goalAmount: goalAmount,
      collectedAmount: collectedAmount,
      tags: tags,
      goalText: goalText,
      avgRating: avgRating,
    );
  }

  Future<List<DonationRequest>> getAll({
    UrgencyLevel? urgency,
    RequestStatus? status,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      if (urgency != null) 'urgency': _urgencyToBackend(urgency),
      if (status != null) 'status': _statusToBackend(status),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      'page': page,
      'limit': limit,
    };

    final res = await ApiClient.get<Map<String, dynamic>>('/api/donations',
        query: query);

    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().map(_mapDonation).toList();
  }

  String _urgencyToBackend(UrgencyLevel u) {
    return switch (u) {
      UrgencyLevel.urgent => 'Mendesak',
      UrgencyLevel.normal => 'Normal',
      UrgencyLevel.low => 'Rendah',
    };
  }

  String _statusToBackend(RequestStatus s) {
    return switch (s) {
      RequestStatus.open => 'Open',
      RequestStatus.onProgress => 'On Progress',
      RequestStatus.completed => 'Completed',
    };
  }

  Future<DonationRequest> getById(String pointId) async {
    final res =
        await ApiClient.get<Map<String, dynamic>>('/api/donations/$pointId');
    final body = res.data;
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      return _mapDonation(data);
    }
    throw StateError('Unexpected response format for donation detail');
  }

  Future<List<DonationRequest>> getNearby({
    required double lat,
    required double lng,
    int radiusMeters = 5000,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/donations/nearby',
      query: {
        'lat': lat,
        'lng': lng,
        'radius': radiusMeters,
      },
    );

    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().map(_mapDonation).toList();
  }

  Future<DonationRequest> createDonation({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    UrgencyLevel urgency = UrgencyLevel.normal,
    String? category,
  }) async {
    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/donations',
      data: {
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'urgency': _urgencyToBackend(urgency),
        if (category != null) 'category': category,
      },
    );

    final body = res.data;
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      return _mapDonation(data);
    }
    throw StateError('Unexpected response format for create donation');
  }

  Future<DonationRequest> updateStatus({
    required String requestId,
    required RequestStatus status,
  }) async {
    final res = await ApiClient.patch<Map<String, dynamic>>(
      '/api/donations/$requestId',
      data: {
        // defensif: backend kemungkinan menerima field `status`
        // atau variasi lain; kita pakai yang umum sesuai TODO.
        'status': _statusToBackend(status),
      },
    );

    final body = res.data;
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      return _mapDonation(data);
    }

    // Fallback: kalau backend balikin data tidak terstruktur
    // tetap kembalikan id + status minimal.
    return DonationRequest(
      id: requestId,
      title: '',
      description: '',
      authorName: '',
      authorAvatar: null,
      urgency: UrgencyLevel.normal,
      status: status,
      category: '',
      location: '',
      timeAgo: 'Baru',
      imageUrl: null,
      avgRating: null,
    );
  }

  // --- Ratings ---
  Future<List<Map<String, dynamic>>> getRatings(String pointId) async {
    final res =
        await ApiClient.get<Map<String, dynamic>>('/api/ratings/$pointId');
    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> createRating({
    required String pointId,
    required int score,
    String? review,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/api/ratings',
      data: {
        'point_id': pointId,
        'score': score,
        if (review != null) 'review': review,
      },
    );
  }

  // --- Documentation ---
  Future<List<Map<String, dynamic>>> getDocumentation(String pointId) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/documentation/$pointId');
    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> uploadDocumentation({
    required String pointId,
    required String photoUrl,
    String? caption,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/api/documentation',
      data: {
        'point_id': pointId,
        'photo_url': photoUrl,
        if (caption != null) 'caption': caption,
      },
    );
  }

  // --- Reports ---
  Future<void> createReport({
    required String pointId,
    required String reason,
  }) async {
    await ApiClient.post<Map<String, dynamic>>(
      '/api/reports',
      data: {
        'point_id': pointId,
        'reason': reason,
      },
    );
  }
}
