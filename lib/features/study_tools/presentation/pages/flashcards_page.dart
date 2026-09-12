import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../providers/flashcard_provider.dart';

class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  final TextEditingController _topicController = TextEditingController();

  void _showCreateDialog(BuildContext context) {
    double cardCount = 10;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate AI Flashcards'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic (e.g., Photosynthesis)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cards:'),
                  Text('${cardCount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: cardCount,
                min: 5,
                max: 30,
                divisions: 25,
                label: cardCount.toInt().toString(),
                onChanged: (val) => setDialogState(() => cardCount = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final topic = _topicController.text.trim();
                if (topic.isNotEmpty) {
                  Navigator.pop(ctx);
                  final provider = context.read<FlashcardProvider>();
                  final success = await provider.generateDeckFromTopic(topic, count: cardCount.toInt());
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to generate flashcards.')),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardProvider>();
    final decks = provider.decks;

    return AdaptiveScaffold(
      selectedIndex: 7,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/study-tools'),
          ),
          title: const Text('Flashcards'),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : decks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No Flashcard Decks Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showCreateDialog(context),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate AI Deck'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(deck.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${deck.cards.length} cards'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                                onPressed: () {
                                  context.push('/flashcards/study/${deck.id}');
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => provider.deleteDeck(deck.id),
                              ),
                            ],
                          ),
                          onTap: () => context.push('/flashcards/study/${deck.id}'),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('AI Deck'),
        ),
      ),
    );
  }
}
