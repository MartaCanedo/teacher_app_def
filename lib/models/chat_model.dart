import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String chatId;
  final String userId; // ID da outra pessoa
  final String name;

  Chat({
    required this.chatId,
    required this.userId,
    required this.name,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> map) {
    return Chat(
      chatId: id,
      userId: map['userId'],
      name: map['name'],
    );
  }

  factory Chat.fromDocument(DocumentSnapshot doc, String currentUserId) {
  final data = doc.data() as Map<String, dynamic>;
  final participants = List<String>.from(data['participants']);
  final otherUserId = participants.firstWhere((id) => id != currentUserId);

  return Chat(
    chatId: doc.id,
    userId: otherUserId,
    name: data['name'] ?? 'Chat',
  );
}
}
