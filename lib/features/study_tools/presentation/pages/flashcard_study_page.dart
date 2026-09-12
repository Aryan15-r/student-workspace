import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../../app/theme/app_colors.dart';
import '../../providers/flashcard_provider.dart';
import '../../models/flashcard.dart';

class FlashcardStudyPage extends StatefulWidget {
  final String deckId;
  const FlashcardStudyPage({super.key, required this.deckId});

  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  void _nextCard(int total) {
    if (_currentIndex < total - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      // Done
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have completed this deck!')),
      );
      context.pop();
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final deck = provider.decks.firstWhere((d) => d.id == widget.deckId, orElse: () => FlashcardDeck(title: 'Not Found', cards: []));

    if (deck.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(deck.title)),
        body: const Center(child: Text('This deck is empty.')),
      );
    }

    final card = deck.cards[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${deck.title} (${_currentIndex + 1}/${deck.cards.length})'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / deck.cards.length,
              backgroundColor: AppColors.card,
              color: AppColors.primary,
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFlipped = !_isFlipped;
                    });
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
                      return AnimatedBuilder(
                        animation: rotate,
                        child: child,
                        builder: (context, child) {
                          final angle = (ValueKey(_isFlipped) == child?.key) ? rotate.value : math.pi - rotate.value;
                          return Transform(
                            transform: Matrix4.rotationY(angle),
                            alignment: Alignment.center,
                            child: angle >= math.pi / 2
                                ? const SizedBox.shrink()
                                : child,
                          );
                        },
                      );
                    },
                    child: Card(
                      key: ValueKey(_isFlipped),
                      margin: const EdgeInsets.all(32),
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Container(
                        width: double.infinity,
                        height: 400,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _isFlipped ? AppColors.surface : AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isFlipped ? 'BACK' : 'FRONT',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isFlipped ? card.back : card.front,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevCard,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: _currentIndex > 0 ? AppColors.primary : AppColors.textMuted,
                  ),
                  const Text('Tap card to flip', style: TextStyle(color: AppColors.textSecondary)),
                  IconButton(
                    onPressed: () => _nextCard(deck.cards.length),
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
