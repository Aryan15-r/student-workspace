import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/ai_provider.dart';
import '../../models/chat_message.dart';
import '../widgets/code_syntax_highlighter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /ai
class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      if (!auth.incrementGuestAiQuery()) {
        LoginPromptDialog.show(
          context,
          title: 'Guest AI Limit Reached',
          message: 'You have used all 3 free guest questions. Sign in or create a free account to get unlimited AI tutor access!',
          icon: Icons.auto_awesome_rounded,
        );
        return;
      }
    }

    _ctrl.clear();
    context.read<AiProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 2,
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
                  child: Text('🤖', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Text('StudySpace AI', style: AppTextStyles.headlineSmall),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
              onPressed: () => context.read<AiProvider>().clearChat(),
              tooltip: 'Clear chat',
            ),
          ],
        ),
        body: Consumer<AiProvider>(
          builder: (context, ai, _) {
            return Column(
              children: [
                Expanded(
                  child: ai.messages.isEmpty
                      ? _EmptyChat(
                          onSuggest: (q) {
                            _ctrl.text = q;
                            _send();
                          },
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          itemCount: ai.messages.length,
                          itemBuilder: (_, i) => _MessageBubble(message: ai.messages[i]),
                        ),
                ),
                if (ai.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      ai.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (context.watch<AuthProvider>().isGuest)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Guest Mode: ${context.watch<AuthProvider>().guestAiQueries} of 3 free questions used • ',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                        InkWell(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Sign In for Unlimited',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                _InputBar(
                  ctrl: _ctrl,
                  focusNode: _focusNode,
                  isLoading: ai.isLoading,
                  onSend: _send,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onSuggest;
  const _EmptyChat({required this.onSuggest});

  static const _suggestions = [
    'Explain Newton\'s third law with everyday examples',
    'Explain recursion in Python with step-by-step logic',
    'Write a complete Binary Search implementation in Dart',
    'How does Fourier Transform work intuitively?',
    'Help me create a 2-week active recall exam study plan',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 32))),
            ).animate().fadeIn().scale(),
            const SizedBox(height: 20),
            Text('StudySpace AI Mentor', style: AppTextStyles.headlineMedium).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text(
              'Powered by Gemini 3.6 • Rich Markdown • Syntax Code Highlighting',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Text('Try asking:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => onSuggest(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              )).toList(),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  Future<void> _launchLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard! 📋'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).fadeIn(delay: Duration(milliseconds: i * 150)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppColors.primaryGradient : null,
          color: message.isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: message.isUser ? null : const Radius.circular(4),
          ),
          border: message.isUser ? null : Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isUser)
              Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
              )
            else ...[
              MarkdownBody(
                data: message.content,
                onTapLink: (text, href, title) => _launchLink(href),
                builders: {
                  'code': _CodeBlockCustomBuilder(onCopy: (code) => _copyToClipboard(context, code)),
                  'pre': _CodeBlockCustomBuilder(onCopy: (code) => _copyToClipboard(context, code)),
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.6),
                  h1: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  h2: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  h3: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  h4: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  code: const TextStyle(
                    backgroundColor: Color(0xFF1E2433),
                    color: Color(0xFF38BDF8),
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  blockquote: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  blockquoteDecoration: BoxDecoration(
                    border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                  blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  listBullet: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  em: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  a: const TextStyle(color: Color(0xFF38BDF8), decoration: TextDecoration.underline),
                  tableBody: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  tableBorder: TableBorder.all(color: AppColors.border, width: 1),
                  tablePadding: const EdgeInsets.all(8),
                  blockSpacing: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                    onPressed: () => _copyToClipboard(context, message.content),
                    tooltip: 'Copy response',
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Custom code block element builder that adds a header, language badge, and copy button
class _CodeBlockCustomBuilder extends MarkdownElementBuilder {
  final void Function(String) onCopy;
  _CodeBlockCustomBuilder({required this.onCopy});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawText = element.textContent;

    // Distinguish between block code vs inline code
    final isBlock = rawText.contains('\n') || (element.attributes['class'] != null);

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Text(
          rawText,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF38BDF8),
            fontSize: 12.5,
          ),
        ),
      );
    }

    final classAttr = element.attributes['class'] ?? '';
    final language = classAttr.replaceFirst('language-', '').trim();
    final displayLanguage = language.isNotEmpty ? language.toUpperCase() : 'CODE';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Language and Copy Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 14, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      displayLanguage,
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => onCopy(rawText),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 12, color: Color(0xFF8B949E)),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(color: Color(0xFF8B949E), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Text with Syntax Highlighting and Horizontal Scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText.rich(
              CodeSyntaxHighlighter.format(rawText),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.ctrl,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask a question or request code / formulas...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
