class TesteModel {
  final String id;
  final String nome; // "Teste 1", "Teste 2", etc.
  final String disciplinaId;
  final String professorId;
  final DateTime dataHora;

  TesteModel({
    required this.id,
    required this.nome,
    required this.disciplinaId,
    required this.professorId,
    required this.dataHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'disciplinaId': disciplinaId,
      'professorId': professorId,
      'dataHora': dataHora.millisecondsSinceEpoch,
    };
  }

  factory TesteModel.fromMap(Map<String, dynamic> map) {
    return TesteModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      disciplinaId: map['disciplinaId'] ?? '',
      professorId: map['professorId'] ?? '',
      dataHora: DateTime.fromMillisecondsSinceEpoch(map['dataHora'] ?? 0),
    );
  }

  TesteModel copyWith({
    String? id,
    String? nome,
    String? disciplinaId,
    String? professorId,
    DateTime? dataHora,
  }) {
    return TesteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      professorId: professorId ?? this.professorId,
      dataHora: dataHora ?? this.dataHora,
    );
  }

  @override
  String toString() {
    return 'TesteModel(id: $id, nome: $nome, disciplinaId: $disciplinaId, professorId: $professorId, dataHora: $dataHora)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TesteModel &&
        other.id == id &&
        other.nome == nome &&
        other.disciplinaId == disciplinaId &&
        other.professorId == professorId &&
        other.dataHora == dataHora;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        disciplinaId.hashCode ^
        professorId.hashCode ^
        dataHora.hashCode;
  }
}
