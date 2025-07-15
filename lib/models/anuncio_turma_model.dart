class AnuncioTurma {
  final String id;
  final String titulo;
  final String descricao;
  final String disciplina;
  final Map<String, dynamic> ficheiro; // {'nome': ..., 'base64': ...}

  AnuncioTurma({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.disciplina,
    required this.ficheiro,
  });

  Map<String, dynamic> toMap() {
    // Ensure the ficheiro map has proper string keys and values
    final cleanFicheiro = <String, dynamic>{};
    for (final entry in ficheiro.entries) {
      if (entry.value != null) {
        cleanFicheiro[entry.key] = entry.value.toString();
      }
    }

    return {
      'titulo': titulo,
      'descricao': descricao,
      'disciplina': disciplina,
      'ficheiro': cleanFicheiro,
    };
  }

  factory AnuncioTurma.fromMap(Map<String, dynamic> data, String id) {
    return AnuncioTurma(
      id: id,
      titulo: data['titulo'] ?? '',
      descricao: data['descricao'] ?? '',
      disciplina: data['disciplina'] ?? '',
      ficheiro: Map<String, dynamic>.from(data['ficheiro'] ?? {}),
    );
  }
}
