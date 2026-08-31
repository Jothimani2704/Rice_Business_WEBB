import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  void processFile(File file) {
    if (file.path.contains('main_screen.dart')) return;
    
    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll(RegExp(r'const\s+([a-zA-Z0-9_]+\([^)]*Theme\.of)'), r'\1');
    content = content.replaceAll(RegExp(r'const\s+(Theme\.of)'), r'\1');
    
    content = content.replaceAll('AppColors.Theme.of(context).colorScheme.surface', 'AppColors.darkPrimaryLight');
    content = content.replaceAll('AppColors.Theme.of(context).primaryColor', 'Color(0xFF0A2314)');
    content = content.replaceAll('cardTheme: CardTheme(', 'cardTheme: CardThemeData(');
    content = content.replaceAll('Theme.of(context).primaryColor', 'Color(0xFF0A2314)'); // Reverting
    content = content.replaceAll('Theme.of(context).colorScheme.surface', 'Color(0xFF1E4226)');
    content = content.replaceAll('Theme.of(context).colorScheme.primary', 'Color(0xFFF7DE9B)');
    content = content.replaceAll('Theme.of(context).colorScheme.outline', 'Color(0xFFA0B3A6)');
    content = content.replaceAll('Theme.of(context).colorScheme.secondary', 'Color(0xFFD4A373)');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed const in \${file.path}');
    }
  }

  dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach(processFile);
}
