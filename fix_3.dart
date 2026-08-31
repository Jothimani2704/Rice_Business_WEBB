import 'dart:io';

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    var content = file.readAsStringSync();
    
    // Fix extra closing parenthesis introduced by LinearGradient and Text substitutions
    content = content.replaceAll('Color(0xFFD4A373)]),\n                            ),', 'Color(0xFFD4A373)]),\n');
    content = content.replaceAll('Color(0xFFD4A373)]),\n                          ),', 'Color(0xFFD4A373)]),\n');
    content = content.replaceAll('Color(0xFFD4A373)]),\n                        ),', 'Color(0xFFD4A373)]),\n');
    
    // Fix Text(Label) missing the rest of the file parenthesis
    // Let's just do a blanket regex for cases where there's an extra ), on its own line after gradient
    content = content.replaceAll(RegExp(r'gradient: LinearGradient\(colors: \[Theme\.of\(context\)\.colorScheme\.primary, Color\(0xFFD4A373\)\]\),\s*\),'), 'gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFFD4A373)]),\n');
    
    file.writeAsStringSync(content);
  }
}
