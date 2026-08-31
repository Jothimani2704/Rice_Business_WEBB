import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  final reps = {
    'const Color(0xFF0A2314)': 'Theme.of(context).primaryColor',
    'Color(0xFF0A2314)': 'Theme.of(context).primaryColor',
    'const Color(0xFF1E4226)': 'Theme.of(context).colorScheme.surface',
    'Color(0xFF1E4226)': 'Theme.of(context).colorScheme.surface',
    'const Color(0xFFF7DE9B)': 'Theme.of(context).colorScheme.primary',
    'Color(0xFFF7DE9B)': 'Theme.of(context).colorScheme.primary',
    'const Color(0xFFA0B3A6)': 'Theme.of(context).colorScheme.outline',
    'Color(0xFFA0B3A6)': 'Theme.of(context).colorScheme.outline',
    'const Color(0xFFD4A373)': 'Theme.of(context).colorScheme.secondary',
    'Color(0xFFD4A373)': 'Theme.of(context).colorScheme.secondary',
    
    // Local variables used in forms
    ' primaryDark': ' Theme.of(context).primaryColor',
    ' primaryLight': ' Theme.of(context).colorScheme.surface',
    ' accentGoldLight': ' Theme.of(context).colorScheme.primary',
    ' textSecondary': ' Theme.of(context).colorScheme.outline',
    '(primaryDark': '(Theme.of(context).primaryColor',
    '(primaryLight': '(Theme.of(context).colorScheme.surface',
    '(accentGoldLight': '(Theme.of(context).colorScheme.primary',
    '(textSecondary': '(Theme.of(context).colorScheme.outline',
  };

  void processFile(File file) {
    if (file.path.contains('app_theme.dart') || file.path.contains('main_screen.dart')) return;
    
    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll(RegExp(r'^\s*final\s+\w+\s*=\s*const\s*Color\(0xFF[0-9A-Fa-f]+\);\s*\n?', multiLine: true), '');
    content = content.replaceAll(RegExp(r'^\s*static\s+const\s+\w+\s*=\s*Color\(0xFF[0-9A-Fa-f]+\);\s*\n?', multiLine: true), '');

    for (var entry in reps.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    
    if (content != original) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }

  dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach(processFile);
}
