import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/chat_message.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /ai
class AiPage extends StatefulWidget {
  const AiPage({super.key});
  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _ctrl         = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _focusNode    = FocusNode();

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<AiProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 10),
            Text('AI Assistant', style: AppTextStyles.headlineSmall),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary), onPressed: () => context.read<AiProvider>().clearChat(), tooltip: 'Clear chat'),
          ],
        ),
        body: Consumer<AiProvider>(
          builder: (context, ai, _) {
            return Column(
              children: [
                Expanded(
                  child: ai.messages.isEmpty
                      ? _EmptyChat(onSuggest: (q) { _ctrl.text = q; _send(); })
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
                    child: Text(ai.error!, style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
                  ),
                _InputBar(ctrl: _ctrl, focusNode: _focusNode, isLoading: ai.isLoading, onSend: _send),
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
    'Explain recursion with an example',
    'What is Newton\'s second law?',
    'Help me create a study plan for exams',
    'Summarize the concept of OOP',
  ];
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 32)))).animate().fadeIn().scale(),
            const SizedBox(height: 20),
            Text('StudySpace AI', style: AppTextStyles.headlineMedium).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 8),
            Text('Ask me anything about your studies!', style: AppTextStyles.bodySmall, textAlign: TextAlign.center).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            Text('Try asking:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _suggestions.map((s) => GestureDetector(
                onTap: () => onSuggest(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                  child: Text(s, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              )).toList(),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14)))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat()).fadeIn(delay: Duration(milliseconds: i * 150)))),
          ),
        ]),
      );
    }
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppColors.primaryGradient : null,
          color: message.isUser ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : null,
            bottomLeft: message.isUser ? null : const Radius.circular(4),
          ),
          border: message.isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(message.content, style: TextStyle(color: message.isUser ? Colors.white : AppColors.textPrimary, fontSize: 14, height: 1.5)),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.focusNode, required this.isLoading, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Ask me anything...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                : GestureDetector(
                    onTap: onSend,
                    child: Container(width: 44, height: 44, decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
                  ),
          ),
        ],
      ),
    );
  }
}
