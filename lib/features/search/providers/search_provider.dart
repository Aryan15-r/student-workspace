import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/search_result.dart';
import '../../ai_assistant/services/ai_service.dart';

class SearchProvider extends ChangeNotifier {
  final _ai = AiService();
  SearchData? _searchData;
  List<String> _history = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';
  String _selectedCategory = 'all';
  Timer? _debounce;

  SearchData? get searchData => _searchData;
  List<SearchResult> get results {
    if (_searchData == null) return [];
    if (_selectedCategory == 'all') return _searchData!.results;
    return _searchData!.results
        .where((r) => r.type.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  String get overview => _searchData?.overview ?? '';
  List<String> get relatedQueries => _searchData?.relatedQueries ?? [];
  List<String> get history => _history;
  bool get isLoading => _loading;
  String? get error => _error;
  String get lastQuery => _lastQuery;
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _lastQuery = clean;
    _loading = true;
    _error = null;
    _selectedCategory = 'all';
    notifyListeners();

    try {
      final raw = await _ai.searchAcademicEngine(clean);
      _searchData = SearchData.fromMap(raw);
      unawaited(_saveHistory(clean));
    } catch (e) {
      _error = 'Could not fetch search results. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void searchWhenSettled(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => search(query));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _saveHistory(String query) async {
    if (!_history.contains(query)) _history.insert(0, query);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client.from('search_history').insert({
          'user_id': userId,
          'query': query,
        });
      }
    } catch (_) {}
  }

  void clear() {
    _searchData = null;
    _lastQuery = '';
    _selectedCategory = 'all';
    notifyListeners();
  }
}
