// lib/features/admin/data/admin_repository.dart
import '../../../core/network/api_client.dart';

class AdminRepository {
  const AdminRepository();

  Future<Map<String, dynamic>> getStats() async {
    final res = await ApiClient.get<Map<String, dynamic>>('/api/admin/stats');
    final body = res.data;
    return body?['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getReports({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    };

    final res = await ApiClient.get<Map<String, dynamic>>('/api/admin/reports',
        query: query);
    final body = res.data;
    final data = (body?['data'] as List?) ?? [];
    return data.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> updateReportStatus({
    required String reportId,
    required String status, // 'resolved' or 'dismissed'
  }) async {
    await ApiClient.patch<Map<String, dynamic>>(
      '/api/admin/reports/$reportId',
      data: {'status': status},
    );
  }

  Future<void> deletePoint(String pointId) async {
    await ApiClient.delete('/api/admin/points/$pointId');
  }
}
