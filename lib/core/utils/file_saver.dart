import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

/// Cross-platform utility to trigger a file save / browser download
Future<void> saveAndDownloadFile({
  required String fileName,
  required List<int> bytes,
  String mimeType = 'application/pdf',
}) async {
  await saveFileImpl(fileName: fileName, bytes: bytes, mimeType: mimeType);
}
