import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

class AnnouncementController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Buscar todos os anúncios
  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final snapshot = await _firestore.collection('announcements').get();

      return snapshot.docs.map((doc) {
        return Announcement.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar anúncios: $e');
      return [];
    }
  }

  /// Buscar anúncios apenas para professores
  Future<List<Announcement>> getAnnouncementsForProfessors() async {
    try {
      final snapshot =
          await _firestore
              .collection('announcements')
              .where('recipient', whereIn: ["todos", "professores"])
              .get();

      return snapshot.docs.map((doc) {
        return Announcement.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Erro ao buscar anúncios para professores: $e');
      return [];
    }
  }
}
