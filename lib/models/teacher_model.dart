// lib/models/professor.dart

class Professor {
  final String id;
  final String nome;
  final String email;
  final List<String> disciplinas;
  final String nacionalidade;
  final String distrito;
  final String morada;
  final String codigoPostal;
  final String dataNascimento;
  final String nif;
  final String iban;
  final String password;

  Professor({
    required this.id,
    required this.nome,
    required this.email,
    required this.disciplinas,
    required this.nacionalidade,
    required this.distrito,
    required this.morada,
    required this.codigoPostal,
    required this.dataNascimento,
    required this.nif,
    required this.iban,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'disciplinas': disciplinas,
      'nacionalidade': nacionalidade,
      'distrito': distrito,
      'morada': morada,
      'codigoPostal': codigoPostal,
      'dataNascimento': dataNascimento,
      'nif': nif,
      'iban': iban,
      'password': password,
    };
  }

  factory Professor.fromMap(Map<String, dynamic> map) {
    return Professor(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      disciplinas: List<String>.from(map['disciplinas'] ?? []),
      nacionalidade: map['nacionalidade'] ?? '',
      distrito: map['distrito'] ?? '',
      morada: map['morada'] ?? '',
      codigoPostal: map['codigoPostal'] ?? '',
      dataNascimento: map['dataNascimento'] ?? '',
      nif: map['nif'] ?? '',
      iban: map['iban'] ?? '',
      password: map['password'] ?? '',
    );
  }
}
