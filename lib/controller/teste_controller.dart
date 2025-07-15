import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teste_model.dart';
import 'package:uuid/uuid.dart';

class TesteController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Busca todos os testes de uma disciplina para um professor
  Future<List<TesteModel>> getTestes(
    String disciplinaId,
    String professorId,
  ) async {
    print('[DEBUG] Buscando testes para disciplina: $disciplinaId, professor: $professorId');
    try {
      final snap =
          await _firestore
              .collection('testes')
              .where('disciplinaId', isEqualTo: disciplinaId)
              .where('professorId', isEqualTo: professorId)
              .orderBy(
                'dataHora',
                descending: false,
              ) // Ordenar por data/hora crescente
              .get();
    print('[DEBUG] Testes encontrados: ${snap.docs.length}');
      return snap.docs.map((doc) => TesteModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('[DEBUG] Erro ao buscar testes: $e');
      return [];
    }
  }

  /// Adiciona um novo teste
  Future<void> addTeste({
    required String nome,
    required String disciplinaId,
    required String professorId,
    required DateTime dataHora,
  }) async {
    try {
      final id = _uuid.v4();
      final teste = TesteModel(
        id: id,
        nome: nome,
        disciplinaId: disciplinaId,
        professorId: professorId,
        dataHora: dataHora,
      );

      await _firestore.collection('testes').doc(id).set(teste.toMap());
      print('[DEBUG] Teste adicionado com sucesso: $nome');
    } catch (e) {
      print('[DEBUG] Erro ao adicionar teste: $e');
      throw Exception('Erro ao adicionar teste: $e');
    }
  }

  /// Atualiza um teste existente
  Future<void> updateTeste(TesteModel teste) async {
    try {
      await _firestore.collection('testes').doc(teste.id).update(teste.toMap());
      print('[DEBUG] Teste atualizado com sucesso: ${teste.nome}');
    } catch (e) {
      print('[DEBUG] Erro ao atualizar teste: $e');
      throw Exception('Erro ao atualizar teste: $e');
    }
  }

  /// Remove um teste
  Future<void> deleteTeste(String id) async {
    try {
      await _firestore.collection('testes').doc(id).delete();
      print('[DEBUG] Teste removido com sucesso: $id');
    } catch (e) {
      print('[DEBUG] Erro ao remover teste: $e');
      throw Exception('Erro ao remover teste: $e');
    }
  }

  /// Gera automaticamente o próximo nome de teste (Teste 1, Teste 2, etc.)
  Future<String> getProximoNomeTeste(
    String disciplinaId,
    String professorId,
  ) async {
    try {
      final testes = await getTestes(disciplinaId, professorId);

      // Encontra o maior número de teste existente
      int maiorNumero = 0;
      for (var teste in testes) {
        final regex = RegExp(r'Teste (\d+)', caseSensitive: false);
        final match = regex.firstMatch(teste.nome);
        if (match != null) {
          final numero = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (numero > maiorNumero) {
            maiorNumero = numero;
          }
        }
      }

      return 'Teste ${maiorNumero + 1}';
    } catch (e) {
      print('[DEBUG] Erro ao gerar próximo nome de teste: $e');
      return 'Teste 1'; // Fallback para o primeiro teste
    }
  }

  /// Verifica se já existe um teste com o mesmo nome para a disciplina
  Future<bool> existeTesteComNome(
    String nome,
    String disciplinaId,
    String professorId,
  ) async {
    try {
      final snap =
          await _firestore
              .collection('testes')
              .where('disciplinaId', isEqualTo: disciplinaId)
              .where('professorId', isEqualTo: professorId)
              .where('nome', isEqualTo: nome)
              .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      print('[DEBUG] Erro ao verificar se teste existe: $e');
      return false;
    }
  }
}
