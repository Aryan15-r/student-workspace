import 'package:flutter/material.dart';

/// Search result model
class SearchResult {
  final String title;
  final String description;
  final String url;
  final String type;   // video | article | course | documentation | tool | website
  final bool   isFree;
  final String source;

  const SearchResult({required this.title, required this.description, required this.url, required this.type, required this.isFree, required this.source});

  factory SearchResult.fromMap(Map<String, dynamic> m) => SearchResult(
    title:       m['title']       as String? ?? '',
    description: m['description'] as String? ?? '',
    url:         m['url']         as String? ?? '',
    type:        m['type']        as String? ?? 'website',
    isFree:      m['isFree']      as bool?   ?? true,
    source:      m['source']      as String? ?? '',
  );

  static IconData iconForType(String type) {
    switch (type) {
      case 'video':         return Icons.play_circle_outline_rounded;
      case 'course':        return Icons.school_outlined;
      case 'documentation': return Icons.description_outlined;
      case 'tool':          return Icons.build_outlined;
      default:              return Icons.language_rounded;
    }
  }
}
