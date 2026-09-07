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
    } catch (e) {
      _error = 'Could not load messages';
    } finally {
      _loading = false;
      notifyListeners();
    }
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

  /// Create or join a Room with Private Passcode support
  Future<Map<String, String>?> joinOrCreateRoom({
    required String roomName,
    String? icon,
    String? description,
    bool isPrivate = false,
    String? passcode,
    String? inputPasscode,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final sanitizedName = roomName.trim();
      if (sanitizedName.isEmpty) return null;
      final user = _db.auth.currentUser;

      // 1. Check if community exists with exact name
      final existing = await _db
          .from('communities')
          .select()
          .ilike('name', sanitizedName)
          .maybeSingle();

      String communityId;
      if (existing != null) {
        communityId = existing['id'] as String;
        final roomIsPrivate = existing['is_private'] as bool? ?? false;
        final roomPasscode  = existing['passcode'] as String? ?? '';
        final roomCreatorId = existing['created_by'] as String?;

        // Verify private room passcode if user is not creator
        if (roomIsPrivate && roomPasscode.isNotEmpty) {
          final isCreator = user != null && user.id == roomCreatorId;
          final providedPass = (inputPasscode ?? passcode ?? '').trim();
          if (!isCreator && providedPass != roomPasscode.trim()) {
            _error = 'Incorrect passcode for private room "$sanitizedName".';
            return null;
          }
        }
      } else {
        if (user == null) {
          _error = 'Please sign in to create a new room.';
          return null;
        }

        final insertData = <String, dynamic>{
          'name': sanitizedName,
          'description': description?.trim().isNotEmpty == true
              ? description!.trim()
              : (isPrivate ? 'Private Room #$sanitizedName' : 'Instant Study Room #$sanitizedName'),
          'icon': icon?.trim().isNotEmpty == true ? icon!.trim() : (isPrivate ? '🔒' : '💬'),
          'category': 'general',
          'is_private': isPrivate,
          'passcode': isPrivate ? (passcode?.trim() ?? '') : '',
          'created_by': user.id,
        };
        final newComm = await _db.from('communities').insert(insertData).select().single();
        communityId = newComm['id'] as String;
      }

      // 2. Fetch or create default channel
      var channelData = await _db
          .from('channels')
          .select()
          .eq('community_id', communityId)
          .maybeSingle();

      String channelId;
      if (channelData != null) {
        channelId = channelData['id'] as String;
      } else {
        final newChannel = await _db.from('channels').insert({
          'community_id': communityId,
          'name': 'general',
          'description': 'Main discussion in $sanitizedName',
          'is_private': isPrivate,
          'passcode': isPrivate ? (passcode?.trim() ?? '') : '',
          'created_by': user?.id,
        }).select().single();
        channelId = newChannel['id'] as String;
      }

      await loadCommunities();
      return {'communityId': communityId, 'channelId': channelId};
    } catch (e) {
      _error = 'Could not join or create room: $e';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
