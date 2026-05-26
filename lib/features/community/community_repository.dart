import '../../features/donation/data/donation_repository.dart';

class CommunityRepository {
  const CommunityRepository();

  /// Currently backend report endpoint is tied to "point" reporting.
  /// We reuse DonationRepository.createReport for community feed report.
  Future<void> reportPoint({
    required String pointId,
    required String reason,
  }) async {
    await const DonationRepository().createReport(
      pointId: pointId,
      reason: reason,
    );
  }
}
