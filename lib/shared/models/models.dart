// lib/shared/models/models.dart

enum UrgencyLevel { low, normal, urgent }

enum RequestStatus { open, onProgress, completed }

enum UserType { individu, organisasi }

enum FeedPostType {
  bantuanDibutuhkan,
  pertanyaan,
  updateKomunitas,
  inspirasi,
  kisahSukses,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserType type;
  final bool isVerified;
  final String? bio;
  final String role;
  final int donationCount;
  final int pointsHelped;
  final double totalDonation;
  final int communityPoints;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.type = UserType.individu,
    this.isVerified = false,
    this.bio,
    this.role = 'donatur',
    this.donationCount = 0,
    this.pointsHelped = 0,
    this.totalDonation = 0,
    this.communityPoints = 0,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}

class DonationRequest {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String? authorAvatar;
  final String? createdById;

  final UrgencyLevel urgency;
  final RequestStatus status;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String timeAgo;
  final String? imageUrl;
  final double goalAmount;
  final double collectedAmount;
  final List<String> tags;
  final String? goalText;
  final double? avgRating;

  const DonationRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorAvatar,
    this.createdById,
    required this.urgency,
    required this.status,
    required this.category,
    required this.location,
    this.latitude = -7.7956,
    this.longitude = 110.3695,
    this.distanceKm = 0,
    required this.timeAgo,
    this.imageUrl,
    this.goalAmount = 0, // ✅ default 0, tidak hardcode 5_000_000
    this.collectedAmount = 0, // ✅ default 0, tidak hardcode 2_500_000
    this.tags = const [],
    this.goalText,
    this.avgRating,
  });
}

// ✅ FIXED: tambah field likedByMe dan pointId
class FeedPost {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String content;
  final String timeAgo;
  final FeedPostType type;
  final String? imageUrl;
  final int likes;
  final int comments;
  final String? tagLabel;
  final bool likedByMe; // ✅ untuk toggle like di community feed
  final String? pointId; // ✅ untuk navigasi ke detail titik dari notifikasi
  final List<CommentModel> commentsList; // ✅ NEW: list of comments

  const FeedPost({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.authorRole,
    required this.content,
    required this.timeAgo,
    required this.type,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.tagLabel,
    this.likedByMe = false,
    this.pointId,
    this.commentsList = const [],
  });
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final String iconType; // 'success', 'donation', 'request'

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.iconType,
  });
}

class DonationHistory {
  final String id;
  final String requestId;
  final String title;
  final RequestStatus status;
  final String category;
  final String timeStr;
  final List<StatusUpdate> updates;
  final List<String> docImages;

  const DonationHistory({
    required this.id,
    required this.requestId,
    required this.title,
    required this.status,
    required this.category,
    required this.timeStr,
    this.updates = const [],
    this.docImages = const [],
  });
}

class StatusUpdate {
  final String dateStr;
  final String description;
  final bool isActive;

  const StatusUpdate({
    required this.dateStr,
    required this.description,
    this.isActive = false,
  });
}

// ✅ NEW: Report Categories
enum ReportCategory {
  alamatSalah,
  lokasiTidakSesuai,
  informasiPalsu,
  spam,
  ujaran,
  lainnya,
}

extension ReportCategoryExt on ReportCategory {
  String get label {
    return switch (this) {
      ReportCategory.alamatSalah => 'Alamat Salah',
      ReportCategory.lokasiTidakSesuai => 'Lokasi Tidak Sesuai',
      ReportCategory.informasiPalsu => 'Informasi Palsu',
      ReportCategory.spam => 'Spam',
      ReportCategory.ujaran => 'Ujaran Hateful',
      ReportCategory.lainnya => 'Lainnya',
    };
  }
}

// ✅ NEW: Report Model
class ReportModel {
  final String id;
  final String targetId; // pointId atau postId
  final String targetType; // 'point' atau 'post'
  final String reporterName;
  final String reporterRole;
  final String reason;
  final ReportCategory category;
  final String status; // 'pending', 'resolved', 'dismissed'
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.reporterName,
    required this.reporterRole,
    required this.reason,
    required this.category,
    this.status = 'pending',
    required this.createdAt,
  });
}

// ✅ NEW: Rating Model
class RatingModel {
  final String id;
  final String pointId;
  final String raterName;
  final String? raterAvatar;
  final int score; // 1-5
  final String? review;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.pointId,
    required this.raterName,
    this.raterAvatar,
    required this.score,
    this.review,
    required this.createdAt,
  });
}

// ✅ NEW: Comment Model
class CommentModel {
  final String id;
  final String postId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorName,
    this.authorAvatar,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });
}

// ✅ NEW: Notification Model
enum NotificationType {
  nearbyPoint,
  statusUpdate,
  like,
  comment,
  commentReply,
  departure,
  participantAccepted,
  participantCompleted,
}

class NotificationModel {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final Map<String, dynamic>? payload; // {pointId, postId, userId, etc}
  final DateTime createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.payload,
    required this.createdAt,
    this.read = false,
  });
}

class AdminReport {
  final String id;
  final String title;
  final String description;
  final String statusLabel;
  final String statusColor; // 'orange', 'yellow', 'green'
  final String timeAgo;
  final String iconType;
  final String? reporterName;
  final String? reportCategory;

  const AdminReport({
    required this.id,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.timeAgo,
    required this.iconType,
    this.reporterName,
    this.reportCategory,
  });
}
