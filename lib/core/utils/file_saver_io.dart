import 'dart:io';

Future<void> saveFileImpl({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  // On Desktop/Android, try common download/temp paths
  Directory targetDir;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    targetDir = Directory('$home/Downloads');
    if (!targetDir.existsSync()) targetDir = Directory.current;
  } else {
    targetDir = Directory.systemTemp;
  }

  final file = File('${targetDir.path}/$fileName');
  await file.writeAsBytes(bytes);
}
