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
    _loading = true; notifyListeners();
    try {
      final data = await _db.from('communities').select().order('name');
      _communities = (data as List).map((m) => Community.fromMap(m)).toList();
      _error = null;
    } catch (e) { _error = 'Could not load communities'; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> loadChannels(String communityId) async {
    _loading = true; notifyListeners();
    try {
      final data = await _db.from('channels').select().eq('community_id', communityId).order('name');
      _channels = (data as List).map((m) => Channel.fromMap(m)).toList();
      _error = null;
    } catch (e) { _error = 'Could not load channels'; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> loadMessages(String channelId) async {
    _loading = true; notifyListeners();
    try {
      final data = await _db.from('messages').select('*, profiles(username, avatar_url)').eq('channel_id', channelId).order('created_at').limit(50);
      _messages = (data as List).map((m) => CommunityMessage.fromMap(m)).toList();
      _error = null;
      _subscribeRealtime(channelId);
    } catch (e) { _error = 'Could not load messages'; }
    finally { _loading = false; notifyListeners(); }
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
          // Fetch the new message with profile info
          final data = await _db.from('messages').select('*, profiles(username, avatar_url)').eq('id', payload.newRecord['id']).maybeSingle();
          if (data != null) {
            _messages.add(CommunityMessage.fromMap(data));
            notifyListeners();
          }
        },
      ).subscribe();
  }

  Future<void> sendMessage(String channelId, String content) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null || content.trim().isEmpty) return;
    try {
      await _db.from('messages').insert({'channel_id': channelId, 'user_id': userId, 'content': content.trim()});
    } catch (e) { _error = 'Could not send message'; notifyListeners(); }
  }

  @override
  void dispose() { _realtimeChannel?.unsubscribe(); super.dispose(); }
}
