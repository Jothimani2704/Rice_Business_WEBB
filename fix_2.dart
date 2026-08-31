import 'dart:io';

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains('Color(')) {
      content = content.replaceAll(RegExp(r'Color\([^)]+\)\s*=\s*Color\([^)]+\);'), '');
      
      // Also the agent wrote `final Theme = Theme.of(context);` inside Widget build. Let's fix missing imports if needed, but this regex is for the broken assignment.
      file.writeAsStringSync(content);
    }
  }
}
