import 'package:cloud_firestore/cloud_firestore.dart';

class PresencaModel {
  final String id;
  final String alunoId;
  final String disciplinaNome;
  final int ano;
  final DateTime dataAula;
  final String diaSemana;
  final String horaInicio;
  final String horaFim;
  final bool presente;
  final DateTime? marcadoEm;

  PresencaModel({
    required this.id,
    required this.alunoId,
    required this.disciplinaNome,
    required this.ano,
    required this.dataAula,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
    required this.presente,
    this.marcadoEm,
  });

  factory PresencaModel.fromFirestore(Map<String, dynamic> data, String id) {
    return PresencaModel(
      id: id,
      alunoId: data['alunoId'] ?? '',
      disciplinaNome: data['disciplinaNome'] ?? '',
      ano: data['ano'] ?? 0,
      dataAula: (data['dataAula'] as Timestamp).toDate(),
      diaSemana: data['diaSemana'] ?? '',
      horaInicio: data['horaInicio'] ?? '',
      horaFim: data['horaFim'] ?? '',
      presente: data['presente'] ?? false,
      marcadoEm:
          data['marcadoEm'] != null
              ? (data['marcadoEm'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'alunoId': alunoId,
      'disciplinaNome': disciplinaNome,
      'ano': ano,
      'dataAula': Timestamp.fromDate(dataAula),
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFim': horaFim,
      'presente': presente,
      'marcadoEm': marcadoEm != null ? Timestamp.fromDate(marcadoEm!) : null,
    };
  }
}
