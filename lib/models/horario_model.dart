class HorarioModel {
  final String id;
  final String disciplinaNome;
  final int ano;
  final String diaSemana;
  final String horaInicio;
  final String horaFim;

  HorarioModel({
    required this.id,
    required this.disciplinaNome,
    required this.ano,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
  });

  factory HorarioModel.fromFirestore(Map<String, dynamic> data, String id) {
    return HorarioModel(
      id: id,
      disciplinaNome: data['disciplinaNome'] ?? '',
      ano: data['ano'] ?? 0,
      diaSemana: data['diaSemana'] ?? '',
      horaInicio: data['horaInicio'] ?? '',
      horaFim: data['horaFim'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'disciplinaNome': disciplinaNome,
      'ano': ano,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFim': horaFim,
    };
  }
}
