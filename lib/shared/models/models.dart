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
    this.donationCount = 0,
    this.pointsHelped = 0,
    this.totalDonation = 0,
    this.communityPoints = 0,
  });
}

class DonationRequest {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String? authorAvatar;
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

  const DonationRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorAvatar,
    required this.urgency,
    required this.status,
    required this.category,
    required this.location,
    this.latitude = -7.7956,
    this.longitude = 110.3695,
    this.distanceKm = 0.3,
    required this.timeAgo,
    this.imageUrl,
    this.goalAmount = 5000000,
    this.collectedAmount = 2500000,
    this.tags = const [],
    this.goalText,
  });
}

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

class AdminReport {
  final String id;
  final String title;
  final String description;
  final String statusLabel;
  final String statusColor; // 'orange', 'yellow', 'green'
  final String timeAgo;
  final String iconType;

  const AdminReport({
    required this.id,
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.timeAgo,
    required this.iconType,
  });
}
