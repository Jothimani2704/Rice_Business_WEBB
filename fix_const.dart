import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  void processFile(File file) {
    if (file.path.contains('app_theme.dart') || file.path.contains('main_screen.dart')) return;
    
    var content = file.readAsStringSync();
    var original = content;

    content = content.replaceAll('const Theme.of', 'Theme.of');
    content = content.replaceAll('const TextStyle(color: Theme', 'TextStyle(color: Theme');
    content = content.replaceAll('const Icon(Icons.', 'Icon(Icons.');
    content = content.replaceAll('const BorderSide(color: Theme', 'BorderSide(color: Theme');
    content = content.replaceAll('const Divider(color: Theme', 'Divider(color: Theme');
    content = content.replaceAll('const CircularProgressIndicator(color: Theme', 'CircularProgressIndicator(color: Theme');

    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed const in \${file.path}');
    }
  }

  dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach(processFile);
}
