import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  static Future<List<Payment>> getPayments() async {
    final response = await ApiClient.get('/payments');
    return (response as List).map((p) => Payment.fromJson(p)).toList();
  }

  static Future<Payment> createPayment(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/payments', body: data);
    return Payment.fromJson(response);
  }

  static Future<Payment> updatePayment(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.put('/payments/$id', body: data);
      return Payment.fromJson(response);
    } catch (e) {
      // Fallback if PUT endpoint is not available
      final response = await ApiClient.post('/payments', body: data);
      return Payment.fromJson(response);
    }
  }
}
