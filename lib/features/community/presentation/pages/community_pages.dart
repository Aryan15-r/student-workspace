import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _selectedTab = 0; // 0 = Public Lounge, 1 = Private Rooms

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
        backgroundColor: const Color(0xFFFFFCF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8D4C4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Private Room: ${room.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This room is private. Please enter the passcode to join.',
              style: TextStyle(color: Color(0xFF806A63), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Passcode / Access Code',
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  color: Color(0xFFD66A50),
                ),
                filled: true,
                fillColor: const Color(0xFFF7EBDD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A5F),
            ),
            onPressed: () async {
              final pass = passCtrl.text.trim();
              Navigator.pop(ctx);
              final cp = context.read<CommunityProvider>();
              final result = await cp.joinRoomByCode(
                roomCode: room.name,
                inputPasscode: pass,
              );
              if (result != null && mounted) {
                context.go(
                  '/community/${result['communityId']}/channel/${result['channelId']}',
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cp.error ?? 'Incorrect passcode.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text(
              'Enter Room',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoinRoom() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      LoginPromptDialog.show(
        context,
        featureName: 'Community Study Rooms',
        customMessage:
            'Guest users cannot enter community rooms. Please sign in to chat, collaborate, and share notes with classmates!',
      );
      return;
    }

    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room code or name.')),
      );
      return;
    }

    final cp = context.read<CommunityProvider>();
    final result = await cp.joinRoomByCode(roomCode: code);
    if (result != null && mounted) {
      _roomCodeController.clear();
      context.go(
        '/community/${result['communityId']}/channel/${result['channelId']}',
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cp.error ?? 'Could not join room.'),
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
      backgroundColor: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Study Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF806A63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Room Emoji Icon',
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['💬', '🔒', '🚀', '📚', '⚡', '🧠', '💻'].map((
                  emoji,
                ) {
                  final isSelected = selectedIcon == emoji;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedIcon = emoji),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE07A5F).withValues(alpha: 0.2)
                            : const Color(0xFFF7EBDD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFD66A50)
                              : const Color(0xFFE8D4C4),
                        ),
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
                  labelText: 'Room Name / Code',
                  hintText: 'e.g. CS201-Study, Physics-Lab',
                  prefixIcon: const Icon(
                    Icons.meeting_room_rounded,
                    color: Color(0xFFD66A50),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7EBDD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Topic / Description (Optional)',
                  hintText: 'What is this room about?',
                  prefixIcon: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF806A63),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7EBDD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Private Room Switch
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EBDD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8D4C4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private Room',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Requires passcode to enter',
                              style: TextStyle(
                                color: Color(0xFF806A63),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isPrivateRoom,
                      activeThumbColor: const Color(0xFFD66A50),
                      onChanged: (val) =>
                          setSheetState(() => isPrivateRoom = val),
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
                    labelText: 'Set Room Passcode',
                    hintText: 'Set a secret room passcode',
                    prefixIcon: const Icon(
                      Icons.key_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7EBDD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: const Color(0xFFE07A5F),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final pass = passCtrl.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(ctx);
                    final cp = context.read<CommunityProvider>();
                    final res = await cp.createNewRoom(
                      roomName: name,
                      icon: selectedIcon,
                      description: descCtrl.text,
                      isPrivate: isPrivateRoom,
                      passcode: pass,
                    );
                    if (res != null && mounted) {
                      context.go(
                        '/community/${res['communityId']}/channel/${res['channelId']}',
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(cp.error ?? 'Could not create room'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Create Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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
      selectedIndex: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFCF8).withValues(alpha: 0.8),
          title: Text(
            'Student Lounge & Study Rooms',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFFD66A50),
              ),
              onPressed: _showCreateRoomSheet,
              tooltip: 'New Room',
            ),
          ],
        ),
        body: Consumer<CommunityProvider>(
          builder: (context, cp, _) {
            final publicRooms = cp.communities
                .where((c) => !c.isPrivate)
                .toList();
            final privateRooms = cp.communities
                .where((c) => c.isPrivate)
                .toList();
            final displayRooms = _selectedTab == 0 ? publicRooms : privateRooms;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (auth.isGuest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07A5F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE07A5F).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD66A50),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Viewing as Guest. Sign in to chat in study rooms and create custom private groups.',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => LoginPromptDialog.show(
                              context,
                              featureName: 'Study Rooms',
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Color(0xFFD66A50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quick Join Room Code Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF8F4F3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD66A50).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE07A5F).withValues(alpha: 0.2),
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
                            Text(
                              'Join Room by Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter an existing room code to join instantly.',
                          style: TextStyle(
                            color: Color(0xFF806A63),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roomCodeController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter room code (e.g. physics-lab)',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.meeting_room_outlined,
                                    size: 18,
                                    color: Color(0xFFD66A50),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFFFFCF8),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE8D4C4),
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _handleJoinRoom(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFFE07A5F),
                              ),
                              onPressed: _handleJoinRoom,
                              child: const Text(
                                'Join Room',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Segmented Tabs: Public Lounge vs Private Rooms
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EBDD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8D4C4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? const Color(0xFFE07A5F)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.public_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Public Lounge (${publicRooms.length})',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 0
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? const Color(0xFFE07A5F)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    size: 16,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Private Rooms (${privateRooms.length})',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: _selectedTab == 1
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTab == 0
                            ? 'Public Study Lounges'
                            : 'Private Passcode Rooms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7EBDD),
                          side: const BorderSide(color: Color(0xFFE8D4C4)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showCreateRoomSheet,
                        icon: const Icon(
                          Icons.add,
                          size: 15,
                          color: Color(0xFFD66A50),
                        ),
                        label: const Text(
                          'New Room',
                          style: TextStyle(
                            color: Color(0xFFD66A50),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (cp.isLoading && cp.communities.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: LoadingWidget(
                          message: 'Loading active rooms...',
                        ),
                      ),
                    )
                  else if (cp.error != null && cp.communities.isEmpty)
                    AppErrorWidget(
                      message: cp.error!,
                      onRetry: cp.loadCommunities,
                    )
                  else if (displayRooms.isEmpty)
                    EmptyStateWidget(
                      icon: _selectedTab == 0
                          ? Icons.forum_outlined
                          : Icons.lock_outline_rounded,
                      title: _selectedTab == 0
                          ? 'No Public Rooms'
                          : 'No Private Rooms Yet',
                      subtitle: _selectedTab == 0
                          ? 'Click "New Room" to create the first study room!'
                          : 'Create a private passcode-protected room for your study group.',
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                      itemCount: displayRooms.length,
                      itemBuilder: (_, i) {
                        final room = displayRooms[i];
                        return _RoomCard(
                              community: room,
                              isGuest: auth.isGuest,
                              onTap: () {
                                if (auth.isGuest) {
                                  LoginPromptDialog.show(
                                    context,
                                    featureName: 'Community Study Rooms',
                                    customMessage:
                                        'Guest users cannot access community study rooms. Please sign in to join discussions!',
                                  );
                                  return;
                                }
                                if (room.isPrivate) {
                                  final currentUserId = Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser
                                      ?.id;
                                  if (room.createdBy != currentUserId) {
                                    _promptPasscodeAndJoin(room);
                                    return;
                                  }
                                }
                                context.go('/community/${room.id}');
                              },
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 30))
                            .scale(begin: const Offset(0.95, 0.95));
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
  const _RoomCard({
    required this.community,
    required this.isGuest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: community.isPrivate
                ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                : const Color(0xFFE8D4C4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(community.icon, style: const TextStyle(fontSize: 24)),
                if (community.isPrivate)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Private',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  community.description.isNotEmpty
                      ? community.description
                      : 'Open Discussion',
                  style: const TextStyle(
                    color: Color(0xFF806A63),
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CommunityProvider>().loadChannels(widget.communityId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isGuest) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/community')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Color(0xFFD66A50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign In Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guest users cannot view or join channels.',
                  style: TextStyle(color: Color(0xFF806A63), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => LoginPromptDialog.show(
                    context,
                    featureName: 'Community Rooms',
                  ),
                  child: const Text('Sign In to Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cp = context.watch<CommunityProvider>();
    final community = cp.communities
        .where((c) => c.id == widget.communityId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8).withValues(alpha: 0.8),
        leading: BackButton(onPressed: () => context.go('/community')),
        title: Text(
          community?.name ?? 'Room Channels',
          style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
        ),
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
                    color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8D4C4)),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07A5F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Color(0xFFD66A50),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      '#${ch.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: ch.description.isNotEmpty
                        ? Text(
                            ch.description,
                            style: const TextStyle(
                              color: Color(0xFF806A63),
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () => context.go(
                      '/community/${widget.communityId}/channel/${ch.id}',
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
              },
            ),
    );
  }
}

// ── Instant Chat Page with Discord Profile & Instagram Message Menu ─────────────
class ChatPage extends StatefulWidget {
  final String channelId, communityId;
  const ChatPage({
    super.key,
    required this.channelId,
    required this.communityId,
  });
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
        customMessage:
            'Please sign in to send messages and chat with students!',
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

  /// Long-Press Instagram-Style Message Action Sheet
  void _showInstagramMessageMenu(
    CommunityMessage message,
    bool canDelete,
    bool isRoomAdmin,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D4C4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Emoji Reaction Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EBDD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8D4C4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '👍', '🔥', '😮', '😂', '🙏'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reacted with $emoji'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Message Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EBDD).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.username ?? 'Student',
                    style: const TextStyle(
                      color: Color(0xFFD66A50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copy Action
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8)),
              title: const Text(
                'Copy Message Text',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard! 📋'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            // Delete Action (Only for message author or room admin)
            if (canDelete)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: Text(
                  isRoomAdmin &&
                          message.userId !=
                              Supabase.instance.client.auth.currentUser?.id
                      ? 'Delete Message (Admin)'
                      : 'Delete Message',
                  style: const TextStyle(
                    color: Color(0xFFF87171),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final cp = context.read<CommunityProvider>();
                  final success = await cp.deleteMessage(message.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted 🗑️'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Discord-Style Channel Profile & Member Moderation Drawer
  void _showDiscordChannelProfile(
    Channel? channel,
    Community? community,
    bool isRoomAdmin,
  ) {
    final cp = context.read<CommunityProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D4C4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Channel Banner Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        community?.icon ?? '💬',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              community?.name ?? 'Room Profile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (community?.isPrivate == true)
                              const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: Color(0xFFFBBF24),
                              ),
                          ],
                        ),
                        Text(
                          'Channel #${channel?.name ?? 'general'}',
                          style: const TextStyle(
                            color: Color(0xFF806A63),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Member Count & List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Channel Members',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EBDD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${cp.channelMembers.length} Members',
                      style: const TextStyle(
                        color: Color(0xFFD66A50),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Member List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: cp.channelMembers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No other members in room yet.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: cp.channelMembers.length,
                        itemBuilder: (_, i) {
                          final member = cp.channelMembers[i];
                          final isAdmin =
                              member.role == 'admin' ||
                              member.userId == community?.createdBy;
                          final currentUserId =
                              Supabase.instance.client.auth.currentUser?.id;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(
                                0xFFE07A5F,
                              ).withValues(alpha: 0.2),
                              child: Text(
                                (member.username?.isNotEmpty == true
                                        ? member.username![0]
                                        : 'U')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFD66A50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  member.username ?? 'Student',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Admin 👑',
                                      style: TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing:
                                (isRoomAdmin && member.userId != currentUserId)
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.person_remove_rounded,
                                      color: Color(0xFFF87171),
                                      size: 18,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFFFFFCF8,
                                          ),
                                          title: const Text(
                                            'Kick Member',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: Text(
                                            'Kick ${member.username ?? 'user'} from channel?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFFEF4444,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: const Text('Kick'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await cp.kickMember(
                                          widget.channelId,
                                          member.userId,
                                        );
                                        setSheetState(() {});
                                      }
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE8D4C4)),
              const SizedBox(height: 10),

              // Actions (Leave Channel or Delete Chat & Room)
              if (isRoomAdmin && community != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Delete Room & All Chats (Admin)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: const Color(0xFFFFFCF8),
                          title: const Text(
                            'Delete Entire Room?',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'This will delete the channel, messages, and room for all users permanently.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete Room'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        final deleted = await cp.deleteRoomAndCommunity(
                          community.id,
                        );
                        if (deleted && mounted) {
                          context.go('/community');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Room deleted 🗑️')),
                          );
                        }
                      }
                    },
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFF87171),
                    ),
                    label: const Text(
                      'Leave Channel',
                      style: TextStyle(
                        color: Color(0xFFF87171),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await cp.leaveChannel(widget.channelId);
                      if (mounted) context.go('/community');
                    },
                  ),
                ),
            ],
          ),
        ),
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
    final channel = cp.channels
        .where((c) => c.id == widget.channelId)
        .firstOrNull;
    final community = cp.communities
        .where((c) => c.id == widget.communityId)
        .firstOrNull;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isRoomAdmin =
        currentUserId != null &&
        (community?.createdBy == currentUserId ||
            channel?.createdBy == currentUserId);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8).withValues(alpha: 0.8),
        leading: BackButton(
          onPressed: () => context.go('/community/${widget.communityId}'),
        ),
        title: GestureDetector(
          onTap: () =>
              _showDiscordChannelProfile(channel, community, isRoomAdmin),
          child: Row(
            children: [
              Text(
                '#${channel?.name ?? 'chat'}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFFD66A50),
              ),
              if (isRoomAdmin) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Admin 👑',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.people_alt_rounded,
              color: Color(0xFFD66A50),
            ),
            onPressed: () =>
                _showDiscordChannelProfile(channel, community, isRoomAdmin),
            tooltip: 'Channel Profile & Members',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cp.isLoading && cp.messages.isEmpty
                ? const LoadingWidget(message: 'Connecting to room...')
                : cp.messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Say hi! 👋',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
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
                        onLongPress: () => _showInstagramMessageMenu(
                          msg,
                          canDelete,
                          isRoomAdmin,
                        ),
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF8),
              border: Border(top: BorderSide(color: Color(0xFFF7EBDD))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EBDD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8D4C4)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
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
                      gradient: LinearGradient(
                        colors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
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

class _MessageTile extends StatelessWidget {
  final CommunityMessage message;
  final bool canDelete;
  final bool isRoomAdmin;
  final VoidCallback onLongPress;

  const _MessageTile({
    required this.message,
    required this.canDelete,
    required this.isRoomAdmin,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = message.userId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE07A5F).withValues(alpha: 0.25),
              child: Text(
                (message.username != null && message.username!.isNotEmpty
                        ? message.username![0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFD66A50),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    message.username ?? 'Student',
                    style: const TextStyle(
                      color: Color(0xFF806A63),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                GestureDetector(
                  onLongPress: onLongPress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            )
                          : null,
                      color: isMe ? null : const Color(0xFFF7EBDD),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMe ? const Radius.circular(4) : null,
                        bottomLeft: isMe ? null : const Radius.circular(4),
                      ),
                      border: isMe
                          ? null
                          : Border.all(color: const Color(0xFFE8D4C4)),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFFF1F5F9),
                        fontSize: 14,
                      ),
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
