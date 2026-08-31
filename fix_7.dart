import 'dart:io';

void main() {
  var file = File('lib/screens/product/product_form_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('Color Color(0xFFF7DE9B) = const Color(0xFFF3E5AB);', '');
  content = content.replaceAll('Color Color(0xFFA0B3A6) = Colors.white70;', '');
  file.writeAsStringSync(content);
}
