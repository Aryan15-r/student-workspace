import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class AiProvider extends ChangeNotifier {
  final _service = AiService();
  final List<ChatMessage> _messages = [];
  bool    _isLoading = false;
  String? _error;

  List<ChatMessage> get messages  => List.unmodifiable(_messages);
  bool              get isLoading => _isLoading;
  String?           get error     => _error;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messages.add(ChatMessage.user(text));
    _messages.add(ChatMessage.loading());
    _isLoading = true; _error = null; notifyListeners();

    try {
      // Pass history (excluding the loading bubble) to get context-aware response
      final history = _messages.where((m) => !m.isLoading).toList();
      final reply = await _service.sendMessage(history.sublist(0, history.length - 1), text);
      _messages.removeLast(); // remove loading bubble
      _messages.add(ChatMessage.ai(reply));
    } catch (e) {
      _messages.removeLast();
      _error = e.toString().replaceAll('AppException: ', '');
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void clearChat() { _messages.clear(); _error = null; notifyListeners(); }
}
