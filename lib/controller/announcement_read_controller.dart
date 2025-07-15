import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_read_model.dart';

class AnnouncementReadController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'announcements_teacher_read';

  /// Carrega os anúncios lidos para um professor
  Future<AnnouncementReadModel> loadReadAnnouncements(
    String professorId,
  ) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(professorId).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return AnnouncementReadModel.fromFirestore(
          docSnapshot.data()!,
          professorId,
        );
      } else {
        // Se não existe, retorna um modelo vazio
        return AnnouncementReadModel.empty(professorId);
      }
    } catch (e) {
      print('Erro ao carregar anúncios lidos: $e');
      // Em caso de erro, retorna um modelo vazio
      return AnnouncementReadModel.empty(professorId);
    }
  }

  /// Marca um anúncio como lido
  Future<bool> markAnnouncementAsRead(
    String professorId,
    String announcementId,
  ) async {
    try {
      // Primeiro carrega os dados atuais
      final currentData = await loadReadAnnouncements(professorId);

      // Cria uma nova versão com o anúncio marcado como lido
      final updatedData = currentData.copyWithNewRead(announcementId);

      // Salva no Firestore
      await _firestore
          .collection(_collection)
          .doc(professorId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar anúncio como lido: $e');
      return false;
    }
  }

  /// Verifica se um anúncio específico foi lido
  Future<bool> isAnnouncementRead(
    String professorId,
    String announcementId,
  ) async {
    try {
      final data = await loadReadAnnouncements(professorId);
      return data.isAnnouncementRead(announcementId);
    } catch (e) {
      print('Erro ao verificar se anúncio foi lido: $e');
      return false;
    }
  }

  /// Obtém a lista de IDs dos anúncios lidos
  Future<Set<String>> getReadAnnouncementIds(String professorId) async {
    try {
      final data = await loadReadAnnouncements(professorId);
      return data.readAnnouncementIds.toSet();
    } catch (e) {
      print('Erro ao obter IDs dos anúncios lidos: $e');
      return <String>{};
    }
  }

  /// Marca múltiplos anúncios como lidos de uma vez
  Future<bool> markMultipleAnnouncementsAsRead(
    String professorId,
    List<String> announcementIds,
  ) async {
    try {
      // Carrega os dados atuais
      final currentData = await loadReadAnnouncements(professorId);

      // Adiciona todos os novos IDs (evitando duplicatas)
      final allReadIds = {
        ...currentData.readAnnouncementIds,
        ...announcementIds,
      };

      // Cria o modelo atualizado
      final updatedData = AnnouncementReadModel(
        professorId: professorId,
        readAnnouncementIds: allReadIds.toList(),
        lastUpdated: DateTime.now(),
      );

      // Salva no Firestore
      await _firestore
          .collection(_collection)
          .doc(professorId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar múltiplos anúncios como lidos: $e');
      return false;
    }
  }

  /// Remove um anúncio da lista de lidos (marcar como não lido)
  Future<bool> markAnnouncementAsUnread(
    String professorId,
    String announcementId,
  ) async {
    try {
      final currentData = await loadReadAnnouncements(professorId);

      // Remove o ID da lista
      final updatedIds =
          currentData.readAnnouncementIds
              .where((id) => id != announcementId)
              .toList();

      final updatedData = AnnouncementReadModel(
        professorId: professorId,
        readAnnouncementIds: updatedIds,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(professorId)
          .set(updatedData.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao marcar anúncio como não lido: $e');
      return false;
    }
  }
}
