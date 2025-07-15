import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nota_model.dart';

class NotaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notas';

  // Salvar ou atualizar uma nota
  Future<bool> salvarNota({
    required String disciplinaId,
    required String alunoId,
    required String professorId,
    required double nota,
    String? testeId,
    String? tarefaId,
  }) async {
    try {
      // Validar nota
      if (!NotaModel.isNotaValida(nota)) {
        throw Exception('Nota deve estar entre 0 e 20');
      }

      // Determinar tipo
      String tipo;
      if (testeId != null && tarefaId == null) {
        tipo = 'teste';
      } else if (tarefaId != null && testeId == null) {
        tipo = 'tarefa';
      } else {
        throw Exception('Deve fornecer apenas testeId ou tarefaId');
      }

      // Gerar ID único para a nota
      final notaId = NotaModel.gerarNotaId(
        disciplinaId: disciplinaId,
        alunoId: alunoId,
        testeId: testeId,
        tarefaId: tarefaId,
      );

      // Verificar se a nota já existe
      final notaExistente =
          await _firestore.collection(_collection).doc(notaId).get();

      final agora = DateTime.now();

      if (notaExistente.exists) {
        // Atualizar nota existente
        final notaAtual = NotaModel.fromMap(notaExistente.data()!, notaId);
        final notaAtualizada = notaAtual.copyWith(
          nota: nota,
          dataAtualizacao: agora,
        );

        await _firestore
            .collection(_collection)
            .doc(notaId)
            .update(notaAtualizada.toMap());
      } else {
        // Criar nova nota
        final novaNota = NotaModel(
          id: notaId,
          alunoId: alunoId,
          disciplinaId: disciplinaId,
          professorId: professorId,
          testeId: testeId,
          tarefaId: tarefaId,
          nota: nota,
          dataLancamento: agora,
          tipo: tipo,
        );

        await _firestore
            .collection(_collection)
            .doc(notaId)
            .set(novaNota.toMap());
      }

      return true;
    } catch (e) {
      print('Erro ao salvar nota: $e');
      return false;
    }
  }

  // Salvar múltiplas notas de uma vez (para um teste ou tarefa)
  Future<Map<String, bool>> salvarNotasLote({
    required String disciplinaId,
    required String professorId,
    required Map<String, double> notasPorAluno, // {alunoId: nota}
    String? testeId,
    String? tarefaId,
  }) async {
    final resultados = <String, bool>{};

    for (final entry in notasPorAluno.entries) {
      final alunoId = entry.key;
      final nota = entry.value;

      final sucesso = await salvarNota(
        disciplinaId: disciplinaId,
        alunoId: alunoId,
        professorId: professorId,
        nota: nota,
        testeId: testeId,
        tarefaId: tarefaId,
      );

      resultados[alunoId] = sucesso;
    }

    return resultados;
  }

  // Buscar notas de uma disciplina
  Future<List<NotaModel>> getNotasDisciplina(String disciplinaId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('disciplinaId', isEqualTo: disciplinaId)
              .get();

      return querySnapshot.docs
          .map((doc) => NotaModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao buscar notas da disciplina: $e');
      return [];
    }
  }

  // Buscar notas de um teste específico
  Future<List<NotaModel>> getNotasTeste({
    required String disciplinaId,
    required String testeId,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('disciplinaId', isEqualTo: disciplinaId)
              .where('testeId', isEqualTo: testeId)
              .where('tipo', isEqualTo: 'teste')
              .get();

      return querySnapshot.docs
          .map((doc) => NotaModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao buscar notas do teste: $e');
      return [];
    }
  }

  // Buscar notas de uma tarefa específica
  Future<List<NotaModel>> getNotasTarefa({
    required String disciplinaId,
    required String tarefaId,
  }) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .where('disciplinaId', isEqualTo: disciplinaId)
              .where('tarefaId', isEqualTo: tarefaId)
              .where('tipo', isEqualTo: 'tarefa')
              .get();

      return querySnapshot.docs
          .map((doc) => NotaModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao buscar notas da tarefa: $e');
      return [];
    }
  }

  // Buscar nota específica de um aluno
  Future<NotaModel?> getNotaAluno({
    required String disciplinaId,
    required String alunoId,
    String? testeId,
    String? tarefaId,
  }) async {
    try {
      final notaId = NotaModel.gerarNotaId(
        disciplinaId: disciplinaId,
        alunoId: alunoId,
        testeId: testeId,
        tarefaId: tarefaId,
      );

      final doc = await _firestore.collection(_collection).doc(notaId).get();

      if (doc.exists) {
        return NotaModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar nota do aluno: $e');
      return null;
    }
  }

  // Verificar se todas as notas foram lançadas para um teste/tarefa
  Future<Map<String, dynamic>> verificarNotasCompletas({
    required String disciplinaId,
    required List<String> alunosIds,
    String? testeId,
    String? tarefaId,
  }) async {
    try {
      final notasExistentes =
          testeId != null
              ? await getNotasTeste(
                disciplinaId: disciplinaId,
                testeId: testeId,
              )
              : await getNotasTarefa(
                disciplinaId: disciplinaId,
                tarefaId: tarefaId!,
              );

      final alunosComNota = notasExistentes.map((nota) => nota.alunoId).toSet();
      final alunosSemNota =
          alunosIds.where((id) => !alunosComNota.contains(id)).toList();

      return {
        'completo': alunosSemNota.isEmpty,
        'totalAlunos': alunosIds.length,
        'notasLancadas': alunosComNota.length,
        'alunosSemNota': alunosSemNota,
        'percentualCompleto':
            (alunosComNota.length / alunosIds.length * 100).round(),
      };
    } catch (e) {
      print('Erro ao verificar completude das notas: $e');
      return {
        'completo': false,
        'totalAlunos': alunosIds.length,
        'notasLancadas': 0,
        'alunosSemNota': alunosIds,
        'percentualCompleto': 0,
      };
    }
  }

  // Deletar uma nota
  Future<bool> deletarNota({
    required String disciplinaId,
    required String alunoId,
    String? testeId,
    String? tarefaId,
  }) async {
    try {
      final notaId = NotaModel.gerarNotaId(
        disciplinaId: disciplinaId,
        alunoId: alunoId,
        testeId: testeId,
        tarefaId: tarefaId,
      );

      await _firestore.collection(_collection).doc(notaId).delete();
      return true;
    } catch (e) {
      print('Erro ao deletar nota: $e');
      return false;
    }
  }

  // Validar lote de notas antes de salvar
  static Map<String, String> validarNotasLote(
    Map<String, double> notasPorAluno,
  ) {
    final erros = <String, String>{};

    for (final entry in notasPorAluno.entries) {
      final alunoId = entry.key;
      final nota = entry.value;

      if (!NotaModel.isNotaValida(nota)) {
        erros[alunoId] = 'Nota deve estar entre 0 e 20 (atual: $nota)';
      }
    }

    return erros;
  }
}
