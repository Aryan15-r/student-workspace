import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calculator_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /calculator  — works 100% offline
class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Calculator', style: AppTextStyles.headlineSmall)),
        body: Consumer<CalculatorProvider>(
          builder: (context, calc, _) => Column(
            children: [
              // Display
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(calc.expression, style: AppTextStyles.calcExpression, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(
                        calc.result,
                        style: AppTextStyles.calcDisplay.copyWith(
                          color: calc.result == 'Error' ? AppColors.error : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Buttons
              Expanded(
                flex: 5,
                child: _ButtonGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonGrid extends StatelessWidget {
  final _buttons = const [
    // Row 1: scientific
    ['sin(', 'cos(', 'tan(', 'log(', 'ln('],
    // Row 2
    ['sqrt(', '^', '(', ')', '%'],
    // Row 3
    ['AC', '⌫', 'π', 'e', '÷'],
    // Row 4
    ['7', '8', '9', '', '×'],
    // Row 5
    ['4', '5', '6', '', '-'],
    // Row 6
    ['1', '2', '3', '', '+'],
    // Row 7
    ['0', '.', '', '', '='],
  ];

  @override
  Widget build(BuildContext context) {
    // Flatten but use a 5-column grid
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _buttons.map((row) => Expanded(
          child: Row(
            children: row.asMap().entries.map((e) {
              final label = e.value;
              if (label.isEmpty) return const Expanded(child: SizedBox());
              // Check if this cell should span (= sign in last row)
              return Expanded(child: Padding(padding: const EdgeInsets.all(4), child: _CalcButton(label: label)));
            }).toList(),
          ),
        )).toList(),
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  const _CalcButton({required this.label});

  Color _bgColor() {
    if (label == '=')  return AppColors.primary;
    if (label == 'AC') return AppColors.error.withValues(alpha: 0.2);
    if (label == '⌫')  return AppColors.warning.withValues(alpha: 0.15);
    if (_isOp(label))  return AppColors.secondary.withValues(alpha: 0.15);
    if (_isSci(label)) return AppColors.accent.withValues(alpha: 0.1);
    return AppColors.surface;
  }

  Color _textColor() {
    if (label == '=')  return Colors.white;
    if (label == 'AC') return AppColors.error;
    if (label == '⌫')  return AppColors.warning;
    if (_isOp(label))  return AppColors.secondary;
    if (_isSci(label)) return AppColors.accent;
    return AppColors.textPrimary;
  }

  bool _isOp(String l)  => ['÷', '×', '-', '+', '^', '%', '(', ')'].contains(l);
  bool _isSci(String l) => ['sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt(', 'π', 'e'].contains(l);

  void _onTap(BuildContext context) {
    final calc = context.read<CalculatorProvider>();
    switch (label) {
      case '=':  calc.evaluate(); break;
      case 'AC': calc.clear();   break;
      case '⌫':  calc.backspace(); break;
      default:   calc.input(label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: label.length > 3 ? 13 : 18,
                  fontWeight: FontWeight.w500,
                  color: _textColor(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
