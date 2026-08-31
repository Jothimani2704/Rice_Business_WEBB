import 'dart:io';

void main() {
  final historyDir = Directory('C:\\\\Users\\\\Windows\\\\AppData\\\\Roaming\\\\Code\\\\User\\\\History');
  
  final targets = {
    'class CustomerFormScreen': 'customer_form_screen.dart',
    'class CustomerListScreen': 'customer_list_screen.dart',
    'class PaymentFormScreen': 'payment_form_screen.dart',
    'class PaymentListScreen': 'payment_list_screen.dart',
    'class ProductListScreen': 'product_list_screen.dart',
    'class SaleDetailScreen': 'sale_detail_screen.dart',
    'class SaleFormScreen': 'sale_form_screen.dart',
    'class SaleListScreen': 'sale_list_screen.dart',
    'class StockDetailScreen': 'stock_detail_screen.dart',
    'class StockFormScreen': 'stock_form_screen.dart',
    'class StockListScreen': 'stock_list_screen.dart',
  };

  Map<String, String> recoveredFiles = {};
  Map<String, DateTime> lastModified = {};

  if (!historyDir.existsSync()) {
    print('VS Code history not found');
    return;
  }

  final files = historyDir.listSync(recursive: true).whereType<File>();
  for (var file in files) {
    if (file.path.endsWith('.json')) continue; // entries.json etc
    
    try {
      final content = file.readAsStringSync();
      // Skip the ones that were corrupted by the script today
      if (content.contains(r'\1')) continue;
      if (content.contains('final Theme = Theme.of(context);')) continue;
      if (content.contains('AppColors.Theme.of(context)')) continue;
      if (content.contains('Theme.of(context).colorScheme.surface = Theme.of(context).colorScheme.surface;')) continue;
      
      for (var entry in targets.entries) {
        final marker = entry.key;
        final targetName = entry.value;
        
        if (content.contains(marker) && content.contains('StatefulWidget')) {
           // We found a version of the file!
           // We want the most recent uncorrupted version.
           final stat = file.statSync();
           if (!lastModified.containsKey(targetName) || stat.modified.isAfter(lastModified[targetName]!)) {
             recoveredFiles[targetName] = content;
             lastModified[targetName] = stat.modified;
           }
        }
      }
    } catch (e) {
      // ignore read errors
    }
  }

  print('Recovered ' + recoveredFiles.length.toString() + ' files from VS Code history');
  
  final libDir = Directory('lib');
  for (var targetName in recoveredFiles.keys) {
     final content = recoveredFiles[targetName]!;
     final f = libDir.listSync(recursive: true).whereType<File>().firstWhere((element) => element.path.endsWith(targetName));
     f.writeAsStringSync(content);
     print('Restored ' + targetName + ' to ' + f.path);
  }
}
