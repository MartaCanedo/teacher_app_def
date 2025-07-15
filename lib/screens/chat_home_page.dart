import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:teacher_app/services/notification_service.dart';
import '../models/chat_model.dart';
import '../session/session.dart'; // para acessar Session.currentUser.id
import '../models/message_models.dart';

class ChatHomePage extends StatefulWidget {
  final Chat chat;

  const ChatHomePage({super.key, required this.chat});

  @override
  _ChatHomePageState createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> sendMessage() async {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final currentUserId = Session.currentProfessor!.id;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chat.chatId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        });
    final receiverId = widget.chat.userId;
    final senderName = Session.currentProfessor?.nome ?? 'Alguém';
    await NotificationService.sendChatNotification(
      receiverId: receiverId,
      senderName: senderName,
      message: content,
    );
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Session.currentProfessor!.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.chat.name)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chat.chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final content = data['content'] ?? '';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[800] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Escreve uma mensagem...",
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
