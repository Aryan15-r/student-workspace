import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/search_provider.dart';
import '../../models/search_result.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /search
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    context.read<SearchProvider>().search(q);
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Smart Search', style: AppTextStyles.headlineSmall)),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search study resources...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textMuted), onPressed: () { _ctrl.clear(); context.read<SearchProvider>().clear(); })
                          : null,
                    ),
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _search, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)), child: const Text('Search')),
              ]),
            ),

            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, search, _) {
                  if (search.isLoading) return const LoadingWidget(message: 'Finding resources...');

                  if (search.results.isEmpty && search.lastQuery.isEmpty) {
                    return _HistoryPanel(history: search.history, onTap: (q) { _ctrl.text = q; _search(); });
                  }

                  if (search.results.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      subtitle: 'Try a different search term',
                      action: TextButton(onPressed: () { _ctrl.clear(); context.read<SearchProvider>().clear(); }, child: const Text('Clear')),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: search.results.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('${search.results.length} resources for "${search.lastQuery}"', style: AppTextStyles.bodySmall),
                      );
                      return _ResultCard(result: search.results[i - 1])
                          .animate().fadeIn(delay: Duration(milliseconds: (i - 1) * 60)).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<String> history;
  final void Function(String) onTap;
  const _HistoryPanel({required this.history, required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyStateWidget(icon: Icons.search_rounded, title: 'Search for anything', subtitle: 'Find free educational resources, videos, articles, and courses');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Recent searches', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        ...history.map((q) => ListTile(
          leading: const Icon(Icons.history_rounded, color: AppColors.textMuted),
          title: Text(q, style: AppTextStyles.bodyMedium),
          onTap: () => onTap(q),
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  const _ResultCard({required this.result});
  static const _typeColors = {'video': AppColors.error, 'course': AppColors.secondary, 'documentation': AppColors.accent, 'tool': AppColors.warning};
  static const _typeIcons  = {'video': Icons.play_circle_outline_rounded, 'course': Icons.school_outlined, 'documentation': Icons.description_outlined, 'tool': Icons.build_outlined};
  @override
  Widget build(BuildContext context) {
    final color = _typeColors[result.type] ?? AppColors.primary;
    final icon  = _typeIcons[result.type]  ?? Icons.language_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open: ${result.url}'), behavior: SnackBarBehavior.floating),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(result.title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (result.isFree) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Text('Free', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 4),
              Text(result.description, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(result.source, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 16),
          ]),
        ),
      ),
    );
  }
}
