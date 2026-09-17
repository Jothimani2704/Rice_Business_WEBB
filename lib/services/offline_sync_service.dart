import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../utils/api_exception.dart';
import '../utils/app_toast.dart';
import '../utils/app_events.dart';

class OfflineSyncService {
  static const String _keyPendingSales = 'offline_pending_sales';
  static const String _keyCachedCustomers = 'offline_cached_customers';
  static const String _keyCachedProducts = 'offline_cached_products';

  static bool _isSyncing = false;

  /// Save a sale payload locally when network/server is unavailable
  static Future<Map<String, dynamic>> savePendingSale(Map<String, dynamic> saleData) async {
    final prefs = await SharedPreferences.getInstance();
    final String localId = 'OFFLINE-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';

    // Inject unique idempotency keys
    final Map<String, dynamic> payload = Map<String, dynamic>.from(saleData);
    payload['clientTransactionId'] = localId;
    payload['offlineSaleId'] = localId;

    final Map<String, dynamic> pendingEntry = {
      'localId': localId,
      'createdAt': DateTime.now().toIso8601String(),
      'saleData': payload,
      'status': 'Pending',
    };

    final List<Map<String, dynamic>> pendingList = await getPendingSales();
    pendingList.add(pendingEntry);

    await prefs.setString(_keyPendingSales, jsonEncode(pendingList));
    print('Offline sale saved locally with unique ID: $localId');

    return {
      'id': localId,
      'isOffline': true,
      'clientTransactionId': localId,
      'message': 'Saved offline. Will auto-sync when online.',
      ...payload,
    };
  }

  /// Retrieve all pending offline sales entries
  static Future<List<Map<String, dynamic>>> getPendingSales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyPendingSales);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      print('Error reading pending sales: $e');
      return [];
    }
  }

  /// Get count of pending sales awaiting sync
  static Future<int> getPendingSalesCount() async {
    final list = await getPendingSales();
    return list.where((e) => e['status'] != 'Failed').length;
  }

  /// Attempt to synchronize all pending offline sales to backend server
  static Future<int> syncPendingSales({BuildContext? context}) async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int syncedCount = 0;
    try {
      final pendingList = await getPendingSales();
      if (pendingList.isEmpty) {
        _isSyncing = false;
        return 0;
      }

      final List<Map<String, dynamic>> remainingList = [];

      for (final entry in pendingList) {
        if (entry['status'] == 'Failed') {
          // Skip already failed items (don't retry permanently unprocessable items)
          remainingList.add(entry);
          continue;
        }

        final String localId = entry['localId'] ?? '';
        final Map<String, dynamic> saleData = Map<String, dynamic>.from(entry['saleData'] ?? {});

        try {
          // Attempt to post sale to server API
          await ApiClient.post('/sales', body: saleData);
          syncedCount++;
          print('Successfully synced offline sale $localId to server');
        } catch (e) {
          if (e is ApiException && e.statusCode >= 400 && e.statusCode < 500) {
            // Validation / Business logic error (e.g. 400 Bad Request)
            print('Business validation error for offline sale $localId: $e');
            entry['status'] = 'Failed';
            entry['syncError'] = e.message;
            remainingList.add(entry);
          } else {
            // Temporary network or 503 server error -> Keep pending for retry
            print('Temporary network failure for offline sale $localId: $e');
            remainingList.add(entry);
          }
        }
      }

      // Update remaining pending list in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPendingSales, jsonEncode(remainingList));

      if (syncedCount > 0) {
        AppEvents.triggerRefresh();
        if (context != null && context.mounted) {
          AppToast.showSuccess(
            context,
            'Successfully synced $syncedCount offline bill(s) to cloud!',
          );
        }
      }
    } catch (e) {
      print('Error during offline sync process: $e');
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  /// Cache list of customers locally for offline bill dropdowns
  static Future<void> cacheCustomers(List<Map<String, dynamic>> customers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCachedCustomers, jsonEncode(customers));
    } catch (e) {
      print('Error caching customers: $e');
    }
  }

  /// Retrieve cached customers list for offline billing
  static Future<List<Map<String, dynamic>>> getCachedCustomers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyCachedCustomers);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      print('Error reading cached customers: $e');
      return [];
    }
  }

  /// Cache list of products locally for offline bill dropdowns
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCachedProducts, jsonEncode(products));
    } catch (e) {
      print('Error caching products: $e');
    }
  }

  /// Retrieve cached products list for offline billing
  static Future<List<Map<String, dynamic>>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyCachedProducts);
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(jsonStr);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      print('Error reading cached products: $e');
      return [];
    }
  }
}
