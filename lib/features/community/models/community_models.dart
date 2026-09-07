// Community models with Private Room, Passcode, and Admin Creator support
class Community {
  final String id, name, description, icon, category;
  final DateTime createdAt;
  final bool isPrivate;
  final String passcode;
  final String? createdBy;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.createdAt,
    this.isPrivate = false,
    this.passcode = '',
    this.createdBy,
  });

  factory Community.fromMap(Map<String, dynamic> m) => Community(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    icon: m['icon'] as String? ?? '🎓',
    category: m['category'] as String? ?? 'general',
    createdAt: DateTime.parse(m['created_at'] as String),
    isPrivate: m['is_private'] as bool? ?? false,
    passcode: m['passcode'] as String? ?? '',
    createdBy: m['created_by'] as String?,
  );
}

class Channel {
  final String id, communityId, name, description;
  final bool isPrivate;
  final String passcode;
  final String? createdBy;

  const Channel({
    required this.id,
    required this.communityId,
    required this.name,
    required this.description,
    this.isPrivate = false,
    this.passcode = '',
    this.createdBy,
  });

  factory Channel.fromMap(Map<String, dynamic> m) => Channel(
    id: m['id'] as String,
    communityId: m['community_id'] as String,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    isPrivate: m['is_private'] as bool? ?? false,
    passcode: m['passcode'] as String? ?? '',
    createdBy: m['created_by'] as String?,
  );
}

class CommunityMessage {
  final String id, channelId, userId, content;
  final DateTime createdAt;
  final String? username, avatarUrl;

  const CommunityMessage({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  factory CommunityMessage.fromMap(Map<String, dynamic> m) => CommunityMessage(
    id: m['id'] as String,
    channelId: m['channel_id'] as String,
    userId: m['user_id'] as String,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
    username: m['profiles']?['username'] as String?,
    avatarUrl: m['profiles']?['avatar_url'] as String?,
  );
}

class ChannelMember {
  final String id, channelId, userId;
  final String role;
  final DateTime joinedAt;
  final String? username, avatarUrl;

  const ChannelMember({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.username,
    this.avatarUrl,
  });

  factory ChannelMember.fromMap(Map<String, dynamic> m) => ChannelMember(
    id: m['id'] as String,
    channelId: m['channel_id'] as String,
    userId: m['user_id'] as String,
    role: m['role'] as String? ?? 'member',
    joinedAt: m['joined_at'] != null ? DateTime.parse(m['joined_at'] as String) : DateTime.now(),
    username: m['profiles']?['username'] as String?,
    avatarUrl: m['profiles']?['avatar_url'] as String?,
  );
}

