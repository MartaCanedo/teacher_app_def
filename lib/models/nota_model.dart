import 'package:cloud_firestore/cloud_firestore.dart';

class NotaModel {
  final String id;
  final String alunoId;
  final String disciplinaId;
  final String professorId;
  final String? testeId;
  final String? tarefaId;
  final double nota;
  final DateTime dataLancamento;
  final DateTime? dataAtualizacao;
  final String tipo; // 'teste' ou 'tarefa'

  NotaModel({
    required this.id,
    required this.alunoId,
    required this.disciplinaId,
    required this.professorId,
    this.testeId,
    this.tarefaId,
    required this.nota,
    required this.dataLancamento,
    this.dataAtualizacao,
    required this.tipo,
  });

  factory NotaModel.fromMap(Map<String, dynamic> map, String id) {
    return NotaModel(
      id: id,
      alunoId: map['alunoId'] ?? '',
      disciplinaId: map['disciplinaId'] ?? '',
      professorId: map['professorId'] ?? '',
      testeId: map['testeId'],
      tarefaId: map['tarefaId'],
      nota: (map['nota'] ?? 0.0).toDouble(),
      dataLancamento: (map['dataLancamento'] as Timestamp).toDate(),
      dataAtualizacao:
          map['dataAtualizacao'] != null
              ? (map['dataAtualizacao'] as Timestamp).toDate()
              : null,
      tipo: map['tipo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'disciplinaId': disciplinaId,
      'professorId': professorId,
      'testeId': testeId,
      'tarefaId': tarefaId,
      'nota': nota,
      'dataLancamento': Timestamp.fromDate(dataLancamento),
      'dataAtualizacao':
          dataAtualizacao != null ? Timestamp.fromDate(dataAtualizacao!) : null,
      'tipo': tipo,
    };
  }

  NotaModel copyWith({
    String? id,
    String? alunoId,
    String? disciplinaId,
    String? professorId,
    String? testeId,
    String? tarefaId,
    double? nota,
    DateTime? dataLancamento,
    DateTime? dataAtualizacao,
    String? tipo,
  }) {
    return NotaModel(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      professorId: professorId ?? this.professorId,
      testeId: testeId ?? this.testeId,
      tarefaId: tarefaId ?? this.tarefaId,
      nota: nota ?? this.nota,
      dataLancamento: dataLancamento ?? this.dataLancamento,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      tipo: tipo ?? this.tipo,
    );
  }

  // Validação da nota
  static bool isNotaValida(double nota) {
    return nota >= 0.0 && nota <= 20.0;
  }

  // Cria um ID único para a nota baseado no tipo e referência
  static String gerarNotaId({
    required String disciplinaId,
    required String alunoId,
    String? testeId,
    String? tarefaId,
  }) {
    if (testeId != null) {
      return '${disciplinaId}_${alunoId}_teste_$testeId';
    } else if (tarefaId != null) {
      return '${disciplinaId}_${alunoId}_tarefa_$tarefaId';
    }
    throw ArgumentError('Deve fornecer testeId ou tarefaId');
  }
}
