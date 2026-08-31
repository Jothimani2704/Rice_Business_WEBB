import 'api_client.dart';

class CustomerService {
  static Future<List<dynamic>?> getCustomers() async {
    try {
      final response = await ApiClient.get('/customers');
      return response;
    } catch (e) {
      print('Error fetching customers: $e');
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
}
