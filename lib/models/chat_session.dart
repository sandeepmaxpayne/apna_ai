class ChatSession {
  final int? id;
  final String title;
  final String message;
  final String timestamp;

  ChatSession({
    this.id,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      timestamp: map['timestamp'],
    );
  }
}
