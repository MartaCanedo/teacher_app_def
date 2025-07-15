import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementReadModel {
  final String professorId;
  final List<String> readAnnouncementIds;
  final DateTime lastUpdated;

  AnnouncementReadModel({
    required this.professorId,
    required this.readAnnouncementIds,
    required this.lastUpdated,
  });

  // Converter do Firestore para o modelo
  factory AnnouncementReadModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return AnnouncementReadModel(
      professorId: docId,
      readAnnouncementIds: List<String>.from(data['readAnnouncementIds'] ?? []),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Converter do modelo para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'readAnnouncementIds': readAnnouncementIds,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Verificar se um anúncio foi lido
  bool isAnnouncementRead(String announcementId) {
    return readAnnouncementIds.contains(announcementId);
  }

  // Criar uma cópia com novos anúncios lidos
  AnnouncementReadModel copyWithNewRead(String announcementId) {
    if (readAnnouncementIds.contains(announcementId)) {
      return this; // Já foi lido
    }

    return AnnouncementReadModel(
      professorId: professorId,
      readAnnouncementIds: [...readAnnouncementIds, announcementId],
      lastUpdated: DateTime.now(),
    );
  }

  // Criar uma instância vazia para um novo professor
  factory AnnouncementReadModel.empty(String professorId) {
    return AnnouncementReadModel(
      professorId: professorId,
      readAnnouncementIds: [],
      lastUpdated: DateTime.now(),
    );
  }
}
