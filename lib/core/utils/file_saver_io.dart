import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> saveFileImpl({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  Directory targetDir;

  if (Platform.isAndroid) {
    // Use the public external Downloads directory on Android.
    // getExternalStorageDirectories with type 'downloads' returns
    // /storage/emulated/0/Android/data/<pkg>/files/Download which is
    // app-scoped. Instead, use the well-known /storage/emulated/0/Download.
    final externalDirs = await getExternalStorageDirectories();
    if (externalDirs != null && externalDirs.isNotEmpty) {
      // externalDirs[0] is typically:
      //   /storage/emulated/0/Android/data/<pkg>/files
      // Navigate up to get /storage/emulated/0
      final rootExternal = externalDirs.first.path.split('Android').first;
      targetDir = Directory('${rootExternal}Download');
      if (!targetDir.existsSync()) {
        targetDir = await getApplicationDocumentsDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }
  } else if (Platform.isIOS) {
    // On iOS, save to the app documents directory (accessible via Files app)
    targetDir = await getApplicationDocumentsDirectory();
  } else {
    // Desktop (Windows, macOS, Linux) — save to user's Downloads folder
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null && downloadsDir.existsSync()) {
      targetDir = downloadsDir;
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }
  }

  final filePath = '${targetDir.path}${Platform.pathSeparator}$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);

  // Open the saved file so the user can see it immediately
  await OpenFilex.open(filePath, type: mimeType);
}
