import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/errors/app_exception.dart';

enum PdfJobStatus { idle, picking, uploading, processing, done, error }

class PdfProvider extends ChangeNotifier {
  PdfJobStatus _status  = PdfJobStatus.idle;
  String?      _error;
  String?      _fileName;
  String?      _result; // extracted text result

  PdfJobStatus get status   => _status;
  String?      get error    => _error;
  String?      get fileName => _fileName;
  String?      get result   => _result;

  Future<void> pickAndProcess() async {
    _status = PdfJobStatus.picking; notifyListeners();
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (res == null || res.files.isEmpty) { _status = PdfJobStatus.idle; notifyListeners(); return; }

      _fileName = res.files.first.name;
      _status   = PdfJobStatus.uploading; notifyListeners();

      // Simulate processing for hackathon demo
      await Future.delayed(const Duration(seconds: 2));
      _status = PdfJobStatus.processing; notifyListeners();
      await Future.delayed(const Duration(seconds: 2));

      _result = 'PDF content extracted successfully!\n\n[In production, this would send the PDF to a Supabase Edge Function, extract text using a PDF library, and return the content here.]\n\nFile: $_fileName';
      _status = PdfJobStatus.done; notifyListeners();
    } catch (e) {
      _error  = AppException.fileError().message;
      _status = PdfJobStatus.error; notifyListeners();
    }
  }

  void reset() { _status = PdfJobStatus.idle; _error = null; _fileName = null; _result = null; notifyListeners(); }
}
