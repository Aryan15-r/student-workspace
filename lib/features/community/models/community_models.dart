// Community models
class Community {
  final String id, name, description, icon, category;
  final DateTime createdAt;
  const Community({required this.id, required this.name, required this.description, required this.icon, required this.category, required this.createdAt});
  factory Community.fromMap(Map<String, dynamic> m) => Community(
    id: m['id'] as String, name: m['name'] as String, description: m['description'] as String? ?? '',
    icon: m['icon'] as String? ?? '🎓', category: m['category'] as String? ?? 'general',
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class Channel {
  final String id, communityId, name, description;
  const Channel({required this.id, required this.communityId, required this.name, required this.description});
  factory Channel.fromMap(Map<String, dynamic> m) => Channel(
    id: m['id'] as String, communityId: m['community_id'] as String,
    name: m['name'] as String, description: m['description'] as String? ?? '',
  );
}

class CommunityMessage {
  final String id, channelId, userId, content;
  final DateTime createdAt;
  final String? username, avatarUrl;
  const CommunityMessage({required this.id, required this.channelId, required this.userId, required this.content, required this.createdAt, this.username, this.avatarUrl});
  factory CommunityMessage.fromMap(Map<String, dynamic> m) => CommunityMessage(
    id: m['id'] as String, channelId: m['channel_id'] as String, userId: m['user_id'] as String,
    content: m['content'] as String, createdAt: DateTime.parse(m['created_at'] as String),
    username: m['profiles']?['username'] as String?, avatarUrl: m['profiles']?['avatar_url'] as String?,
  );
}
