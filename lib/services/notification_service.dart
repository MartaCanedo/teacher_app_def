import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

class NotificationService {
  static Future<void> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      print('⚠️ Carregando service account (apenas para desenvolvimento)');

      // Ler o arquivo de service account dos assets
      final serviceAccountJson = await rootBundle.loadString(
        'assets/campus-link-def-firebase-adminsdk-fbsvc-009abb77a7.json',
      );

      final serviceAccount = json.decode(serviceAccountJson);

      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(credentials, scopes);

      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send',
      );

      final message = {
        "message": {
          "token": targetToken,
          "notification": {"title": title, "body": body},
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "type": "chat_message",
          },
        },
      };

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação enviada com sucesso');
      } else {
        print('❌ Erro ao enviar notificação: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      client.close();
    } catch (e) {
      print('❌ Erro no serviço de notificação: $e');
    }
  }

  // Método para enviar notificação de chat
  static Future<void> sendChatNotification({
    required String receiverId,
    required String senderName,
    required String message,
  }) async {
    try {
      // Buscar o token FCM do destinatário
      final userDoc =
          await FirebaseFirestore.instance
              .collection('students')
              .doc(receiverId)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final fcmToken = userData?['fcmToken'];

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await sendPushNotification(
            targetToken: fcmToken,
            title: senderName,
            body: message,
          );
        } else {
          print('⚠️ Token FCM não encontrado para o usuário $receiverId');
        }
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de chat: $e');
    }
  }

  // Método para enviar notificação de tarefa para todos os alunos da disciplina
  static Future<void> sendTaskNotificationToStudents({
    required String courseId,
    required String disciplinaNome,
    required String professorName,
    required String taskTitle,
    required bool isTest,
  }) async {
    try {
      print(
        '📢 Enviando notificações de ${isTest ? "teste" : "tarefa"} para alunos da disciplina: $disciplinaNome',
      );

      // Buscar os alunos da disciplina
      final students = await _getStudentsFromSubject(courseId, disciplinaNome);

      final title = isTest ? 'Novo Teste Disponível' : 'Nova Tarefa Disponível';
      final body =
          '$professorName criou ${isTest ? "um novo teste" : "uma nova tarefa"}: $taskTitle em $disciplinaNome';

      // Enviar notificação para cada aluno
      for (final student in students) {
        final fcmToken = student['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await sendPushNotification(
            targetToken: fcmToken,
            title: title,
            body: body,
          );
          print('✅ Notificação enviada para ${student['nome']}');
        } else {
          print('⚠️ Token FCM não encontrado para ${student['nome']}');
        }
      }

      print('📢 Notificações enviadas para ${students.length} alunos');
    } catch (e) {
      print('❌ Erro ao enviar notificações de tarefa: $e');
    }
  }

  // Método para enviar notificação de material para todos os alunos da disciplina
  static Future<void> sendMaterialNotificationToStudents({
    required String courseId,
    required String disciplinaNome,
    required String professorName,
    required String materialTitle,
  }) async {
    try {
      print(
        '📢 Enviando notificações de material para alunos da disciplina: $disciplinaNome',
      );

      // Buscar os alunos da disciplina
      final students = await _getStudentsFromSubject(courseId, disciplinaNome);

      const title = 'Novo Material Disponível';
      final body =
          '$professorName adicionou um novo material: $materialTitle em $disciplinaNome';

      // Enviar notificação para cada aluno
      for (final student in students) {
        final fcmToken = student['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await sendPushNotification(
            targetToken: fcmToken,
            title: title,
            body: body,
          );
          print('✅ Notificação enviada para ${student['nome']}');
        } else {
          print('⚠️ Token FCM não encontrado para ${student['nome']}');
        }
      }

      print('📢 Notificações enviadas para ${students.length} alunos');
    } catch (e) {
      print('❌ Erro ao enviar notificações de material: $e');
    }
  }

  // Função privada para buscar alunos de uma disciplina
  static Future<List<Map<String, dynamic>>> _getStudentsFromSubject(
    String courseId,
    String disciplinaNome,
  ) async {
    try {
      // Normalizar strings para comparação
      String normalizar(String s) {
        return s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      // Buscar o curso
      final coursesSnap =
          await FirebaseFirestore.instance.collection('courses').get();
      final normalizadoCourseId = normalizar(courseId);

      QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc;
      try {
        courseDoc = coursesSnap.docs.firstWhere(
          (doc) =>
              normalizar(doc.id) == normalizadoCourseId ||
              normalizar(doc['name'] ?? '') == normalizadoCourseId,
        );
      } catch (e) {
        try {
          courseDoc = coursesSnap.docs.firstWhere(
            (doc) =>
                normalizar(doc.id).contains(normalizadoCourseId) ||
                normalizar(doc['name'] ?? '').contains(normalizadoCourseId),
          );
        } catch (e) {
          print('Curso não encontrado: $courseId');
          return [];
        }
      }

      // Buscar a disciplina dentro do curso
      final subjectsSnap =
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseDoc.id)
              .collection('subjects')
              .get();

      final normalizadoDisciplina = normalizar(disciplinaNome);
      QueryDocumentSnapshot<Map<String, dynamic>>? subjectDoc;

      try {
        subjectDoc = subjectsSnap.docs.firstWhere(
          (doc) => normalizar(doc['name'] ?? '') == normalizadoDisciplina,
        );
      } catch (e) {
        print('Disciplina não encontrada: $disciplinaNome');
        return [];
      }

      final subject = subjectDoc.data();
      final int subjectCourseYear = subject['courseYear'] ?? 0;

      // Buscar alunos do curso e ano correspondente
      final studentsSnap =
          await FirebaseFirestore.instance
              .collection('students')
              .where('courseId', whereIn: [courseDoc.id, courseDoc['name']])
              .where('year', isEqualTo: subjectCourseYear)
              .get();

      return studentsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nome': data['nome'] ?? '',
          'fcmToken': data['fcmToken'],
        };
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar alunos da disciplina: $e');
      return [];
    }
  }
}
