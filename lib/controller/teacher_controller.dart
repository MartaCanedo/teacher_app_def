import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import '../session/session.dart';

class TeacherController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Atualiza morada e código postal do professor logado
  Future<bool> atualizarMoradaECodigoPostal({
    required String novaMorada,
    required String novoCodigoPostal,
  }) async {
    try {
      final professor = Session.currentProfessor!;
      await _firestore.collection('professores').doc(professor.id).update({
        'morada': novaMorada,
        'codigoPostal': novoCodigoPostal,
      });

      // Atualiza também o professor na sessão
      Session.currentProfessor = Professor(
        id: professor.id,
        nome: professor.nome,
        email: professor.email,
        disciplinas: professor.disciplinas,
        nacionalidade: professor.nacionalidade,
        distrito: professor.distrito,
        morada: novaMorada,
        codigoPostal: novoCodigoPostal,
        dataNascimento: professor.dataNascimento,
        nif: professor.nif,
        iban: professor.iban,
        password: professor.password,
      );

      return true;
    } catch (e) {
      print('Erro ao atualizar morada e código postal: $e');
      return false;
    }
  }

  /// Atualiza a senha, validando a senha atual
  Future<String?> atualizarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    final professor = Session.currentProfessor!;

    if (senhaAtual != professor.password) {
      return 'A senha atual está incorreta.';
    }

    if (novaSenha != confirmarSenha) {
      return 'As novas senhas não coincidem.';
    }

    try {
      await _firestore.collection('professores').doc(professor.id).update({
        'password': novaSenha,
      });

      // Atualiza a sessão
      Session.currentProfessor = Professor(
        id: professor.id,
        nome: professor.nome,
        email: professor.email,
        disciplinas: professor.disciplinas,
        nacionalidade: professor.nacionalidade,
        distrito: professor.distrito,
        morada: professor.morada,
        codigoPostal: professor.codigoPostal,
        dataNascimento: professor.dataNascimento,
        nif: professor.nif,
        iban: professor.iban,
        password: novaSenha,
      );

      return null; // sucesso
    } catch (e) {
      print('Erro ao atualizar senha: $e');
      return 'Erro ao atualizar senha.';
    }
  }
}
