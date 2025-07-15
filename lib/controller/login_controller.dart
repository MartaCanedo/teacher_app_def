import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';

class LoginController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Professor?> login(String email, String password) async {
    try {
      final snapshot =
          await _firestore
              .collection('professores')
              .where('email', isEqualTo: email)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      if (data['password'] == password) {
        return Professor.fromMap(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }
}
