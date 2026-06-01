import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/utils/date_utils.dart' as AdaTitikDateUtils;

class DonationRepository {
  const DonationRepository();

  // ─── Helpers: parsing numerik string dari PostgreSQL ──────────────────────
  // Backend (driver `pg`) mengembalikan DECIMAL/NUMERIC sebagai String.
  // Contoh: goal_amount -> "5000000.00", avg_rating -> "4.50"
  double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  // --- Heatmap ---
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
    final data = body?['data'] ?? body;
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected response format for profile');
    }

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

    // ✅ FIXED: gunakan _parseInt agar string "5" terparsing dengan benar
    final donationCount = _parseInt(
      data['donation_count'] ?? data['donationCount'],
      0,
    );

    final communityPoints = _parseInt(
      data['community_points'] ?? data['communityPoints'],
      0,
    );

    final pointsHelped = _parseInt(
      data['points_helped'] ?? data['pointsHelped'],
      0,
    );

    // ✅ FIXED: backend mengembalikan "35000000" (String), bukan number
    final totalDonation = _parseDouble(
      data['total_donation'] ?? data['totalDonation'],
      0.0,
    );

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

  Future<List<ActivityItem>> getUserActivity({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/users/activity',
      query: {'page': page, 'limit': limit},
    );

    final body = res.data;
    final data = (body?['data'] as List?) ?? [];

    return data.whereType<Map<String, dynamic>>().map(_mapActivity).toList();
  }

  /// Donasi Saya khusus untuk role donatur.
  /// Ambil activity dan filter type yang sesuai dokumentasi backend: `rating_given`.
  Future<List<ActivityItem>> getDonationsAsDonatur({
    int limit = 10,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/users/activity',
      query: {'page': 1, 'limit': limit},
    );

    final body = res.data;
    final data = (body?['data'] as List?) ?? [];

    final items = data.whereType<Map<String, dynamic>>();
    final filtered = items.where(
      (e) => (e['type']?.toString() ?? '').toLowerCase() == 'rating_given',
    );

    return filtered.map(_mapActivity).toList();
  }

  /// GET /api/users/activity (untuk komunitas): type=donation_managed
  /// Shape v3: { id, title, subtitle, type, created_at, status, urgency, category }
  /// Kita tampilkan sebagai list DonationRequest (karena FE butuh data titik).
  Future<List<DonationRequest>> getManagedPoints() async {
    // Ambil limit besar agar tab "Kelola Bantuan" tidak sering minta halaman.
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/users/activity',
      query: {'page': 1, 'limit': 50},
    );

    final body = res.data ?? {};
    final data = (body['data'] as List?) ?? [];

    final items = data.whereType<Map<String, dynamic>>().toList();
    final managed =
        items.where((e) => (e['type']?.toString() ?? '') == 'donation_managed');

    // catatan: backend activity donation_managed mengembalikan status/urgency/category.
    // field koordinat tidak selalu tersedia, sehingga untuk aksi accept/complete
    // FE tetap butuh detail dari /api/donations/:id.
    return managed.map((e) {
      final idStr = e['id']?.toString() ?? '';
      final createdAt = e['created_at']?.toString() ?? '';

      final urgency = _urgencyFromBackend(e['urgency']?.toString());
      final status = _statusFromBackend(e['status']?.toString());
      final category = e['category']?.toString() ?? 'Umum';

      return DonationRequest(
        id: idStr,
        title: e['title']?.toString() ?? '',
        description: e['subtitle']?.toString() ?? '',
        authorName: '',
        urgency: urgency,
        status: status,
        category: category,
        location: '',
        latitude: -7.7956,
        longitude: 110.3695,
        distanceKm: 0,
        timeAgo: createdAt,
        imageUrl: null,
        goalAmount: _parseDouble(e['goal_amount'] ?? e['goalAmount'], 0.0),
        collectedAmount:
            _parseDouble(e['collected_amount'] ?? e['collectedAmount'], 0.0),
        tags: const [],
        goalText: null,
        avgRating: null,
        authorAvatar: null,
        createdById: null,
      );
    }).toList();
  }

  ActivityItem _mapActivity(Map<String, dynamic> item) {
    final title = item['title']?.toString() ??
        item['activity']?.toString() ??
        item['description']?.toString() ??
        item['message']?.toString() ??
        item['name']?.toString() ??
        'Aktivitas terbaru';

    final subtitle = item['subtitle']?.toString() ??
        item['detail']?.toString() ??
        item['meta']?.toString() ??
        '';

    final rawTime = item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        item['date']?.toString() ??
        item['time_ago']?.toString() ??
        item['timeAgo']?.toString();
    final timeAgo = rawTime != null && rawTime.contains('T')
        ? AdaTitikDateUtils.DateUtils.formatTimeAgo(rawTime)
        : rawTime ?? 'Baru';

    final type = item['type']?.toString() ??
        item['activity_type']?.toString() ??
        item['event']?.toString();
    final status = item['status']?.toString() ?? '';

    return ActivityItem(
      id: item['id']?.toString() ?? item['activity_id']?.toString() ?? title,
      title: title,
      subtitle: subtitle,
      timeAgo: timeAgo,
      iconType: _activityIconType(type, status, title, subtitle),
    );
  }

  String _activityIconType(
      String? type, String status, String title, String subtitle) {
    final lowerType = type?.toLowerCase() ?? '';
    final lowerStatus = status.toLowerCase();
    final lowerText = '${title.toLowerCase()} ${subtitle.toLowerCase()}';

    if (lowerStatus.contains('complete') || lowerStatus.contains('selesai')) {
      return 'success';
    }
    if (lowerType.contains('rating') || lowerText.contains('donasi')) {
      return 'donation';
    }
    return 'request';
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

    double toCoord(dynamic v, double fallback) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    final longitude = toCoord(item['longitude'],
        toCoord(item['lng'], toCoord(item['lon'], 110.3695)));

    final latitude = toCoord(item['latitude'],
        toCoord(item['lat'], toCoord(item['geo_lat'], -7.7956)));

    final location = item['location']?.toString() ?? 'Lokasi belum tersedia';

    final _rawTimeAgo = item['time_ago']?.toString() ??
        item['timeAgo']?.toString() ??
        item['created_at']?.toString();
    final timeAgo = _rawTimeAgo != null && _rawTimeAgo.contains('T')
        ? AdaTitikDateUtils.DateUtils.formatTimeAgo(_rawTimeAgo)
        : _rawTimeAgo ?? 'Baru';

    final imageUrl = item['image_url']?.toString() ??
        item['imageUrl']?.toString() ??
        item['photo_url']?.toString();

    // ✅ FIXED: backend mengembalikan "5000000.00" (String), bukan num.
    // Dulu: `item['goal_amount'] is num` -> selalu false untuk String -> fallback hardcoded
    final goalAmount = _parseDouble(
      item['goal_amount'] ?? item['goalAmount'] ?? item['goal'],
      0.0, // default 0 (tidak hardcode 5_000_000)
    );

    final collectedAmount = _parseDouble(
      item['collected_amount'] ?? item['collectedAmount'],
      0.0, // default 0 (tidak hardcode 2_500_000)
    );

    // ✅ FIXED: avg_rating juga bisa datang sebagai String "4.50"
    final avgRating = _parseNullableDouble(
      item['avg_rating'] ?? item['avgRating'] ?? item['avg_score'],
    );

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

    // final distanceMeters = _parseDouble(
    //   item['distance_meters'] ?? item['distance'],
    //   0,
    // );

    final distanceMeters = double.tryParse(
          (item['distance_meters'] ?? 0).toString(),
        ) ??
        0;

    final createdById =
        item['created_by']?.toString() ?? item['createdById']?.toString();

    final distanceKm = distanceMeters > 0
        ? (distanceMeters / 1000.0)
        : 0.0; // jarak dari backend jika ada, fallback 0

    return DonationRequest(
      id: id,
      title: title,
      description: description,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdById: createdById,
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
    String? category,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      if (urgency != null) 'urgency': _urgencyToBackend(urgency),
      if (status != null) 'status': _statusToBackend(status),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
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

  // ✅ FIXED: lat/lng tidak lagi hardcoded — diambil dari GPS user
  Future<List<FeedPost>> getNearbyNotifications({
    double? lat,
    double? lng,
    int radiusMeters = 5000,
    int limit = 10,
  }) async {
    double resolvedLat = lat ?? LocationService.defaultCenter.latitude;
    double resolvedLng = lng ?? LocationService.defaultCenter.longitude;

    if (lat == null || lng == null) {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        resolvedLat = pos.latitude;
        resolvedLng = pos.longitude;
      }
    }

    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/notifications/nearby',
      query: {
        'lat': resolvedLat,
        'lng': resolvedLng,
        'radius': radiusMeters,
        'limit': limit,
      },
    );

    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_mapNotification)
        .toList();
  }

  // ✅ FIXED: mapping field sesuai response shape v3:
  // { id, title: "Bantuan baru di dekat Anda", subtitle: <judul titik>,
  //   type, urgency, category, distance_meters, point_id }
  FeedPost _mapNotification(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final pointId = item['point_id']?.toString() ?? '';

    // v3: 'title' = label konstan; 'subtitle' = judul titik bantuan sebenarnya
    final judul = item['subtitle']?.toString() ??
        item['title']?.toString() ??
        'Bantuan Dibutuhkan';

    final category = item['category']?.toString() ?? 'Umum';
    final urgency = item['urgency']?.toString() ?? '';
    final timeAgo = item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        'Baru';

    final type = urgency.toLowerCase().contains('mendesak')
        ? FeedPostType.bantuanDibutuhkan
        : FeedPostType.updateKomunitas;

    return FeedPost(
      id: id,
      authorName: 'Bantuan Baru',
      authorRole: category,
      content: judul,
      timeAgo: timeAgo,
      type: type,
      imageUrl: null,
      likes: 0,
      comments: 0,
      tagLabel:
          urgency.isNotEmpty ? urgency.toUpperCase() : 'BANTUAN DIBUTUHKAN',
      likedByMe: false,
      pointId: pointId,
    );
  }

  // ✅ FIXED: tambah parameter goalAmount yang sebelumnya tidak dikirim ke backend
  Future<DonationRequest> createDonation({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    UrgencyLevel urgency = UrgencyLevel.normal,
    String? category,
    double goalAmount = 0,
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
        'goal_amount': goalAmount, // ✅ sebelumnya tidak dikirim sama sekali
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 201) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal membuat titik bantuan ($statusCode)';
      throw Exception(msg);
    }

    final body = res.data;
    final data = body?['data'];
    if (data is Map<String, dynamic>) {
      return _mapDonation(data);
    }
    throw StateError('Unexpected response format for create donation');
  }

  // ✅ FIXED SEPENUHNYA:
  // 1. Endpoint diubah dari /api/donations/:id -> /api/donations/:id/status
  // 2. Tambah parameter userLat/userLng (wajib untuk status Completed / geo-fencing)
  // 3. Error handling berdasarkan status code dari API Docs
  Future<void> updateStatus({
    required String requestId,
    required RequestStatus status,
    double? userLat,
    double? userLng,
  }) async {
    final body = <String, dynamic>{
      'status': _statusToBackend(status),
    };

    if (status == RequestStatus.completed) {
      if (userLat == null || userLng == null) {
        throw Exception(
          'GPS wajib aktif untuk menyelesaikan titik bantuan (geo-fencing ≤100m).',
        );
      }
      body['user_lat'] = userLat;
      body['user_lng'] = userLng;
    }

    final res = await ApiClient.patch<Map<String, dynamic>>(
      '/api/donations/$requestId/status', // ✅ endpoint benar
      data: body,
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode == 403) {
      final msg = res.data?['error']?.toString() ?? 'Akses ditolak';
      throw Exception(msg);
    }
    if (statusCode == 404) {
      throw Exception('Titik bantuan tidak ditemukan.');
    }
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal memperbarui status ($statusCode)';
      throw Exception(msg);
    }
  }

  // --- Ratings ---
  Future<List<Map<String, dynamic>>> getRatings(String pointId) async {
    final res =
        await ApiClient.get<Map<String, dynamic>>('/api/ratings/$pointId');
    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  // ✅ FIXED: point_id dikirim sebagai integer, bukan String
  // API backend mensyaratkan point_id bertipe integer
  Future<void> createRating({
    required String pointId,
    required int score,
    String? review,
  }) async {
    final pointIdInt = int.tryParse(pointId);
    if (pointIdInt == null) {
      throw ArgumentError('point_id tidak valid: $pointId');
    }

    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/ratings',
      data: {
        'point_id': pointIdInt, // ✅ integer, bukan String
        'score': score,
        if (review != null && review.trim().isNotEmpty) 'review': review.trim(),
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode == 409) {
      throw Exception(
          'Anda sudah pernah memberi rating untuk titik bantuan ini.');
    }
    if (statusCode != 201 && statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal mengirim rating ($statusCode)';
      throw Exception(msg);
    }
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
    final bytes = _dataUrlToBytes(photoUrl);

    final formData = FormData.fromMap({
      'point_id': pointId,
      if (caption != null) 'caption': caption,
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: 'documentation-$pointId.jpg',
      ),
    });

    await ApiClient.post<Map<String, dynamic>>(
      '/api/documentation',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  List<int> _dataUrlToBytes(String dataUrl) {
    final idx = dataUrl.indexOf('base64,');
    if (idx == -1) return [];
    final b64 = dataUrl.substring(idx + 'base64,'.length);
    return base64Decode(b64);
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

  // ✅ NEW: Create report with category
  Future<void> createReportWithCategory({
    required String pointId,
    required String category,
    required String reason,
  }) async {
    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/reports',
      data: {
        'point_id': pointId,
        'reason': reason,
        'category': category,
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 201 && statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal mengirim laporan ($statusCode)';
      throw Exception(msg);
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // v3.2 Flow Donation Participants
  // Endpoint sumber notifikasi event-driven:
  // - POST   /api/donations/:pointId/participants (donatur: Berangkat)
  // - DELETE /api/donations/:pointId/participants/me
  // - GET    /api/donations/:pointId/participants/me
  // - PATCH  /api/donations/:pointId/participants/accept (komunitas bulk)
  // - PATCH  /api/donations/:pointId/participants/complete (komunitas bulk + geo-fence)
  // - GET    /api/donations/:pointId/participants?state=requested
  // ───────────────────────────────────────────────────────────────────────

  Future<void> sendDeparture({
    required String pointId,
    double? userLat,
    double? userLng,
  }) async {
    double? resolvedLat = userLat;
    double? resolvedLng = userLng;

    // user_lat/user_lng opsional di docs; tapi kalau belum ada, kita boleh pakai GPS.
    if (resolvedLat == null || resolvedLng == null) {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        resolvedLat = pos.latitude;
        resolvedLng = pos.longitude;
      }
    }

    final data = <String, dynamic>{
      if (resolvedLat != null) 'user_lat': resolvedLat,
      if (resolvedLng != null) 'user_lng': resolvedLng,
    };

    final res = await ApiClient.post<Map<String, dynamic>>(
      '/api/donations/$pointId/participants',
      data: data,
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200 && statusCode != 201) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal mengirim sinyal Berangkat ($statusCode)';
      throw Exception(msg);
    }
  }

  Future<List<Map<String, dynamic>>> getParticipants({
    required String pointId,
    required String state,
  }) async {
    final res = await ApiClient.get<Map<String, dynamic>>(
      '/api/donations/$pointId/participants',
      query: {
        'state': state,
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal memuat peserta ($statusCode)';
      throw Exception(msg);
    }

    final body = res.data ?? {};
    final data = body['data'];
    if (data is! List) return [];

    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> acceptParticipants({
    required String pointId,
    required List<String> donatorIds,
  }) async {
    if (donatorIds.isEmpty) {
      throw ArgumentError('donatorIds tidak boleh kosong');
    }

    final res = await ApiClient.patch<Map<String, dynamic>>(
      '/api/donations/$pointId/participants/accept',
      data: {
        'donator_ids': donatorIds,
      },
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal accept peserta ($statusCode)';
      throw Exception(msg);
    }
  }

  Future<void> completeParticipants({
    required String pointId,
    required List<String> donatorIds,
    required double userLat,
    required double userLng,
    double? perDonatorAmount,
  }) async {
    if (donatorIds.isEmpty) {
      throw ArgumentError('donatorIds tidak boleh kosong');
    }

    final data = <String, dynamic>{
      'donator_ids': donatorIds,
      'user_lat': userLat,
      'user_lng': userLng,
      if (perDonatorAmount != null) 'per_donator_amount': perDonatorAmount,
    };

    final res = await ApiClient.patch<Map<String, dynamic>>(
      '/api/donations/$pointId/participants/complete',
      data: data,
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal complete peserta ($statusCode)';
      throw Exception(msg);
    }
  }

  // NOTE: method legacy updateDonationStatus dihapus/di-nonaktifkan.
  // Flow v3.2 menggunakan participants/*.

  // ✅ NEW: Get donation detail with ratings and documentation
  Future<
      ({
        DonationRequest point,
        List<RatingModel> ratings,
        List<Map<String, dynamic>> documentation
      })> getDonationDetail(String pointId) async {
    try {
      // Fetch point detail
      final pointRes = await ApiClient.get<Map<String, dynamic>>(
        '/api/donations/$pointId',
      );
      final pointData = pointRes.data?['data'] ?? pointRes.data;
      if (pointData is! Map<String, dynamic>) {
        throw StateError('Invalid point data format');
      }

      final point = _mapDonation(pointData);

      // Fetch ratings
      final ratingsRes = await ApiClient.get<Map<String, dynamic>>(
        '/api/ratings/$pointId',
      );
      final ratingsData = (ratingsRes.data?['data'] as List?) ?? [];
      final ratings = ratingsData
          .whereType<Map<String, dynamic>>()
          .map(_mapRating)
          .toList();

      // Fetch documentation
      final docsRes = await ApiClient.get<Map<String, dynamic>>(
        '/api/documentation/$pointId',
      );
      final docsData = (docsRes.data?['data'] as List?) ?? [];
      final documentation = docsData.whereType<Map<String, dynamic>>().toList();

      return (point: point, ratings: ratings, documentation: documentation);
    } catch (e) {
      print('❌ Error getting donation detail: $e');
      rethrow;
    }
  }

  RatingModel _mapRating(Map<String, dynamic> item) {
    return RatingModel(
      id: item['id']?.toString() ?? '',
      pointId: item['point_id']?.toString() ?? '',
      raterName: item['user_name']?.toString() ??
          item['rater_name']?.toString() ??
          'Anonim',
      raterAvatar:
          item['user_avatar']?.toString() ?? item['rater_avatar']?.toString(),
      score: _parseInt(item['score'], 5),
      review: item['review']?.toString(),
      createdAt: _parseDateTime(item['created_at']),
    );
  }

  // ─── PATCH /api/donations/:pointId/progress ───────────────────────────
  /// Update progress manual oleh komunitas (owner titik)
  Future<void> updateProgress({
    required String pointId,
    double? goalAmount,
    double? collectedAmount,
  }) async {
    final data = <String, dynamic>{
      if (goalAmount != null) 'goal_amount': goalAmount,
      if (collectedAmount != null) 'collected_amount': collectedAmount,
    };

    final res = await ApiClient.patch<Map<String, dynamic>>(
      '/api/donations/$pointId/progress',
      data: data,
    );

    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal update progress ($statusCode)';
      throw Exception(msg);
    }
  }

  // ─── GET /api/donations/:pointId/participants/me ───────────────────────
  /// Cek status partisipasi donatur sendiri pada titik tertentu
  Future<Map<String, dynamic>?> getMyParticipation(String pointId) async {
    try {
      final res = await ApiClient.get<Map<String, dynamic>>(
        '/api/donations/$pointId/participants/me',
      );
      final body = res.data ?? {};
      final data = body['data'];
      if (data == null) return null;
      return data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Batalkan keberangkatan donatur
  Future<void> cancelDeparture(String pointId) async {
    final res = await ApiClient.delete<Map<String, dynamic>>(
      '/api/donations/$pointId/participants/me',
    );
    final statusCode = res.statusCode ?? 0;
    if (statusCode != 200) {
      final msg = res.data?['error']?.toString() ??
          res.data?['message']?.toString() ??
          'Gagal batalkan keberangkatan ($statusCode)';
      throw Exception(msg);
    }
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
