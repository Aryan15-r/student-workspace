import 'dart:ui';
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

/// Route: /ai — StudySpace AI Assistant Page with ultra-modern UI & Copy Prompt capabilities
class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  void _send([String? customPrompt]) {
    final text = (customPrompt ?? _ctrl.text).trim();
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

    if (customPrompt == null) {
      _ctrl.clear();
    }
    context.read<AiProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
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
        backgroundColor: const Color(0xFF0B0F17), // Premium dark theme background
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AppBar(
                elevation: 0,
                backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.75),
                title: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🤖', style: TextStyle(fontSize: 20)),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.96, end: 1.04, duration: 1800.ms),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'StudySpace AI',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                children: [
                                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF22C55E)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Gemini 3.6',
                                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Zero-Downtime Academic Assistant',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      context.read<AiProvider>().clearChat();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat history cleared'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    tooltip: 'Clear Chat',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Ambient glowing background nodes
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 4000.ms),
            ),
            Positioned(
              bottom: 120,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA855F7).withValues(alpha: 0.10),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), duration: 5000.ms),
            ),

            // Main chat content
            SafeArea(
              child: Consumer<AiProvider>(
                builder: (context, ai, _) {
                  return Column(
                    children: [
                      Expanded(
                        child: ai.messages.isEmpty
                            ? _EmptyChatState(
                                onSuggest: (q) {
                                  _ctrl.text = q;
                                  _send(q);
                                },
                              )
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: ai.messages.length,
                                itemBuilder: (_, i) => _MessageBubble(
                                  message: ai.messages[i],
                                  onReusePrompt: (p) {
                                    _ctrl.text = p;
                                    _focusNode.requestFocus();
                                  },
                                ),
                              ),
                      ),

                      if (ai.error != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFF87171)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ai.error!,
                                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (context.watch<AuthProvider>().isGuest)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars_rounded, size: 15, color: Color(0xFF818CF8)),
                              const SizedBox(width: 6),
                              Text(
                                'Guest Mode: ${context.watch<AuthProvider>().guestAiQueries} of 3 questions used • ',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                              InkWell(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Sign In for Unlimited',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      _InputBar(
                        ctrl: _ctrl,
                        focusNode: _focusNode,
                        isLoading: ai.isLoading,
                        onSend: () => _send(),
                      ),
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

class _EmptyChatState extends StatelessWidget {
  final void Function(String) onSuggest;
  const _EmptyChatState({required this.onSuggest});

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 38))),
            ).animate().fadeIn().scale(duration: 400.ms),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFFC084FC), Color(0xFFF472B6)],
              ).createShader(bounds),
              child: const Text(
                'StudySpace AI Tutor',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Text(
                '⚡ Powered by Gemini 3.6 • Zero-Downtime Cascade • Copy Prompt Ready',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Suggested Topics:',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => onSuggest(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFF818CF8)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s,
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.3),
                        ),
                      ),
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
  final void Function(String) onReusePrompt;

  const _MessageBubble({
    required this.message,
    required this.onReusePrompt,
  });

  Future<void> _launchLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard! 📋'),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Text('Thinking...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  const SizedBox(width: 10),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF818CF8),
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat()).fadeIn(delay: Duration(milliseconds: i * 180)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: isUser ? null : const Radius.circular(4),
          ),
          border: Border.all(
            color: isUser ? const Color(0xFF818CF8).withValues(alpha: 0.5) : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bubble Header Bar (User or AI)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFF0F172A).withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(19),
                  topRight: Radius.circular(19),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                        size: 14,
                        color: isUser ? Colors.white70 : const Color(0xFF818CF8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUser ? 'You' : 'StudySpace AI',
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Prompt Action Buttons (Copy Prompt / Reuse Prompt)
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _copyToClipboard(context, message.content, isUser ? 'Prompt' : 'Response'),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUser ? 'Copy Prompt' : 'Copy Response',
                                style: TextStyle(
                                  color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => onReusePrompt(message.content),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            child: Row(
                              children: [
                                Icon(Icons.edit_note_rounded, size: 13, color: Colors.white70),
                                SizedBox(width: 2),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Message Content Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: isUser
                  ? SelectableText(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
                    )
                  : MarkdownBody(
                      data: message.content,
                      onTapLink: (text, href, title) => _launchLink(href),
                      builders: {
                        'code': _CodeBlockCustomBuilder(onCopy: (code) => _copyToClipboard(context, code, 'Code')),
                        'pre': _CodeBlockCustomBuilder(onCopy: (code) => _copyToClipboard(context, code, 'Code')),
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14.5, height: 1.6),
                        h1: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        h2: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        h3: AppTextStyles.titleMedium.copyWith(color: const Color(0xFF818CF8), fontWeight: FontWeight.bold),
                        h4: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 14, fontWeight: FontWeight.w600),
                        code: const TextStyle(
                          backgroundColor: Color(0xFF0F172A),
                          color: Color(0xFF38BDF8),
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        blockquote: const TextStyle(color: Color(0xFFCBD5E1), fontStyle: FontStyle.italic),
                        blockquoteDecoration: BoxDecoration(
                          border: const Border(left: BorderSide(color: Color(0xFF818CF8), width: 3)),
                          color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        ),
                        blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        listBullet: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold),
                        strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        em: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
                        a: const TextStyle(color: Color(0xFF38BDF8), decoration: TextDecoration.underline),
                        tableBody: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 13),
                        tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        tableBorder: TableBorder.all(color: const Color(0xFF334155), width: 1),
                        tablePadding: const EdgeInsets.all(8),
                        blockSpacing: 10,
                      ),
                    ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.06, end: 0);
  }
}

/// Code snippet element builder with syntax highlighting and copy button
class _CodeBlockCustomBuilder extends MarkdownElementBuilder {
  final void Function(String) onCopy;
  _CodeBlockCustomBuilder({required this.onCopy});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final rawText = element.textContent;

    final isBlock = rawText.contains('\n') || (element.attributes['class'] != null);

    if (!isBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
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
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF334155))),
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
                        color: Color(0xFF94A3B8),
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
                        Icon(Icons.copy_rounded, size: 12, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text(
                          'Copy Code',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: focusNode.hasFocus ? const Color(0xFF818CF8) : const Color(0xFF334155),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: const InputDecoration(
                        hintText: 'Ask a study question or paste code/math...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        filled: false,
                      ),
                    ),
                  ),
                  if (ctrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => ctrl.clear(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF818CF8)),
                    ),
                  )
                : GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
