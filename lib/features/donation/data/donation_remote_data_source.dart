import '../../../core/network/api_client.dart';

class DonationRemoteDataSource {
  const DonationRemoteDataSource();

  Future<Map<String, dynamic>> getProfile() async {
    final res = await ApiClient.get<Map<String, dynamic>>('/api/users/profile');
    final data = res.data;
    return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
  }
}
