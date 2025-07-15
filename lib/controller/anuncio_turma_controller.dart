import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/anuncio_turma_model.dart';

class AnuncioTurmaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'anuncios_turma';

  /// Criar um novo anúncio
  Future<void> criarAnuncioTurma(AnuncioTurma anuncio) async {
    try {
      await _firestore.collection(_collection).add(anuncio.toMap());
    } catch (e) {
      print('Erro ao criar anúncio: $e');
      rethrow;
    }
  }

  /// Editar um anúncio existente
  Future<void> editarAnuncioTurma(AnuncioTurma anuncio) async {
    await _firestore
        .collection(_collection)
        .doc(anuncio.id)
        .update(anuncio.toMap());
  }

  /// Eliminar um anúncio
  Future<void> eliminarAnuncioTurma(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Buscar todos os anúncios por disciplina
  Future<List<AnuncioTurma>> buscarPorDisciplina(String disciplina) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('disciplina', isEqualTo: disciplina)
            .get();

    return snapshot.docs.map((doc) {
      return AnuncioTurma.fromMap(doc.data(), doc.id);
    }).toList();
  }
}
