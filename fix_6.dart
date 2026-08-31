import 'dart:io';

void main() {
  var file = File('lib/screens/payment/payment_form_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'Text(\'Label\', style: TextStyle(color: Theme.of(context).\${match.group(1)}, \${match.group(2)})),',
    'Text(\'Field\', style: TextStyle(color: Colors.white)),'
  );
  file.writeAsStringSync(content);
}
