import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).forEach((file) {
    if (file.readAsStringSync().contains(r'\1')) {
      print(file.path);
      count++;
    }
  });
  print('Total files with backreference: \$count');
}
