import 'package:flutter/material.dart';

/// Lightweight, high-performance syntax highlighter for code snippets
class CodeSyntaxHighlighter {
  static const Color keywordColor = Color(0xFFFF7B72);    // Coral Pink
  static const Color typeColor = Color(0xFF79C0FF);       // Cyan / Sky Blue
  static const Color stringColor = Color(0xFF7EE787);     // Mint Green
  static const Color numberColor = Color(0xFFFFA657);     // Gold / Amber
  static const Color commentColor = Color(0xFF8B949E);    // Slate Gray (Italic)
  static const Color functionColor = Color(0xFFD2A8FF);   // Lavender
  static const Color operatorColor = Color(0xFFFF7B72);   // Coral
  static const Color defaultColor = Color(0xFFE6EDF3);    // Bright off-white

  static final Set<String> keywords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
    // Common Python, JavaScript, Java, C++, Go, Rust keywords
    'def', 'let', 'function', 'struct', 'pub', 'fn', 'mut', 'val', 'package',
    'public', 'private', 'protected', 'None', 'True', 'False', 'self', 'lambda',
    'elif', 'except', 'pass', 'raise', 'from', 'global', 'nonlocal', 'del',
    'select', 'defer', 'go', 'chan', 'impl', 'trait', 'match',
  };

  static final Set<String> builtInTypes = {
    'int', 'double', 'num', 'String', 'bool', 'List', 'Map', 'Set',
    'Future', 'Stream', 'DateTime', 'Duration', 'Comparable', 'Object',
    'Widget', 'BuildContext', 'State', 'StatefulWidget', 'StatelessWidget',
    'Key', 'Color', 'TextStyle', 'Container', 'Column', 'Row', 'Text',
    'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64',
    'float', 'char', 'long', 'short', 'byte', 'boolean', 'Array', 'Promise',
    'T', 'E', 'K', 'V', 'R', 'BinarySearch',
  };

  /// Parses raw code into styled TextSpans with syntax coloring
  static TextSpan format(String code) {
    final List<TextSpan> spans = [];
    final lines = code.split('\n');

    for (int l = 0; l < lines.length; l++) {
      final line = lines[l];
      _parseLine(line, spans);
      if (l < lines.length - 1) {
        spans.add(const TextSpan(
          text: '\n',
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
        ));
      }
    }

    return TextSpan(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.5,
        color: defaultColor,
      ),
      children: spans,
    );
  }

  static void _parseLine(String line, List<TextSpan> spans) {
    if (line.isEmpty) return;

    // Check for comment patterns (//, ///, #)
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('///') || trimmed.startsWith('//') || trimmed.startsWith('#')) {
      spans.add(TextSpan(
        text: line,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: commentColor,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ));
      return;
    }

    final commentIdx = line.indexOf('//');
    final hashCommentIdx = line.startsWith('#') ? 0 : -1;

    int activeCommentIdx = -1;
    if (commentIdx != -1) {
      activeCommentIdx = commentIdx;
    } else if (hashCommentIdx != -1) {
      activeCommentIdx = hashCommentIdx;
    }

    String codePart = line;
    String? commentPart;

    if (activeCommentIdx != -1) {
      codePart = line.substring(0, activeCommentIdx);
      commentPart = line.substring(activeCommentIdx);
    }

    // Tokenize codePart into strings, numbers, identifiers, and symbols
    final tokenRegex = RegExp(
      r'("(?:\\.|[^"\\])*"|'
      r"'(?:\\.|[^'\\])*'|"
      r'`(?:\\.|[^`\\])*`|'
      r'\b\d+(?:\.\d+)?\b|'
      r'\b[a-zA-Z_$][a-zA-Z0-9_$]*\b|'
      r'[^\s\w])',
    );

    int lastIndex = 0;
    for (final match in tokenRegex.allMatches(codePart)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: codePart.substring(lastIndex, match.start),
          style: const TextStyle(fontFamily: 'monospace', color: defaultColor, fontSize: 13),
        ));
      }

      final token = match.group(0)!;
      if (token.startsWith('"') || token.startsWith("'") || token.startsWith('`')) {
        // String literal
        spans.add(TextSpan(
          text: token,
          style: const TextStyle(fontFamily: 'monospace', color: stringColor, fontWeight: FontWeight.w500, fontSize: 13),
        ));
      } else if (RegExp(r'^\d+(\.\d+)?$').hasMatch(token)) {
        // Number literal
        spans.add(TextSpan(
          text: token,
          style: const TextStyle(fontFamily: 'monospace', color: numberColor, fontWeight: FontWeight.w500, fontSize: 13),
        ));
      } else if (keywords.contains(token)) {
        // Keyword
        spans.add(TextSpan(
          text: token,
          style: const TextStyle(fontFamily: 'monospace', color: keywordColor, fontWeight: FontWeight.bold, fontSize: 13),
        ));
      } else if (builtInTypes.contains(token) || (token.isNotEmpty && token[0] == token[0].toUpperCase() && token[0] != token[0].toLowerCase())) {
        // Type / Class name
        spans.add(TextSpan(
          text: token,
          style: const TextStyle(fontFamily: 'monospace', color: typeColor, fontWeight: FontWeight.w600, fontSize: 13),
        ));
      } else {
        // Function call detection (lookahead for '(')
        final afterMatch = codePart.substring(match.end).trimLeft();
        if (afterMatch.startsWith('(')) {
          spans.add(TextSpan(
            text: token,
            style: const TextStyle(fontFamily: 'monospace', color: functionColor, fontWeight: FontWeight.w500, fontSize: 13),
          ));
        } else {
          spans.add(TextSpan(
            text: token,
            style: const TextStyle(fontFamily: 'monospace', color: defaultColor, fontSize: 13),
          ));
        }
      }

      lastIndex = match.end;
    }

    if (lastIndex < codePart.length) {
      spans.add(TextSpan(
        text: codePart.substring(lastIndex),
        style: const TextStyle(fontFamily: 'monospace', color: defaultColor, fontSize: 13),
      ));
    }

    if (commentPart != null) {
      spans.add(TextSpan(
        text: commentPart,
        style: const TextStyle(
          fontFamily: 'monospace',
          color: commentColor,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      ));
    }
  }
}
