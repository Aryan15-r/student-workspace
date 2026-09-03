import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});
  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}
class _CommunityListPageState extends State<CommunityListPage> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CommunityProvider>().loadCommunities()); }
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(selectedIndex: 4, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Community', style: AppTextStyles.headlineSmall)),
      body: Consumer<CommunityProvider>(
        builder: (_, cp, __) {
          if (cp.isLoading) return const LoadingWidget(message: 'Loading communities...');
          if (cp.error != null) return AppErrorWidget(message: cp.error!, onRetry: cp.loadCommunities);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1),
            itemCount: cp.communities.length,
            itemBuilder: (_, i) => _CommunityCard(community: cp.communities[i])
                .animate().fadeIn(delay: Duration(milliseconds: i * 40)).scale(begin: const Offset(0.9, 0.9)),
          );
        },
      ),
    ));
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  const _CommunityCard({required this.community});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/community/${community.id}'),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(community.icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(community.name, style: AppTextStyles.titleMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(community.description, style: AppTextStyles.bodySmall, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ── Channel List ───────────────────────────────────────────────────────────────
class ChannelListPage extends StatefulWidget {
  final String communityId;
  const ChannelListPage({super.key, required this.communityId});
  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}
class _ChannelListPageState extends State<ChannelListPage> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CommunityProvider>().loadChannels(widget.communityId)); }
  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final community = cp.communities.where((c) => c.id == widget.communityId).firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/community')), title: Text(community?.name ?? 'Channels', style: AppTextStyles.headlineSmall)),
      body: cp.isLoading
          ? const LoadingWidget()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cp.channels.length,
              itemBuilder: (_, i) {
                final ch = cp.channels[i];
                return ListTile(
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('#', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700)))),
                  title: Text('#${ch.name}', style: AppTextStyles.titleMedium),
                  subtitle: ch.description.isNotEmpty ? Text(ch.description, style: AppTextStyles.bodySmall) : null,
                  onTap: () => context.go('/community/${widget.communityId}/channel/${ch.id}'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
              },
            ),
    );
  }
}

// ── Chat Page ──────────────────────────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final String channelId, communityId;
  const ChatPage({super.key, required this.channelId, required this.communityId});
  @override
  State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadMessages(widget.channelId);
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<CommunityProvider>().sendMessage(widget.channelId, text);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CommunityProvider>();
    final channel = cp.channels.where((c) => c.id == widget.channelId).firstOrNull;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/community/${widget.communityId}')),
        title: Text('#${channel?.name ?? 'chat'}', style: AppTextStyles.headlineSmall),
      ),
      body: Column(children: [
        Expanded(
          child: cp.isLoading && cp.messages.isEmpty
              ? const LoadingWidget()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: cp.messages.length,
                  itemBuilder: (_, i) => _MessageTile(message: cp.messages[i]),
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none, filled: false, hintStyle: TextStyle(color: AppColors.textMuted)), onSubmitted: (_) => _send())),
            GestureDetector(onTap: _send, child: Container(width: 40, height: 40, decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
          ]),
        ),
      ]),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final CommunityMessage message;
  const _MessageTile({required this.message});
  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = message.userId == currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.2), child: Text((message.username ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 12))),
            const SizedBox(width: 8),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Text(message.username ?? 'Unknown', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.primaryGradient : null,
                  color: isMe ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(16).copyWith(bottomRight: isMe ? const Radius.circular(4) : null, bottomLeft: isMe ? null : const Radius.circular(4)),
                  border: isMe ? null : Border.all(color: AppColors.border),
                ),
                child: Text(message.content, style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
              ),
            ],
          )),
        ],
      ),
    );
  }
}
