/// ─────────────────────────────────────────────────────────────────────────────
/// Task — Data model for a to-do item
/// Maps to the `tasks` table in Supabase.
/// ─────────────────────────────────────────────────────────────────────────────
class Task {
  final String  id;
  final String  userId;
  final String  title;
  final String  description;
  final String  category;    // assignment | exam | project | personal | college
  final String  priority;    // low | medium | high
  final DateTime? dueDate;
  final bool    completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.dueDate,
    required this.completed,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id:          map['id'] as String,
      userId:      map['user_id'] as String,
      title:       map['title'] as String,
      description: map['description'] as String? ?? '',
      category:    map['category'] as String? ?? 'personal',
      priority:    map['priority'] as String? ?? 'medium',
      dueDate:     map['due_date'] != null ? DateTime.tryParse(map['due_date'] as String) : null,
      completed:   map['completed'] as bool? ?? false,
      createdAt:   DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'user_id':     userId,
    'title':       title,
    'description': description,
    'category':    category,
    'priority':    priority,
    'due_date':    dueDate?.toIso8601String().split('T')[0], // date only
    'completed':   completed,
  };

  Task copyWith({
    String? title, String? description, String? category,
    String? priority, DateTime? dueDate, bool? completed,
  }) => Task(
    id: id, userId: userId, createdAt: createdAt,
    title:       title       ?? this.title,
    description: description ?? this.description,
    category:    category    ?? this.category,
    priority:    priority    ?? this.priority,
    dueDate:     dueDate     ?? this.dueDate,
    completed:   completed   ?? this.completed,
  );
}
