import 'api_client.dart';

class StockService {
  static Future<List<Map<String, dynamic>>> getStockTransactions() async {
    try {
      final data = await ApiClient.get('/stocktransactions');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching stock transactions: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createStockTransaction(
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await ApiClient.post('/stocktransactions', body: data);
      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error creating stock transaction: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateStockTransaction(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await ApiClient.put('/stocktransactions/$id', body: data);
      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error updating stock transaction: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getStockTransactionsByProductId(
    int productId,
  ) async {
    try {
      final data = await ApiClient.get('/stocktransactions/product/$productId');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching stock history: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getStockSummaryByProductId(
    int productId,
  ) async {
    try {
      final data = await ApiClient.get(
        '/stocktransactions/product/$productId/summary',
      );
      return data as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching stock summary: $e');
      rethrow;
    }
  }
}
