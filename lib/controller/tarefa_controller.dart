import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import '../models/tarefa_model.dart';
import 'package:uuid/uuid.dart';
// Ensure removeDiacritics is imported from string_utils.dart

class TarefaController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Busca tarefas por nome da disciplina, courseId e professorId
  Future<List<TarefaModel>> getTarefasPorNomeDisciplina({
    required String nomeDisciplina,
    required String courseId,
    required String professorId,
    required dynamic coursesSnap,
  }) async {
    final firestore = FirebaseFirestore.instance;
    // Busca todas as subjects do courseId
    String normalizar(String s) => removeDiacritics(
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
    // Make sure removeDiacritics is defined in string_utils.dart and imported above
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
        courseDoc = null;
      }
    }
    if (courseDoc == null) return [];
    final courseIdReal = courseDoc.id;
    final subjectsSnap =
        await firestore
            .collection('courses')
            .doc(courseIdReal)
            .collection('subjects')
            .get();
    final normalizadoWidgetNome = normalizar(nomeDisciplina);
    QueryDocumentSnapshot<Map<String, dynamic>>? subjectDoc;
    try {
      subjectDoc = subjectsSnap.docs.firstWhere(
        (doc) => normalizar(doc['name'] ?? '') == normalizadoWidgetNome,
      );
    } catch (e) {
      subjectDoc = null;
    }
    if (subjectDoc == null) return [];
    final disciplinaId = subjectDoc.id;
    // Busca tarefas do Firestore filtrando por disciplinaId e professorId
    final tarefasSnap =
        await firestore
            .collection('tarefas')
            .where('disciplinaId', isEqualTo: disciplinaId)
            .where('professorId', isEqualTo: professorId)
            .get();

    print(
      'Found ${tarefasSnap.docs.length} tarefas for disciplinaId: $disciplinaId, professorId: $professorId',
    );

    final result =
        tarefasSnap.docs.map((doc) => TarefaModel.fromMap(doc.data())).toList();

    print('Successfully parsed ${result.length} tarefas');
    for (final tarefa in result) {
      print('Tarefa: ${tarefa.titulo} (ID: ${tarefa.id})');
    }

    return result;
  }

  Future<void> addTarefa({
    required String titulo,
    required String descricao,
    required String disciplinaId,
    required String professorId,
    required DateTime dataLimite,
    required DateTime dataPublicacao,
    required String horaLimite,
    List<Map<String, String>>? ficheiros,
    Map<String, bool>? entregas,
  }) async {
    final id = _uuid.v4();
    final tarefa = TarefaModel(
      id: id,
      titulo: titulo,
      descricao: descricao,
      disciplinaId: disciplinaId,
      professorId: professorId,
      dataLimite: dataLimite,
      dataPublicacao: dataPublicacao,
      ficheiros: ficheiros ?? [],
      entregas: entregas ?? {},
      horaLimite: horaLimite,
    );
    await _firestore.collection('tarefas').doc(id).set(tarefa.toMap());
  }

  Future<List<TarefaModel>> getTarefas(
    String disciplinaId,
    String professorId,
  ) async {
    final snap =
        await _firestore
            .collection('tarefas')
            .where('disciplinaId', isEqualTo: disciplinaId)
            .where('professorId', isEqualTo: professorId)
            .orderBy('dataPublicacao', descending: true)
            .get();
    print(
      'Found ${snap.docs.length} tarefas for disciplinaId: $disciplinaId, professorId: $professorId',
    );

    final result =
        snap.docs.map((doc) => TarefaModel.fromMap(doc.data())).toList();

    print('Successfully parsed ${result.length} tarefas in getTarefas');
    for (final tarefa in result) {
      print('Tarefa: ${tarefa.titulo} (ID: ${tarefa.id})');
    }

    return result;
  }

  Future<void> updateTarefa(TarefaModel tarefa) async {
    await _firestore
        .collection('tarefas')
        .doc(tarefa.id)
        .update(tarefa.toMap());
  }

  Future<void> deleteTarefa(String id) async {
    await _firestore.collection('tarefas').doc(id).delete();
  }
}
