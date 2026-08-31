import 'api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>?> getSummary() async {
    try {
      final response = await ApiClient.get('/dashboard/summary');
      return response;
    } catch (e) {
      print('Error fetching dashboard summary: $e');
      return null;
    }
  }
}
