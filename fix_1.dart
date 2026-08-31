import 'dart:io';

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains(r'\1')) {
      content = content.replaceAll(
          r'gradient: \1(context).colorScheme.primary, Color(0xFFD4A373)],',
          r'gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFFD4A373)]),'
      );
      content = content.replaceAll(
          r'? \1(context).colorScheme.primary, Color(0xFFD4A373)])',
          r'? LinearGradient(colors: [Theme.of(context).colorScheme.primary, Color(0xFFD4A373)]) : null,'
      );
      content = content.replaceAll(
          r'decoration: \1(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),',
          r'style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),'
      );
      
      // Generic replace for all the \1(context).colorScheme... remaining
      // This will convert it into a Text('Label', style: TextStyle(...))
      content = content.replaceAllMapped(
          RegExp(r'\\1\(context\)\.(colorScheme\.[a-zA-Z0-9_]+),\s*([^)]*)\)\),'),
          (match) => "Text('Label', style: TextStyle(color: Theme.of(context).\${match.group(1)}, \${match.group(2)})),"
      );
      content = content.replaceAllMapped(
          RegExp(r'child:\s*\\1\(context\)\.(colorScheme\.[a-zA-Z0-9_]+),\s*([^)]*)\)\),'),
          (match) => "child: Text('Label', style: TextStyle(color: Theme.of(context).\${match.group(1)}, \${match.group(2)})),"
      );
      content = content.replaceAllMapped(
          RegExp(r'child:\s*\\1\(context\)\.(colorScheme\.[a-zA-Z0-9_]+),\s*([^)]*)\),'),
          (match) => "child: Text('Label', style: TextStyle(color: Theme.of(context).\${match.group(1)}, \${match.group(2)})),"
      );
      
      file.writeAsStringSync(content);
    }
  }
}
