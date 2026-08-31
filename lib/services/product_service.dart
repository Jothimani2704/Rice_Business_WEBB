import 'api_client.dart';

class ProductService {
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final data = await ApiClient.get('/products');

      return (data as List).map((p) {
        final currentStock = (p['currentStock'] as num?)?.toDouble() ?? 0.0;
        final minStock = (p['minimumStockLevel'] as num?)?.toDouble() ?? 0.0;
        final isActive = p['isActive'] as bool? ?? true;

        String status = 'In Stock';
        if (!isActive) {
          status = 'Inactive';
        } else if (currentStock <= 0) {
          status = 'Out of Stock';
        } else if (currentStock <= minStock) {
          status = 'Low Stock';
        }

        // Mocking an image for now based on the brand/name since DB doesn't have it yet
        String image =
            'assets/images/products/vellore_gold_25kg.jpg'; // default
        final name = (p['productName'] as String?)?.toLowerCase() ?? '';
        final brand = (p['brandName'] as String?)?.toLowerCase() ?? '';

        if (brand.contains('india gate') || name.contains('basmati')) {
          image = 'assets/images/products/india_gate_10kg.jpg';
        } else if (brand.contains('golden') || name.contains('sona')) {
          image = 'assets/images/products/golden_harvest_25kg.jpg';
        } else if (brand.contains('murugan') || name.contains('idli')) {
          image = 'assets/images/products/sri_murugan_10kg.jpg';
        }

        return {
          'id': p['id'],
          'name': p['productName'] ?? 'Unknown Product',
          'brand': p['brandName'] ?? 'Unknown Brand',
          'weight': '${p['bagSize'] ?? 0} kg', // e.g. 25 kg
          'bagSize': (p['bagSize'] as num?)?.toDouble() ?? 0.0,
          'purchasePrice': (p['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          'sellingPrice': (p['sellingPrice'] as num?)?.toDouble() ?? 0.0,
          'currentStock': currentStock,
          'status': status,
          'image': image,
          'isActive': isActive,
          'minimumStockLevel': minStock,
        };
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  static Future<void> createProduct(Map<String, dynamic> productData) async {
    try {
      await ApiClient.post('/products', body: productData);
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    try {
      await ApiClient.put('/products/$id', body: productData);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
}
