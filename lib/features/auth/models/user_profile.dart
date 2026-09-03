/// ─────────────────────────────────────────────────────────────────────────────
/// UserProfile — Data model for a student's profile
///
/// This maps to the `profiles` table in Supabase.
/// ─────────────────────────────────────────────────────────────────────────────
class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;
  final String bio;
  final String college;
  final String branch;
  final int? year;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    required this.bio,
    required this.college,
    required this.branch,
    this.year,
    required this.createdAt,
  });

  /// Converts a Supabase row (a Map) into a UserProfile object
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id:        map['id'] as String,
      username:  map['username'] as String? ?? '',
      fullName:  map['full_name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      bio:       map['bio'] as String? ?? '',
      college:   map['college'] as String? ?? '',
      branch:    map['branch'] as String? ?? '',
      year:      map['year'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts a UserProfile object back to a Map (for Supabase updates)
  Map<String, dynamic> toMap() {
    return {
      'id':        id,
      'username':  username,
      'full_name': fullName,
      'avatar_url':avatarUrl,
      'bio':       bio,
      'college':   college,
      'branch':    branch,
      'year':      year,
    };
  }

  /// Returns display name — prefers fullName, falls back to username
  String get displayName => fullName.isNotEmpty ? fullName : username;

  /// Returns initials for avatar placeholder (e.g. "Aryan Singh" → "AS")
  String get initials {
    if (fullName.isNotEmpty) {
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return fullName[0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  /// Creates a copy with some fields changed
  UserProfile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? college,
    String? branch,
    int? year,
  }) {
    return UserProfile(
      id:        id,
      username:  username  ?? this.username,
      fullName:  fullName  ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio:       bio       ?? this.bio,
      college:   college   ?? this.college,
      branch:    branch    ?? this.branch,
      year:      year      ?? this.year,
      createdAt: createdAt,
    );
  }
}
