import 'dart:io';
import 'dart:convert';

void main() {
  final brainDir = Directory('C:\\Users\\Windows\\.gemini\\antigravity-ide\\brain');
  final targetFiles = [
    'customer_form_screen.dart',
    'customer_list_screen.dart',
    'payment_form_screen.dart',
    'payment_list_screen.dart',
    'product_list_screen.dart',
    'sale_detail_screen.dart',
    'sale_form_screen.dart',
    'sale_list_screen.dart',
    'stock_detail_screen.dart',
    'stock_form_screen.dart',
    'stock_list_screen.dart',
  ];

  Map<String, String> recoveredContents = {};

  if (!brainDir.existsSync()) {
    print('Brain dir not found');
    return;
  }

  for (var entry in brainDir.listSync()) {
    if (entry is Directory) {
      final logFile = File(entry.path + '\\.system_generated\\logs\\transcript_full.jsonl');
      if (logFile.existsSync()) {
        print('Checking ' + logFile.path + '...');
        final lines = logFile.readAsLinesSync();
        for (var line in lines) {
          try {
            final Map<String, dynamic> step = jsonDecode(line);
            if (step['tool_calls'] != null) {
              for (var toolCall in step['tool_calls']) {
                if (toolCall['name'] == 'default_api:write_to_file') {
                  final args = toolCall['arguments'];
                  if (args != null && args['TargetFile'] != null) {
                    final targetPath = args['TargetFile'] as String;
                    for (var target in targetFiles) {
                      if (targetPath.endsWith(target)) {
                        recoveredContents[target] = args['CodeContent'] as String;
                      }
                    }
                  }
                }
              }
            }
          } catch (e) {
            // ignore
          }
        }
      }
    }
  }

  print('Recovered ' + recoveredContents.length.toString() + ' files.');
  for (var target in targetFiles) {
    if (recoveredContents.containsKey(target)) {
      final content = recoveredContents[target]!;
      print('Recovered ' + target + ', size: ' + content.length.toString());
      
      // Write it back
      final searchPath = 'lib';
      final files = Directory(searchPath).listSync(recursive: true).whereType<File>();
      for (var f in files) {
        if (f.path.endsWith(target)) {
          f.writeAsStringSync(content);
          print('Wrote ' + target + ' to ' + f.path);
        }
      }
    } else {
      print('Could not recover ' + target);
    }
  }
}
