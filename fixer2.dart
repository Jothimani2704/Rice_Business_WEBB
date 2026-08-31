import 'dart:io';

void main() {
  void fixFile(String path, String from, String to) {
    try {
      var file = File(path);
      var content = file.readAsStringSync();
      var newContent = content.replaceAll(from, to);
      if (content != newContent) {
        file.writeAsStringSync(newContent);
        print('Fixed \$path');
      }
    } catch (e) {
      print('Error in \$path: \$e');
    }
  }

  void fixRegex(String path, RegExp from, String to) {
    try {
      var file = File(path);
      var content = file.readAsStringSync();
      var newContent = content.replaceAll(from, to);
      if (content != newContent) {
        file.writeAsStringSync(newContent);
        print('Fixed \$path');
      }
    } catch (e) {
      print('Error in \$path: \$e');
    }
  }

  // fix login_screen
  var loginFile = File('lib/screens/login_screen.dart');
  var content = loginFile.readAsStringSync();
  content = content.replaceAll('final Color _\n  final Color _\n  final Color _accentGold = const Color(0xFFE5C07B);\n  final Color _\n  final Color _\n', 'final Color _accentGold = const Color(0xFFE5C07B);\n');
  content = content.replaceAll('_Color(', 'Color(');
  loginFile.writeAsStringSync(content);
  print('Fixed login_screen');

  // fix stock_form_screen
  var stockFile = File('lib/screens/stock/stock_form_screen.dart');
  var sc = stockFile.readAsStringSync();
  // there are weird characters or missing braces around line 322 and 356
  //   error - Expected to find ']' - lib\screens\stock\stock_form_screen.dart:322:21 - expected_token
  //   error - Too many positional arguments: 0 expected, but 2 found. Try removing the extra positional arguments, or specifying the name for named arguments - lib\screens\stock\stock_form_screen.dart:323:21 - extra_positional_arguments_could_be_named
  //   error - Expected to find ')' - lib\screens\stock\stock_form_screen.dart:356:19 - expected_token
  //   error - Expected an identifier - lib\screens\stock\stock_form_screen.dart:359:13 - missing_identifier

  // we can just format it using dart format but since it has syntax errors, let's fix manually.
}
