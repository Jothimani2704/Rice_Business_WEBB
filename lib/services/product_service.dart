import 'api_client.dart';
import 'offline_sync_service.dart';

class ProductService {
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final data = await ApiClient.get('/products');

      final products = (data as List).map((p) {
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

        String image = 'assets/images/products/vellore_gold_25kg.jpg';
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
          'weight': '${p['bagSize'] ?? 0} kg',
          'bagSize': (p['bagSize'] as num?)?.toDouble() ?? 0.0,
          'purchasePrice': (p['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          'sellingPrice': (p['sellingPrice'] as num?)?.toDouble() ?? 0.0,
          'currentStock': currentStock,
          'status': status,
          'image': image,
          'imageUrl': p['imageUrl'],
          'isActive': isActive,
          'minimumStockLevel': minStock,
        };
      }).toList();

      await OfflineSyncService.cacheProducts(products);
      return products;
    } catch (e) {
      print('Error fetching products from server, attempting offline cache: $e');
      final cached = await OfflineSyncService.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  static Future<void> createProduct(
    Map<String, dynamic> productData, {
    List<int>? imageBytes,
    String? imageName,
  }) async {
    try {
      if (imageBytes != null && imageName != null) {
        final fields = <String, String>{};
        productData.forEach((key, value) {
          fields[key] = value.toString();
        });

        await ApiClient.multipartRequest(
          '/products',
          method: 'POST',
          fields: fields,
          fileBytes: imageBytes,
          filename: imageName,
        );
      } else {
        // Fallback for form data without image
        final fields = <String, String>{};
        productData.forEach((key, value) {
          fields[key] = value.toString();
        });
        await ApiClient.multipartRequest(
          '/products',
          method: 'POST',
          fields: fields,
        );
      }
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  static Future<void> updateProduct(
    int id,
    Map<String, dynamic> productData, {
    List<int>? imageBytes,
    String? imageName,
    bool removeImage = false,
  }) async {
    try {
      final fields = <String, String>{};
      productData.forEach((key, value) {
        fields[key] = value.toString();
      });
      fields['removeImage'] = removeImage.toString();

      await ApiClient.multipartRequest(
        '/products/$id',
        method: 'PUT',
        fields: fields,
        fileBytes: imageBytes,
        filename: imageName,
      );
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
}
