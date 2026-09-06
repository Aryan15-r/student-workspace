Future<void> saveFileImpl({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Platform not supported for saving files');
}
