import 'package:flutter/foundation.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorProvider extends ChangeNotifier {
  String _expression = ''; // What user has typed
  String _result     = '0'; // Displayed result
  bool   _justEvaled = false;

  String get expression => _expression;
  String get result     => _result;

  void input(String val) {
    if (_justEvaled && RegExp(r'[0-9π]').hasMatch(val)) {
      _expression = ''; // Start fresh after eval
    }
    _justEvaled = false;
    _expression += val;
    _evaluate();
    notifyListeners();
  }

  void clear()    { _expression = ''; _result = '0'; _justEvaled = false; notifyListeners(); }
  void backspace() {
    if (_expression.isNotEmpty) {
      // Handle multi-char tokens like 'sin(', 'cos(', etc.
      final multiChar = ['sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt('];
      for (final t in multiChar) {
        if (_expression.endsWith(t)) { _expression = _expression.substring(0, _expression.length - t.length); _evaluate(); notifyListeners(); return; }
      }
      _expression = _expression.substring(0, _expression.length - 1);
      _evaluate();
      notifyListeners();
    }
  }

  void evaluate() {
    _evaluate(commit: true);
    if (_result != 'Error') {
      _expression = _result;
      _justEvaled = true;
    }
    notifyListeners();
  }

  void _evaluate({bool commit = false}) {
    if (_expression.isEmpty) { _result = '0'; return; }
    try {
      String expr = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265358979')
          .replaceAll('e', '2.71828182845905')
          .replaceAll('sqrt(', 'sqrt(')
          .replaceAll('%', '/100');

      final parser  = Parser();
      final exp     = parser.parse(expr);
      final context = ContextModel();
      final val     = exp.evaluate(EvaluationType.REAL, context) as double;

      if (val.isNaN || val.isInfinite) { _result = 'Error'; return; }
      // Show as int if whole number
      _result = val == val.truncateToDouble() ? val.toInt().toString() : _trim(val.toString());
    } catch (_) {
      _result = commit ? 'Error' : _expression.isNotEmpty ? '...' : '0';
    }
  }

  String _trim(String s) {
    // Trim trailing zeros: 3.50000 → 3.5
    if (s.contains('.')) { s = s.replaceAll(RegExp(r'0+$'), ''); s = s.replaceAll(RegExp(r'\.$'), ''); }
    return s;
  }
}
