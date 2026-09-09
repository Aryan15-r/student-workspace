import 'package:flutter/foundation.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorHistoryItem {
  final String expression;
  final String result;
  final DateTime timestamp;
  CalculatorHistoryItem({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}

class CalculatorProvider extends ChangeNotifier {
  String _expression = ''; // What user has typed
  String _result = '0'; // Displayed result
  bool _justEvaled = false;
  final List<CalculatorHistoryItem> _history = [];

  String get expression => _expression;
  String get result => _result;
  List<CalculatorHistoryItem> get history => List.unmodifiable(_history);

  void input(String val) {
    if (_justEvaled && RegExp(r'[0-9π]').hasMatch(val)) {
      _expression = ''; // Start fresh after eval
    }
    _justEvaled = false;
    _expression += val;
    _evaluate();
    notifyListeners();
  }

  void clear() {
    _expression = '';
    _result = '0';
    _justEvaled = false;
    notifyListeners();
  }

  void backspace() {
    if (_expression.isNotEmpty) {
      // Handle multi-char tokens like 'sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt('
      final multiChar = ['sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt('];
      for (final t in multiChar) {
        if (_expression.endsWith(t)) {
          _expression = _expression.substring(0, _expression.length - t.length);
          _evaluate();
          notifyListeners();
          return;
        }
      }
      _expression = _expression.substring(0, _expression.length - 1);
      _evaluate();
      notifyListeners();
    }
  }

  void evaluate() {
    _evaluate(commit: true);
    if (_result != 'Error' && _expression.isNotEmpty) {
      _history.insert(
        0,
        CalculatorHistoryItem(
          expression: _expression,
          result: _result,
          timestamp: DateTime.now(),
        ),
      );
      _expression = _result;
      _justEvaled = true;
    }
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void loadFromHistory(String val) {
    _expression = val;
    _justEvaled = false;
    _evaluate();
    notifyListeners();
  }

  void _evaluate({bool commit = false}) {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    try {
      String expr = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265358979')
          .replaceAll('e', '2.71828182845905')
          .replaceAll('%', '/100');

      // Fix leading decimals: e.g. ".25" -> "0.25", "+.5" -> "+0.5", "(.2" -> "(0.2"
      expr = expr.replaceAllMapped(
        RegExp(r'(^|[^0-9])\.([0-9])'),
        (m) => '${m[1]}0.${m[2]}',
      );

      final parser = GrammarParser();
      final exp = parser.parse(expr);
      final context = ContextModel();
      final val = exp.evaluate(EvaluationType.REAL, context) as double;

      if (val.isNaN || val.isInfinite) {
        _result = 'Error';
        return;
      }

      // Format as int if whole number
      _result = val == val.truncateToDouble()
          ? val.toInt().toString()
          : _trim(val.toString());
    } catch (_) {
      _result = commit ? 'Error' : (_expression.isNotEmpty ? '...' : '0');
    }
  }

  String _trim(String s) {
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
