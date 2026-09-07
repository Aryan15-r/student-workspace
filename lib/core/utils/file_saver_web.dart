// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> saveFileImpl({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final safeFileName = fileName.replaceAll(RegExp(r'[/\\]'), '_').replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', safeFileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
