class MaterialModel {
  final String id;
  final String titulo;
  final String descricao;
  final String? base64Arquivo;
  final String? nomeArquivo;
  final DateTime dataCriacao;
  final String disciplinaId;
  final String professorId;

  MaterialModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataCriacao,
    required this.disciplinaId,
    required this.professorId,
    this.base64Arquivo,
    this.nomeArquivo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'base64Arquivo': base64Arquivo,
      'nomeArquivo': nomeArquivo,
      'dataCriacao': dataCriacao.toIso8601String(),
      'disciplinaId': disciplinaId,
      'professorId': professorId,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: map['id'] ?? '',
      titulo: map['titulo'] ?? '',
      descricao: map['descricao'] ?? '',
      base64Arquivo: map['base64Arquivo'],
      nomeArquivo: map['nomeArquivo'],
      dataCriacao: DateTime.parse(map['dataCriacao']),
      disciplinaId: map['disciplinaId'] ?? '',
      professorId: map['professorId'] ?? '',
    );
  }
}
