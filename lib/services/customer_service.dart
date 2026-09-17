import 'api_client.dart';
import 'offline_sync_service.dart';

class CustomerService {
  static Future<List<dynamic>?> getCustomers() async {
    try {
      final response = await ApiClient.get('/customers');
      if (response != null && response is List) {
        final customersList = List<Map<String, dynamic>>.from(response);
        await OfflineSyncService.cacheCustomers(customersList);
      }
      return response;
    } catch (e) {
      print('Error fetching customers from server, attempting offline cache: $e');
      final cached = await OfflineSyncService.getCachedCustomers();
      if (cached.isNotEmpty) {
        return cached;
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await ApiClient.post('/customers', body: customerData);
      return response;
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateCustomer(
    int id,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await ApiClient.put(
        '/customers/$id',
        body: customerData,
      );
      return response;
    } catch (e) {
      print('Error updating customer: $e');
      return null;
    }
  }

  static Future<List<dynamic>?> getCustomerTransactions(int customerId) async {
    try {
      final response = await ApiClient.get('/customers/$customerId/transactions');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching customer transactions: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getCustomerAccountSummary(int customerId) async {
    try {
      final response = await ApiClient.get('/customers/$customerId/account-summary');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching customer account summary: $e');
      return null;
    }
  }
}
