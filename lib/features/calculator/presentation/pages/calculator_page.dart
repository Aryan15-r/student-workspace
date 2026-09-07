import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/calculator_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /calculator — Ultra-Modern Offline Scientific Calculator
class CalculatorPage extends StatelessWidget {
  const CalculatorPage({super.key});

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final history = ctx.watch<CalculatorProvider>().history;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history_rounded, color: Color(0xFF818CF8), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Calculation History',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (history.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF87171)),
                        label: const Text('Clear', style: TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                        onPressed: () {
                          ctx.read<CalculatorProvider>().clearHistory();
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.calculate_outlined, color: Color(0xFF64748B), size: 36),
                        SizedBox(height: 8),
                        Text(
                          'No history yet',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Evaluated calculations will automatically appear here.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E293B), height: 1),
                      itemBuilder: (_, i) {
                        final item = history[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          title: Text(
                            item.expression,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                          subtitle: Text(
                            '= ${item.result}',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF818CF8)),
                            tooltip: 'Reuse Result',
                            onPressed: () {
                              ctx.read<CalculatorProvider>().loadFromHistory(item.result);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('🧮', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Text('Scientific Calculator', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_rounded, color: Color(0xFF818CF8)),
              tooltip: 'Calculation History',
              onPressed: () => _showHistorySheet(context),
            ),
          ],
        ),
        body: Consumer<CalculatorProvider>(
          builder: (context, calc, _) => SafeArea(
            child: Column(
              children: [
                // ── Display Screen ───────────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            calc.expression.isEmpty ? ' ' : calc.expression,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 18,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            calc.result,
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: calc.result == 'Error' ? const Color(0xFFF87171) : const Color(0xFFF8FAFC),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Button Grid ─────────────────────────────────────────────
                const Expanded(
                  flex: 7,
                  child: _ButtonGrid(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid();

  static const _buttons = [
    // Row 1: Trigonometry & Log
    ['sin(', 'cos(', 'tan(', 'log(', 'ln('],
    // Row 2: Powers & Roots
    ['sqrt(', '^', '(', ')', '%'],
    // Row 3: Controls & Basic Ops
    ['AC', '⌫', 'π', 'e', '÷'],
    // Row 4: Keypad Row 7-9
    ['7', '8', '9', '(', '×'],
    // Row 5: Keypad Row 4-6
    ['4', '5', '6', ')', '-'],
    // Row 6: Keypad Row 1-3
    ['1', '2', '3', '%', '+'],
    // Row 7: Keypad Row 0 & Equals
    ['0', '00', '.', '⌫', '='],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: _buttons.map((row) => Expanded(
          child: Row(
            children: row.map((label) => Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _CalcButton(label: label),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  const _CalcButton({required this.label});

  bool _isEquals(String l) => l == '=';
  bool _isClear(String l) => l == 'AC';
  bool _isBack(String l) => l == '⌫';
  bool _isOp(String l) => ['÷', '×', '-', '+', '^', '%', '(', ')'].contains(l);
  bool _isSci(String l) => ['sin(', 'cos(', 'tan(', 'log(', 'ln(', 'sqrt(', 'π', 'e'].contains(l);

  BoxDecoration _buttonDecoration(bool isLocked) {
    if (_isEquals(label)) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }

    if (_isClear(label)) {
      return BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      );
    }

    if (_isBack(label)) {
      return BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      );
    }

    if (_isOp(label)) {
      return BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
      );
    }

    if (_isSci(label)) {
      return BoxDecoration(
        color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
      );
    }

    // Standard Numbers (0-9, ., 00)
    return BoxDecoration(
      color: const Color(0xFF1E293B).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF334155)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Color _textColor(bool isLocked) {
    if (isLocked) return const Color(0xFF64748B);
    if (_isEquals(label)) return Colors.white;
    if (_isClear(label)) return const Color(0xFFF87171);
    if (_isBack(label)) return const Color(0xFFFBBF24);
    if (_isOp(label)) return const Color(0xFF818CF8);
    if (_isSci(label)) return const Color(0xFF38BDF8);
    return Colors.white;
  }

  void _onTap(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest && _isSci(label)) {
      LoginPromptDialog.show(
        context,
        title: 'Scientific Features Locked',
        message: 'Trigonometry, logarithms, and advanced constants require logging in. Sign in to unlock full scientific calculations!',
        icon: Icons.calculate_outlined,
      );
      return;
    }

    HapticFeedback.lightImpact();
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
    final isGuest = context.watch<AuthProvider>().isGuest;
    final isLocked = isGuest && _isSci(label);

    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: _buttonDecoration(isLocked),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: label.length > 3 ? 13 : 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor(isLocked),
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF64748B)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
