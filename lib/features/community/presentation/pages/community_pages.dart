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

// ── Room Lobby (Instant Public & Private Study Rooms) ─────────────────────────
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

  void _promptPasscodeAndJoin(Community room) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF334155))),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Text('Private Room: ${room.name}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This room is private. Please enter the passcode to join.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Passcode / Access Code',
                prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF818CF8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              final pass = passCtrl.text.trim();
              Navigator.pop(ctx);
              final cp = context.read<CommunityProvider>();
              final result = await cp.joinOrCreateRoom(
                roomName: room.name,
                inputPasscode: pass,
              );
              if (result != null && mounted) {
                context.go('/community/${result['communityId']}/channel/${result['channelId']}');
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cp.error ?? 'Incorrect passcode.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Enter Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    // Check if room exists and is private
    final existing = cp.communities.where((c) => c.name.toLowerCase() == code.toLowerCase()).firstOrNull;
    if (existing != null && existing.isPrivate) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (existing.createdBy != currentUserId) {
        _promptPasscodeAndJoin(existing);
        return;
      }
    }

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
    final passCtrl = TextEditingController();
    String selectedIcon = '💬';
    bool isPrivateRoom = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
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
                  const Text('Create Study Room', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Room Emoji Icon', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['💬', '🔒', '🚀', '📚', '⚡', '🧠', '💻'].map((emoji) {
                  final isSelected = selectedIcon == emoji;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedIcon = emoji),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.2) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF334155)),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'e.g. CS201 Study Group, Physics Lab',
                  prefixIcon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF818CF8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Topic / Description (Optional)',
                  hintText: 'What is this room about?',
                  prefixIcon: const Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              // Private Room Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 20),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Private Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Requires a passcode to join', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isPrivateRoom,
                      activeThumbColor: const Color(0xFF818CF8),
                      onChanged: (val) => setSheetState(() => isPrivateRoom = val),
                    ),
                  ],
                ),
              ),

              if (isPrivateRoom) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Room Passcode / Access Code',
                    hintText: 'Set a secret room passcode',
                    prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFFF59E0B)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final pass = passCtrl.text.trim();
                    if (name.isEmpty) return;
                    if (isPrivateRoom && pass.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a passcode for the private room')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    final cp = context.read<CommunityProvider>();
                    final res = await cp.joinOrCreateRoom(
                      roomName: name,
                      icon: isPrivateRoom ? '🔒' : selectedIcon,
                      description: descCtrl.text.trim(),
                      isPrivate: isPrivateRoom,
                      passcode: pass,
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
        backgroundColor: const Color(0xFF0B0F17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
          elevation: 0,
          title: Text('Study Rooms & Lounge', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF818CF8)),
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
                  if (auth.isGuest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF818CF8)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Community chat is locked in Guest Mode.',
                              style: TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => LoginPromptDialog.show(
                              context,
                              featureName: 'Community Study Rooms',
                              customMessage: 'Sign in to access community rooms, chat in real-time, and create custom study groups!',
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFF818CF8),
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quick Join Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('⚡', style: TextStyle(fontSize: 22)),
                            SizedBox(width: 8),
                            Text('Instant Room Access', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Join any room by code, or create a private group with password access.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roomCodeController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Enter room code (e.g. physics-lab)',
                                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18, color: Color(0xFF818CF8)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF334155)),
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
                                backgroundColor: const Color(0xFF6366F1),
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
                      const Text('Active Study Rooms', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: _showCreateRoomSheet,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF818CF8)),
                        label: const Text('New Room', style: TextStyle(color: Color(0xFF818CF8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (cp.isLoading && cp.communities.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: LoadingWidget(message: 'Loading active rooms...')))
                  else if (cp.error != null && cp.communities.isEmpty)
                    AppErrorWidget(message: cp.error!, onRetry: cp.loadCommunities)
                  else if (cp.communities.isEmpty)
                    const EmptyStateWidget(
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
                        childAspectRatio: 1.12,
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
                            if (room.isPrivate) {
                              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                              if (room.createdBy != currentUserId) {
                                _promptPasscodeAndJoin(room);
                                return;
                              }
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
          color: const Color(0xFF1E293B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: community.isPrivate
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(community.icon, style: const TextStyle(fontSize: 26)),
                if (community.isPrivate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFBBF24)),
                        SizedBox(width: 3),
                        Text('Private', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              community.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              community.description.isNotEmpty ? community.description : 'Open Discussion',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
        backgroundColor: const Color(0xFF0B0F17),
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/community'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFF818CF8)),
                const SizedBox(height: 16),
                const Text('Sign In Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Guest users cannot view or join channels.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13), textAlign: TextAlign.center),
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
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
        leading: BackButton(onPressed: () => context.go('/community')),
        title: Text(community?.name ?? 'Room Channels', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
      ),
      body: cp.isLoading
          ? const LoadingWidget()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cp.channels.length,
              itemBuilder: (_, i) {
                final ch = cp.channels[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('#', style: TextStyle(color: Color(0xFF818CF8), fontSize: 20, fontWeight: FontWeight.bold))),
                    ),
                    title: Text('#${ch.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: ch.description.isNotEmpty ? Text(ch.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)) : null,
                    onTap: () => context.go('/community/${widget.communityId}/channel/${ch.id}'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
              },
            ),
    );
  }
}

// ── Instant Chat Page with Admin/Author Message Deletion ───────────────────────
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

  void _confirmDeleteMessage(CommunityMessage message, bool isAdmin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF334155))),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(isAdmin ? 'Delete Message (Admin)' : 'Delete Message', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isAdmin
              ? 'As the room creator/admin, do you want to delete this message by "${message.username ?? 'Student'}"?'
              : 'Are you sure you want to delete your message?',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final cp = context.read<CommunityProvider>();
              final success = await cp.deleteMessage(message.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted 🗑️'), duration: Duration(seconds: 1)),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final community = cp.communities.where((c) => c.id == widget.communityId).firstOrNull;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isRoomAdmin = currentUserId != null && (community?.createdBy == currentUserId || channel?.createdBy == currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
        leading: BackButton(onPressed: () => context.go('/community/${widget.communityId}')),
        title: Row(
          children: [
            Text('#${channel?.name ?? 'chat'}', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
            if (isRoomAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Admin 👑', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: cp.isLoading && cp.messages.isEmpty
                ? const LoadingWidget(message: 'Connecting to room...')
                : cp.messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: Color(0xFF64748B))))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: cp.messages.length,
                        itemBuilder: (_, i) {
                          final msg = cp.messages[i];
                          final isAuthor = currentUserId == msg.userId;
                          final canDelete = isAuthor || isRoomAdmin;

                          return _MessageTile(
                            message: msg,
                            canDelete: canDelete,
                            isRoomAdmin: isRoomAdmin,
                            onDelete: () => _confirmDeleteMessage(msg, isRoomAdmin && !isAuthor),
                          );
                        },
                      ),
          ),
          // Input bar
          Container(
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
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
  final bool canDelete;
  final bool isRoomAdmin;
  final VoidCallback onDelete;

  const _MessageTile({
    required this.message,
    required this.canDelete,
    required this.isRoomAdmin,
    required this.onDelete,
  });

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
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
              child: Text(
                (message.username != null && message.username!.isNotEmpty ? message.username![0] : '?').toUpperCase(),
                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 2),
                GestureDetector(
                  onLongPress: canDelete ? onDelete : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
                          : null,
                      color: isMe ? null : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMe ? const Radius.circular(4) : null,
                        bottomLeft: isMe ? null : const Radius.circular(4),
                      ),
                      border: isMe ? null : Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message.content,
                            style: TextStyle(color: isMe ? Colors.white : const Color(0xFFF1F5F9), fontSize: 14),
                          ),
                        ),
                        if (canDelete) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: isMe ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
