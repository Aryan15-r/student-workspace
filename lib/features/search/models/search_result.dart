import 'package:flutter/material.dart';

/// Single search result item
class SearchResult {
  final String title;
  final String description;
  final String url;
  final String type; // video | article | course | documentation | tool | textbook | website
  final bool isFree;
  final String source;

  const SearchResult({
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    required this.isFree,
    required this.source,
  });

  factory SearchResult.fromMap(Map<String, dynamic> m) => SearchResult(
    title: m['title'] as String? ?? '',
    description: m['description'] as String? ?? '',
    url: m['url'] as String? ?? '',
    type: (m['type'] as String? ?? 'website').toLowerCase(),
    isFree: m['isFree'] as bool? ?? true,
    source: m['source'] as String? ?? 'Web',
  );

  static IconData iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'course':
        return Icons.school_outlined;
      case 'documentation':
        return Icons.description_outlined;
      case 'tool':
        return Icons.build_outlined;
      case 'textbook':
      case 'reference':
        return Icons.menu_book_rounded;
      default:
        return Icons.language_rounded;
    }
  }
}

/// Complete search engine payload with AI overview and related topics
class SearchData {
  final String overview;
  final List<SearchResult> results;
  final List<String> relatedQueries;

  const SearchData({
    required this.overview,
    required this.results,
    required this.relatedQueries,
  });

  factory SearchData.fromMap(Map<String, dynamic> m) {
    final rawResults = m['results'] as List? ?? [];
    final rawRelated = m['related'] as List? ?? [];

    return SearchData(
      overview: m['overview'] as String? ?? '',
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map((e) => SearchResult.fromMap(e))
          .toList(),
      relatedQueries: rawRelated.map((e) => e.toString()).toList(),
    );
  }
}
