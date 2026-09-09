import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/search_provider.dart';
import '../../models/search_result.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';
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

  void _search([String? query]) {
    final q = query ?? _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.text = q;
    context.read<SearchProvider>().search(q);
    FocusScope.of(context).unfocus();
  }

  Future<void> _openUrl(String urlString) async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        title: 'Login Required',
        message:
            'You need to log in to access this feature and view external web pages and study resources.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    if (urlString.isEmpty) return;
    final uri = Uri.tryParse(urlString);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $urlString'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('Smart Search', style: AppTextStyles.headlineSmall),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                _ctrl.clear();
                context.read<SearchProvider>().clear();
              },
              tooltip: 'Clear search',
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Search Input Box ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText:
                              'Search concepts, algorithms, physics, formulas...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                          ),
                          suffixIcon: _ctrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _ctrl.clear();
                                    context.read<SearchProvider>().clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onSubmitted: (val) => _search(val),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _search(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content Area ─────────────────────────────────────────
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, search, _) {
                  if (search.isLoading) {
                    return const LoadingWidget(
                      message: 'Searching academic sources with AI...',
                    );
                  }

                  if (search.searchData == null && search.lastQuery.isEmpty) {
                    return _DiscoveryHome(
                      history: search.history,
                      onSelect: (q) => _search(q),
                    );
                  }

                  if (search.results.isEmpty && search.overview.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.search_off_rounded,
                      title: 'No resources found',
                      subtitle:
                          'Try searching for specific concepts, theorems, or coding topics',
                      action: TextButton(
                        onPressed: () {
                          _ctrl.clear();
                          search.clear();
                        },
                        child: const Text('Clear Search'),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      // ── AI Overview Card ────────────────────────────────
                      if (search.overview.isNotEmpty) ...[
                        _AiOverviewCard(
                              query: search.lastQuery,
                              overview: search.overview,
                            )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 18),
                      ],

                      // ── Quick External Search Options ───────────────────
                      _ExternalEnginesBar(
                        query: search.lastQuery,
                        onOpen: _openUrl,
                      ),
                      const SizedBox(height: 18),

                      // ── Category Filter Pills ───────────────────────────
                      _CategoryFilterPills(
                        selectedCategory: search.selectedCategory,
                        onSelect: (cat) => search.setCategory(cat),
                      ),
                      const SizedBox(height: 14),

                      // ── Results Header ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text(
                          '${search.results.length} Educational Resources found for "${search.lastQuery}"',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Result Items ────────────────────────────────────
                      ...search.results.asMap().entries.map((entry) {
                        final i = entry.key;
                        final result = entry.value;
                        return _ResultCard(
                              result: result,
                              onTap: () => _openUrl(result.url),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 40))
                            .slideY(begin: 0.05, end: 0);
                      }),

                      // ── Related Questions / Subtopics ────────────────────
                      if (search.relatedQueries.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Related Topics & Concepts',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: search.relatedQueries
                              .map(
                                (rq) => ActionChip(
                                  avatar: const Icon(
                                    Icons.search_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    rq,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onPressed: () => _search(rq),
                                ),
                              )
                              .toList(),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ],
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

// ── AI Overview Widget ────────────────────────────────────────────────────────
class _AiOverviewCard extends StatelessWidget {
  final String query;
  final String overview;

  const _AiOverviewCard({required this.query, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI Academic Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Gemini 3.6',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            overview,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Search Engine Shortcuts ─────────────────────────────────────────────
class _ExternalEnginesBar extends StatelessWidget {
  final String query;
  final void Function(String) onOpen;

  const _ExternalEnginesBar({required this.query, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final clean = Uri.encodeComponent(query);
    final links = [
      {
        'label': 'Google',
        'icon': Icons.public_rounded,
        'url': 'https://www.google.com/search?q=$clean',
      },
      {
        'label': 'YouTube',
        'icon': Icons.play_circle_fill_rounded,
        'url': 'https://www.youtube.com/results?search_query=$clean',
      },
      {
        'label': 'Scholar',
        'icon': Icons.school_rounded,
        'url': 'https://scholar.google.com/scholar?q=$clean',
      },
      {
        'label': 'GitHub',
        'icon': Icons.code_rounded,
        'url': 'https://github.com/search?q=$clean',
      },
      {
        'label': 'Wikipedia',
        'icon': Icons.menu_book_rounded,
        'url': 'https://en.wikipedia.org/wiki/Special:Search?search=$clean',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: links.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => onOpen(item['url'] as String),
              icon: Icon(
                item['icon'] as IconData,
                size: 14,
                color: AppColors.textSecondary,
              ),
              label: Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Category Filters ──────────────────────────────────────────────────────────
class _CategoryFilterPills extends StatelessWidget {
  final String selectedCategory;
  final void Function(String) onSelect;

  const _CategoryFilterPills({
    required this.selectedCategory,
    required this.onSelect,
  });

  static const _categories = [
    {'id': 'all', 'label': 'All Sources'},
    {'id': 'article', 'label': 'Articles & Guides'},
    {'id': 'video', 'label': 'Video Lessons'},
    {'id': 'course', 'label': 'Courses & MIT'},
    {'id': 'documentation', 'label': 'Official Docs'},
    {'id': 'textbook', 'label': 'Textbooks & Ref'},
    {'id': 'tool', 'label': 'Calculators & Tools'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat['label']!),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onSelect(cat['id']!),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Search Result Card ────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _ResultCard({required this.result, required this.onTap});

  static const _typeColors = {
    'video': AppColors.error,
    'course': AppColors.secondary,
    'documentation': AppColors.accent,
    'tool': AppColors.warning,
    'textbook': AppColors.primary,
    'reference': AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[result.type] ?? AppColors.primary;
    final icon = SearchResult.iconForType(result.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top metadata row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.source,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (result.isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FREE',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: AppColors.textMuted,
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  result.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  result.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // URL preview
                Text(
                  result.url,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontSize: 11,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Discovery Home Widget (Empty Search State) ────────────────────────────────
class _DiscoveryHome extends StatelessWidget {
  final List<String> history;
  final void Function(String) onSelect;

  const _DiscoveryHome({required this.history, required this.onSelect});

  static const _trendingTopics = [
    'Newton\'s Laws of Motion',
    'Dijkstra\'s Shortest Path Algorithm',
    'Dynamic Programming Memoization',
    'Fourier Transform Intuition',
    'Organic Chemistry Reaction Mechanisms',
    'Binary Search Trees & Balancing',
    'Single Variable Calculus Integrals',
    'Async Await & Futures in Dart',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.explore_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Academic Search Engine',
                    style: AppTextStyles.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Instant conceptual summaries, verified tutorial links, textbook chapters, and video lectures powered by Gemini 3.6 AI.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
        const SizedBox(height: 24),

        // Recent Searches
        if (history.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text('Recent Searches', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: history
                .map(
                  (q) => ActionChip(
                    avatar: const Icon(
                      Icons.history,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    label: Text(
                      q,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => onSelect(q),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending Academic Topics
        Row(
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text('Trending Topics to Explore', style: AppTextStyles.labelLarge),
          ],
        ),
        const SizedBox(height: 12),
        ..._trendingTopics.map(
          (topic) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              title: Text(
                topic,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textMuted,
              ),
              onTap: () => onSelect(topic),
            ),
          ),
        ),
      ],
    );
  }
}
