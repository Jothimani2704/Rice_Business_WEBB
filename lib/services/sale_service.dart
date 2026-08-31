import 'api_client.dart';

class SaleService {
  static Future<List<Map<String, dynamic>>> getSales() async {
    try {
      final data = await ApiClient.get('/sales');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching sales: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSaleById(int id) async {
    try {
      final data = await ApiClient.get('/sales/$id');
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching sale: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createSale(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await ApiClient.post('/sales', body: data);
      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error creating sale: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateSale(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await ApiClient.put('/sales/$id', body: data);
      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error updating sale: $e');
      rethrow;
    }
  }
}
