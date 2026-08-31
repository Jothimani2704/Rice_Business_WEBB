import 'api_client.dart';

class ReportService {
  static Future<List<dynamic>> getSalesReport(
    String startDate,
    String endDate,
  ) async {
    final response = await ApiClient.get(
      '/reports/sales?startDate=$startDate&endDate=$endDate',
    );
    return response as List;
  }

  static Future<List<dynamic>> getPaymentReport(
    String startDate,
    String endDate,
  ) async {
    final response = await ApiClient.get(
      '/reports/payments?startDate=$startDate&endDate=$endDate',
    );
    return response as List;
  }

  static Future<List<dynamic>> getCustomerBalanceReport() async {
    final response = await ApiClient.get('/reports/customer-balances');
    return response as List;
  }

  static Future<List<dynamic>> getStockReport() async {
    final response = await ApiClient.get('/reports/stock');
    return response as List;
  }

  static Future<List<dynamic>> getProductSalesReport(
    String startDate,
    String endDate,
  ) async {
    final response = await ApiClient.get(
      '/reports/product-sales?startDate=$startDate&endDate=$endDate',
    );
    return response as List;
  }
}
