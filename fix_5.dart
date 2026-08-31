import 'dart:io';

void main() {
  var file = File('lib/screens/stock/stock_form_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'Text(\'Label\', style: TextStyle(color: Theme.of(context).\${match.group(1)}, \${match.group(2)})),',
    'Text(\'Cancel\', style: TextStyle(color: Color(0xFFF7DE9B), fontWeight: FontWeight.bold, fontSize: 16)),'
  );
  file.writeAsStringSync(content);
}
