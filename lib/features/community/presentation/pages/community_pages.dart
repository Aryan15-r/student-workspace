import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

// ── Room Lobby (ipchat.io style) ───────────────────────────────────────────────
class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});
  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage> {
  final _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadCommunities();
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _handleJoinOrCreateRoom([String? customCode]) async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        featureName: 'Community Study Rooms',
        customMessage: 'Guest users cannot enter community rooms. Please sign in to chat, collaborate, and share notes with classmates!',
      );
      return;
    }

    final code = (customCode ?? _roomCodeController.text).trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room name or code')),
      );
      return;
    }

    final cp = context.read<CommunityProvider>();
    final result = await cp.joinOrCreateRoom(roomName: code);
    if (result != null && mounted) {
      _roomCodeController.clear();
      context.go('/community/${result['communityId']}/channel/${result['channelId']}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cp.error ?? 'Could not join or create room.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCreateRoomSheet() {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        featureName: 'Community Study Rooms',
        customMessage: 'Please sign in to create your own study room!',
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedIcon = '💬';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Create Instant Room', style: AppTextStyles.headlineSmall),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Room Emoji Icon', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: ['💬', '🚀', '📚', '⚡', '🧠', '💻', '🎨'].map((emoji) {
                  final isSelected = selectedIcon == emoji;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedIcon = emoji),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Room Code or Name',
                  hintText: 'e.g. physics-revision, cs-group',
                  prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Topic / Description (Optional)',
                  hintText: 'What is this room about?',
                  prefixIcon: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    final cp = context.read<CommunityProvider>();
                    final res = await cp.joinOrCreateRoom(
                      roomName: name,
                      icon: selectedIcon,
                      description: descCtrl.text.trim(),
                    );
                    if (res != null && mounted) {
                      context.go('/community/${res['communityId']}/channel/${res['channelId']}');
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(cp.error ?? 'Could not create room.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Create & Enter Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      selectedIndex: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Study Rooms', style: AppTextStyles.headlineSmall),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              tooltip: 'Create Room',
              onPressed: _showCreateRoomSheet,
            ),
          ],
        ),
        body: Consumer<CommunityProvider>(
          builder: (_, cp, _) {
            return RefreshIndicator(
              onRefresh: cp.loadCommunities,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Guest lock banner
                  if (auth.isGuest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community chat is locked in Guest Mode.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => LoginPromptDialog.show(
                              context,
                              featureName: 'Community Study Rooms',
                              customMessage: 'Sign in to access community rooms, chat in real-time, and create custom study groups!',
                            ),
                            child: Text(
                              'Sign In',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ipchat.io Style Quick Room Join Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          AppColors.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text('Instant Room Access', style: AppTextStyles.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join any room by code, or create a private room in 1 second.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roomCodeController,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Enter room code (e.g. bio-lab)',
                                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18, color: AppColors.primary),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onSubmitted: (_) => _handleJoinOrCreateRoom(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: AppColors.primary,
                              ),
                              onPressed: () => _handleJoinOrCreateRoom(),
                              child: const Text('Join / Go', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Study Rooms', style: AppTextStyles.headlineSmall),
                      TextButton.icon(
                        onPressed: _showCreateRoomSheet,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Room'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (cp.isLoading && cp.communities.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: LoadingWidget(message: 'Loading active rooms...')))
                  else if (cp.error != null && cp.communities.isEmpty)
                    AppErrorWidget(message: cp.error!, onRetry: cp.loadCommunities)
                  else if (cp.communities.isEmpty)
                    EmptyStateWidget(
                      icon: Icons.forum_outlined,
                      title: 'No Active Rooms',
                      subtitle: 'Type a room code above to start the first study room!',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: cp.communities.length,
                      itemBuilder: (_, i) {
                        final room = cp.communities[i];
                        return _RoomCard(
                          community: room,
                          isGuest: auth.isGuest,
                          onTap: () {
                            if (auth.isGuest) {
                              LoginPromptDialog.show(
                                context,
                                featureName: 'Community Study Rooms',
                                customMessage: 'Guest users cannot access community study rooms. Please sign in to join discussions!',
                              );
                              return;
                            }
                            context.go('/community/${room.id}');
                          },
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 30)).scale(begin: const Offset(0.95, 0.95));
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Community community;
  final bool isGuest;
  final VoidCallback onTap;
  const _RoomCard({required this.community, required this.isGuest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(community.icon, style: const TextStyle(fontSize: 28)),
                if (isGuest)
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.warning)
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              community.name,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              community.description.isNotEmpty ? community.description : 'Open Discussion',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CommunityProvider>().loadChannels(widget.communityId));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/community'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('Sign In Required', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text('Guest users cannot view or join channels.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => LoginPromptDialog.show(context, featureName: 'Community Rooms'),
                  child: const Text('Sign In to Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cp = context.watch<CommunityProvider>();
    final community = cp.communities.where((c) => c.id == widget.communityId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/community')),
        title: Text(community?.name ?? 'Room Channels', style: AppTextStyles.headlineSmall),
      ),
      body: cp.isLoading
          ? const LoadingWidget()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cp.channels.length,
              itemBuilder: (_, i) {
                final ch = cp.channels[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(child: Text('#', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w700))),
                  ),
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

// ── Instant Chat Page (Zero Latency UI) ─────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final String channelId, communityId;
  const ChatPage({super.key, required this.channelId, required this.communityId});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadMessages(widget.channelId);
    });
  }

  void _send() {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        featureName: 'Community Chat',
        customMessage: 'Please sign in to send messages and chat with students!',
      );
      return;
    }

    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    context.read<CommunityProvider>().sendMessage(widget.channelId, text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          Expanded(
            child: cp.isLoading && cp.messages.isEmpty
                ? const LoadingWidget(message: 'Connecting to room...')
                : cp.messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: AppColors.textMuted)))
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
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Type an instant message...',
                      border: InputBorder.none,
                      filled: false,
                      hintStyle: TextStyle(color: AppColors.textMuted),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                (message.username != null && message.username!.isNotEmpty ? message.username![0] : '?').toUpperCase(),
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    message.username ?? 'Student',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(4) : null,
                      bottomLeft: isMe ? null : const Radius.circular(4),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

