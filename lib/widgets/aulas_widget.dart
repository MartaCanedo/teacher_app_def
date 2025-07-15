import 'package:flutter/material.dart';
import '../models/horario_model.dart';
import '../models/presenca_model.dart';
import '../controller/presenca_controller.dart';

class AulasWidget extends StatefulWidget {
  final Map<String, String> alunos; // {alunoId: nomeAluno}
  final String disciplinaNome;
  final int ano;

  const AulasWidget({
    super.key,
    required this.alunos,
    required this.disciplinaNome,
    required this.ano,
  });

  @override
  State<AulasWidget> createState() => _AulasWidgetState();
}

class _AulasWidgetState extends State<AulasWidget> {
  final PresencaController _presencaController = PresencaController();
  List<HorarioModel> horarios = [];
  Map<DateTime, HorarioModel> aulasPassadas = {};
  Map<String, Map<String, PresencaModel>> presencas =
      {}; // data -> {alunoId -> presenca}
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);

    try {
      print(
        'Carregando dados para disciplina: ${widget.disciplinaNome}, ano: ${widget.ano}',
      );

      // Buscar horários da disciplina
      horarios = await _presencaController.getHorarios(
        widget.disciplinaNome,
        widget.ano,
      );

      print('Horários encontrados: ${horarios.length}');

      // Gerar datas de aulas passadas
      aulasPassadas.clear();
      for (final horario in horarios) {
        try {
          final datas = _presencaController.gerarDatasAula(horario);
          print(
            'Horário ${horario.diaSemana} ${horario.horaInicio}-${horario.horaFim}: ${datas.length} datas geradas',
          );
          for (final data in datas) {
            aulasPassadas[data] = horario;
          }
        } catch (e) {
          print('Erro ao gerar datas para horário ${horario.id}: $e');
        }
      }

      print('Total de aulas passadas: ${aulasPassadas.length}');

      // Carregar presenças para cada data
      for (final data in aulasPassadas.keys) {
        try {
          final presencasData = await _presencaController.getPresencasPorData(
            widget.disciplinaNome,
            widget.ano,
            data,
          );
          presencas[_formatarData(data)] = presencasData;
        } catch (e) {
          print('Erro ao carregar presenças para data $data: $e');
        }
      }
    } catch (e) {
      print('Erro ao carregar dados das aulas: $e');
    }

    setState(() => loading = false);
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDiaSemana(DateTime data) {
    const diasSemana = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    return diasSemana[data.weekday % 7];
  }

  Future<void> _marcarPresenca(
    DateTime dataAula,
    String alunoId,
    bool presente,
  ) async {
    try {
      final horario = aulasPassadas[dataAula];
      if (horario == null) return;

      await _presencaController.marcarPresenca(
        alunoId,
        widget.disciplinaNome,
        widget.ano,
        dataAula,
        horario.diaSemana,
        horario.horaInicio,
        horario.horaFim,
        presente,
      );

      // Atualizar estado local
      final dataFormatada = _formatarData(dataAula);
      setState(() {
        if (presencas[dataFormatada] == null) {
          presencas[dataFormatada] = {};
        }
        presencas[dataFormatada]![alunoId] = PresencaModel(
          id: '',
          alunoId: alunoId,
          disciplinaNome: widget.disciplinaNome,
          ano: widget.ano,
          dataAula: dataAula,
          diaSemana: horario.diaSemana,
          horaInicio: horario.horaInicio,
          horaFim: horario.horaFim,
          presente: presente,
          marcadoEm: DateTime.now(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            presente
                ? 'Presença marcada com sucesso!'
                : 'Falta marcada com sucesso!',
          ),
          backgroundColor: presente ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar presença: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (aulasPassadas.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 48,
                    color: Colors.blue.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma aula encontrada',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não foram encontradas aulas passadas para esta disciplina desde março.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ordenar aulas por data (mais recente primeiro)
    final aulasOrdenadas =
        aulasPassadas.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aulasOrdenadas.length,
      itemBuilder: (context, index) {
        final entrada = aulasOrdenadas[index];
        final dataAula = entrada.key;
        final horario = entrada.value;
        final dataFormatada = _formatarData(dataAula);
        final diaSemana = _formatarDiaSemana(dataAula);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              '$diaSemana - $dataFormatada',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              '${horario.horaInicio} - ${horario.horaFim}',
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
            children: [
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Presenças dos Alunos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.alunos.entries.map((alunoEntry) {
                        final alunoId = alunoEntry.key;
                        final alunoNome = alunoEntry.value;
                        final presencaAluno =
                            presencas[dataFormatada]?[alunoId];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alunoNome,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Status atual
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      presencaAluno?.presente == true
                                          ? Colors.green.shade200
                                          : presencaAluno?.presente == false
                                          ? Colors.red.shade200
                                          : Colors.grey.shade500,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  presencaAluno?.presente == true
                                      ? 'Presente'
                                      : presencaAluno?.presente == false
                                      ? 'Ausente'
                                      : 'Não marcado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        presencaAluno?.presente == true
                                            ? Colors.green.shade900
                                            : presencaAluno?.presente == false
                                            ? Colors.red.shade900
                                            : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botões de presença
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed:
                                        () => _marcarPresenca(
                                          dataAula,
                                          alunoId,
                                          true,
                                        ),
                                    icon: Icon(
                                      Icons.check_circle,
                                      color:
                                          presencaAluno?.presente == true
                                              ? Colors.green
                                              : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                    tooltip: 'Marcar presente',
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => _marcarPresenca(
                                          dataAula,
                                          alunoId,
                                          false,
                                        ),
                                    icon: Icon(
                                      Icons.close,
                                      color:
                                          presencaAluno?.presente == false
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                      size: 24,
                                    ),
                                    tooltip: 'Marcar ausente',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
