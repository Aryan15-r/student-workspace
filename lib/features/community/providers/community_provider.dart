import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_models.dart';

class CommunityProvider extends ChangeNotifier {
  final _db = Supabase.instance.client;
  List<Community>        _communities = [];
  List<Channel>          _channels    = [];
  List<CommunityMessage> _messages    = [];
  bool    _loading = false;
  String? _error;
  RealtimeChannel? _realtimeChannel;

  List<Community>        get communities => _communities;
  List<Channel>          get channels    => _channels;
  List<CommunityMessage> get messages    => _messages;
  List<ChannelMember>    _channelMembers = [];
  List<ChannelMember>    get channelMembers => _channelMembers;
  bool                   get isLoading   => _loading;
  String?                get error       => _error;

  Future<void> loadCommunities() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _db.from('communities').select().order('name');
      _communities = (data as List).map((m) => Community.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Could not load rooms';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadChannels(String communityId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _db.from('channels').select().eq('community_id', communityId).order('name');
      _channels = (data as List).map((m) => Channel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Could not load channels';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String channelId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _db
          .from('messages')
          .select('*, profiles(username, avatar_url)')
          .eq('channel_id', channelId)
          .order('created_at')
          .limit(100);
      _messages = (data as List).map((m) => CommunityMessage.fromMap(m)).toList();
      _error = null;
      _subscribeRealtime(channelId);
      await loadChannelMembers(channelId);
    } catch (e) {
      _error = 'Could not load messages';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadChannelMembers(String channelId) async {
    try {
      final data = await _db
          .from('channel_members')
          .select('*, profiles(username, avatar_url)')
          .eq('channel_id', channelId);
      _channelMembers = (data as List).map((m) => ChannelMember.fromMap(m)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void _subscribeRealtime(String channelId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _db.channel('messages-$channelId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'channel_id', value: channelId),
        callback: (payload) async {
          final newId = payload.newRecord['id'] as String?;
          if (newId == null) return;
          if (_messages.any((m) => m.id == newId)) return;

          try {
            final data = await _db
                .from('messages')
                .select('*, profiles(username, avatar_url)')
                .eq('id', newId)
                .maybeSingle();
            if (data != null) {
              final newMsg = CommunityMessage.fromMap(data);
              _messages.removeWhere((m) => m.id.startsWith('temp-') && m.userId == newMsg.userId && m.content == newMsg.content);
              if (!_messages.any((m) => m.id == newMsg.id)) {
                _messages.add(newMsg);
                notifyListeners();
              }
            }
          } catch (_) {}
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'channel_id', value: channelId),
        callback: (payload) {
          final oldId = payload.oldRecord['id'] as String?;
          if (oldId != null) {
            _messages.removeWhere((m) => m.id == oldId);
            notifyListeners();
          }
        },
      )
      .subscribe();
  }

  /// Instant Optimistic Message Sending
  Future<void> sendMessage(String channelId, String content) async {
    final user = _db.auth.currentUser;
    if (user == null || content.trim().isEmpty) return;
    final trimmed = content.trim();

    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final userName = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'You';

    final optimisticMsg = CommunityMessage(
      id: tempId,
      channelId: channelId,
      userId: user.id,
      content: trimmed,
      createdAt: DateTime.now(),
      username: userName,
    );

    _messages.add(optimisticMsg);
    notifyListeners();

    try {
      final res = await _db.from('messages').insert({
        'channel_id': channelId,
        'user_id': user.id,
        'content': trimmed,
      }).select('*, profiles(username, avatar_url)').maybeSingle();

      if (res != null) {
        final realMsg = CommunityMessage.fromMap(res);
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = realMsg;
        } else if (!_messages.any((m) => m.id == realMsg.id)) {
          _messages.add(realMsg);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Message sync warning';
      notifyListeners();
    }
  }

  /// Delete Chat Message (Author or Room Creator/Admin luxury)
  Future<bool> deleteMessage(String messageId) async {
    try {
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();

      await _db.from('messages').delete().eq('id', messageId);
      return true;
    } catch (e) {
      _error = 'Could not delete message: $e';
      notifyListeners();
      return false;
    }
  }

  /// STRICT Join Room by Code (DOES NOT create new room if missing)
  Future<Map<String, String>?> joinRoomByCode({
    required String roomCode,
    String? inputPasscode,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final sanitizedCode = roomCode.trim();
      if (sanitizedCode.isEmpty) {
        _error = 'Please enter a valid room code or name.';
        return null;
      }
      final user = _db.auth.currentUser;

      // Check if community exists matching exact code/name
      final existing = await _db
          .from('communities')
          .select()
          .ilike('name', sanitizedCode)
          .maybeSingle();

      if (existing == null) {
        _error = 'Room code "$sanitizedCode" not found! Check the code or create a new room in "New Room" section.';
        return null;
      }

      final communityId = existing['id'] as String;
      final roomIsPrivate = existing['is_private'] as bool? ?? false;
      final roomPasscode  = existing['passcode'] as String? ?? '';
      final roomCreatorId = existing['created_by'] as String?;

      if (roomIsPrivate && roomPasscode.isNotEmpty) {
        final isCreator = user != null && user.id == roomCreatorId;
        final providedPass = (inputPasscode ?? '').trim();
        if (!isCreator && providedPass != roomPasscode.trim()) {
          _error = 'Incorrect passcode for private room "$sanitizedCode".';
          return null;
        }
      }

      // Join channel_members
      if (user != null) {
        await _db.from('channel_members').upsert({
          'channel_id': communityId,
          'user_id': user.id,
          'role': user.id == roomCreatorId ? 'admin' : 'member',
        }, onConflict: 'channel_id, user_id');
      }

      final channelData = await _db
          .from('channels')
          .select()
          .eq('community_id', communityId)
          .maybeSingle();

      final channelId = channelData != null ? channelData['id'] as String : communityId;

      await loadCommunities();
      return {'communityId': communityId, 'channelId': channelId};
    } catch (e) {
      _error = 'Could not join room: $e';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create a New Public or Private Room
  Future<Map<String, String>?> createNewRoom({
    required String roomName,
    String? icon,
    String? description,
    bool isPrivate = false,
    String? passcode,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final sanitizedName = roomName.trim();
      if (sanitizedName.isEmpty) {
        _error = 'Room name cannot be empty.';
        return null;
      }
      final user = _db.auth.currentUser;
      if (user == null) {
        _error = 'Please sign in to create a room.';
        return null;
      }

      final existing = await _db
          .from('communities')
          .select()
          .ilike('name', sanitizedName)
          .maybeSingle();

      if (existing != null) {
        _error = 'A room named "$sanitizedName" already exists! Please use a unique room code or name.';
        return null;
      }

      final insertData = <String, dynamic>{
        'name': sanitizedName,
        'description': description?.trim().isNotEmpty == true
            ? description!.trim()
            : (isPrivate ? 'Private Study Room #$sanitizedName' : 'Public Lounge #$sanitizedName'),
        'icon': icon?.trim().isNotEmpty == true ? icon!.trim() : (isPrivate ? '🔒' : '💬'),
        'category': 'general',
        'is_private': isPrivate,
        'passcode': isPrivate ? (passcode?.trim() ?? '') : '',
        'created_by': user.id,
      };

      final newComm = await _db.from('communities').insert(insertData).select().single();
      final communityId = newComm['id'] as String;

      final newChannel = await _db.from('channels').insert({
        'community_id': communityId,
        'name': 'general',
        'description': 'Main channel in $sanitizedName',
        'is_private': isPrivate,
        'passcode': isPrivate ? (passcode?.trim() ?? '') : '',
        'created_by': user.id,
      }).select().single();
      final channelId = newChannel['id'] as String;

      // Add creator as Admin member
      await _db.from('channel_members').insert({
        'channel_id': channelId,
        'user_id': user.id,
        'role': 'admin',
      });

      await loadCommunities();
      return {'communityId': communityId, 'channelId': channelId};
    } catch (e) {
      _error = 'Could not create room: $e';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete entire Chat/Room & Community (Admin only)
  Future<bool> deleteRoomAndCommunity(String communityId) async {
    try {
      await _db.from('communities').delete().eq('id', communityId);
      await loadCommunities();
      return true;
    } catch (e) {
      _error = 'Failed to delete room: $e';
      notifyListeners();
      return false;
    }
  }

  /// Kick Member from Channel (Admin only)
  Future<bool> kickMember(String channelId, String userId) async {
    try {
      await _db.from('channel_members').delete().match({'channel_id': channelId, 'user_id': userId});
      await loadChannelMembers(channelId);
      return true;
    } catch (e) {
      _error = 'Failed to kick member: $e';
      return false;
    }
  }

  /// Leave Channel
  Future<bool> leaveChannel(String channelId) async {
    final user = _db.auth.currentUser;
    if (user == null) return false;
    try {
      await _db.from('channel_members').delete().match({'channel_id': channelId, 'user_id': user.id});
      return true;
    } catch (e) {
      _error = 'Failed to leave channel: $e';
      return false;
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

