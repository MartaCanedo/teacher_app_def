class Message {
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  // Converter objeto Message em Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Criar objeto Message a partir de Map (ao buscar do Firestore)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
