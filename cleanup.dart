import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  void processFile(File file) {
    if (file.path.contains('app_theme.dart') || file.path.contains('main_screen.dart')) return;
    
    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll(RegExp(r'^\s*final\s+Theme\.of\(context\).*=.*;\s*\n?', multiLine: true), '');
    content = content.replaceAll(RegExp(r'^\s*static\s+const\s+Theme\.of\(context\).*=.*;\s*\n?', multiLine: true), '');

    content = content.replaceAll('primaryDark', 'Theme.of(context).primaryColor');
    content = content.replaceAll('primaryLight', 'Theme.of(context).colorScheme.surface');
    content = content.replaceAll('accentGoldLight', 'Theme.of(context).colorScheme.primary');
    content = content.replaceAll('textSecondary', 'Theme.of(context).colorScheme.outline');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Cleaned \${file.path}');
    }
  }

  dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach(processFile);
}
