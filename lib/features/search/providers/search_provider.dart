import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result.dart';
import '../../ai_assistant/services/ai_service.dart';

class SearchProvider extends ChangeNotifier {
  final _ai = AiService();
  List<SearchResult> _results   = [];
  List<String>       _history   = [];
  bool               _loading   = false;
  String?            _error;
  String             _lastQuery = '';

  List<SearchResult> get results   => _results;
  List<String>       get history   => _history;
  bool               get isLoading => _loading;
  String?            get error     => _error;
  String             get lastQuery => _lastQuery;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    _lastQuery = query.trim();
    _loading = true; _error = null; notifyListeners();
    try {
      final raw = await _ai.searchResources(query);
      _results = raw.map((m) => SearchResult.fromMap(m)).toList();
      await _saveHistory(query.trim());
    } catch (e) {
      _error = 'Could not fetch results. Check your Gemini API key.';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> _saveHistory(String query) async {
    if (!_history.contains(query)) _history.insert(0, query);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('search_history').insert({'user_id': userId, 'query': query});
      }
    } catch (_) {}
  }

  void clear() { _results = []; _lastQuery = ''; notifyListeners(); }
}
