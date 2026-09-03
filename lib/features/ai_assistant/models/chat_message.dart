/// A single chat message in the AI conversation
class ChatMessage {
  final String  content;
  final bool    isUser;   // true = user message, false = AI message
  final DateTime timestamp;
  final bool    isLoading; // true = AI is typing

  const ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.user(String text) => ChatMessage(content: text, isUser: true, timestamp: DateTime.now());
  factory ChatMessage.ai(String text) => ChatMessage(content: text, isUser: false, timestamp: DateTime.now());
  factory ChatMessage.loading() => ChatMessage(content: '', isUser: false, timestamp: DateTime.now(), isLoading: true);
}
