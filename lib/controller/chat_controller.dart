import 'package:teacher_app/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectableUser {
  final String id;
  final String name;
  final String type; // 'student' ou 'professor'

  SelectableUser({required this.id, required this.name, required this.type});
}

Future<List<Map<String, dynamic>>> getAllProfessoresEAlunos() async {
  print("ENTREI NO GET ALL PROFESSORES E ALUNOS");
  try {
    final alunosSnap =
        await FirebaseFirestore.instance.collection('students').get();
    final professoresSnap =
        await FirebaseFirestore.instance.collection('professores').get();

    final alunos = alunosSnap.docs.map((doc) {
      final data = doc.data();
      print("ALUNO: ${data['nome'] ?? 'Aluno'}"); // Debug
      return {'id': doc.id, 'name': data['nome'] ?? 'Aluno','type': 'Estudante'};
    }).toList(); // 👈 AQUI ESTAVA FALTANDO

    final professores = professoresSnap.docs.map((doc) {
      final data = doc.data();
      print("PROFESSOR: ${data['nome'] ?? 'Professor'}"); // Debug
      return {'id': doc.id, 'name': data['nome'] ?? 'Professor','type': 'Professor'};
    }).toList(); // 👈 AQUI TAMBÉM

  print('TOTAL ALUNOS: ${alunosSnap.docs.length}');
print('TOTAL PROFESSORES: ${professoresSnap.docs.length}');

    return [...alunos, ...professores];
  } catch (e) {
    print('ERRO AO CARREGAR USUÁRIOS: $e');
    return [];
  }
}



 Future<Chat> createOrGetChat(String userId1, String userId2) async {
  final chatsRef = FirebaseFirestore.instance.collection('chats');

  // Verifica se já existe
  final query = await chatsRef
      .where('participants', arrayContains: userId1)
      .get();

  for (var doc in query.docs) {
    final participants = List<String>.from(doc['participants']);
    if (participants.contains(userId2)) {
      return Chat.fromDocument(doc, userId1);
    }
  }

  // Obtém nomes
  Future<String?> getNome(String id) async {
    final student = await FirebaseFirestore.instance.collection('students').doc(id).get();
    if (student.exists) return student.data()?['nome'];

    final prof = await FirebaseFirestore.instance.collection('professores').doc(id).get();
    if (prof.exists) return prof.data()?['nome'];

    return null;
  }

  final name1 = await getNome(userId1) ?? 'Utilizador';
  final name2 = await getNome(userId2) ?? 'Utilizador';

  // Cria novo chat com campo `users`
  final newDoc = await chatsRef.add({
    'participants': [userId1, userId2],
    'timestamp': Timestamp.now(),
    'users': {
      userId1: {'name': name1},
      userId2: {'name': name2},
    }
  });

  final newSnapshot = await newDoc.get();
  return Chat.fromDocument(newSnapshot, userId1);
}


