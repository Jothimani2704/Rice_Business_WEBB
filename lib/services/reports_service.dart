import 'api_client.dart';

class ReportsService {
  static Future<List<dynamic>?> getRevenueTrends(String period) async {
    try {
      final response = await ApiClient.get('/reports/revenue-trends?period=$period');
      if (response != null && response is List) {
        return response;
      }
      return null;
    } catch (e) {
      print('Error fetching revenue trends: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getFinancialSummary(String period) async {
    try {
      final response = await ApiClient.get('/reports/summary?period=$period');
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      print('Error fetching financial summary: $e');
      return null;
    }
  }
}
