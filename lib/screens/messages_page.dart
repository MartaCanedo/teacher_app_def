import 'package:teacher_app/controller/chat_controller.dart';
import 'package:teacher_app/models/teacher_model.dart';
import 'package:teacher_app/session/session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../screens/chat_home_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String searchQuery = '';
  late Professor student;

  @override
  void initState() {
    super.initState();
    student = Session.currentProfessor!;
  }

  void _openUserSelector(BuildContext context) async {
    print('Opening user selector...');
    final allUsers = await getAllProfessoresEAlunos();
    print('Usuarios carregados: ${allUsers.length}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered =
                allUsers
                    .where(
                      (u) => u['name'].toLowerCase().contains(
                        search.toLowerCase(),
                      ),
                    )
                    .toList();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por nome...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => search = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Text(user['name']),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      user['type'] == 'Professor'
                                          ? Colors.blue
                                          : Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user['type'] == 'Professor'
                                      ? 'Professor'
                                      : 'Aluno',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            final chat = await createOrGetChat(
                              student.id,
                              user['id'],
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatHomePage(chat: chat),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Session.currentProfessor!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text("Mensagens"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar por nome...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: currentUserId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final chats =
                    snapshot.data!.docs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final otherId = (data['participants'] as List)
                              .firstWhere((id) => id != currentUserId);
                          final name =
                              data['users']?[otherId]?['name'] ?? 'Sem Nome';

                          return Chat(
                            chatId: doc.id,
                            userId: otherId,
                            name: name,
                          );
                        })
                        .where(
                          (chat) => chat.name.toLowerCase().contains(
                            searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection(
                                'students',
                              ) // primeiro tenta em students
                              .doc(chat.userId)
                              .get(),
                      builder: (context, studentSnapshot) {
                        if (studentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text(chat.name),
                            leading: CircleAvatar(child: Text(chat.name[0])),
                            trailing: CircularProgressIndicator(),
                          );
                        }

                        String userType = 'professor'; // default
                        if (studentSnapshot.hasData &&
                            studentSnapshot.data!.exists) {
                          userType = 'student';
                        }

                        return ListTile(
                          title: Row(
                            children: [
                              Text(chat.name),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      userType == 'professor'
                                          ? Colors.blue
                                          : Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  userType == 'professor'
                                      ? 'Professor'
                                      : 'Aluno',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          leading: CircleAvatar(child: Text(chat.name[0])),
                          trailing: Icon(Icons.chat_bubble_outline),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatHomePage(chat: chat),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {print('CLIQUEI NO FAB'), _openUserSelector(context)},
        child: Icon(Icons.add),
      ),
    );
  }
}
