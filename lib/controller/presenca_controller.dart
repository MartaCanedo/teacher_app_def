import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/presenca_model.dart';
import '../models/horario_model.dart';

class PresencaController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar horários para uma disciplina específica e ano
  Future<List<HorarioModel>> getHorarios(String disciplinaNome, int ano) async {
    try {
      print('Buscando horários para disciplina: $disciplinaNome, ano: $ano');
      final querySnapshot = await _firestore.collection('horarios').get();

      // Filtrar horários manualmente para maior flexibilidade
      final List<HorarioModel> horariosFiltrados = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Analisando documento: ${doc.id}, dados: $data');

          // Verificar se tem o campo aulasPorAno
          if (data['aulasPorAno'] != null) {
            final aulasPorAnoRaw = data['aulasPorAno'];
            print('Tipo de aulasPorAno: ${aulasPorAnoRaw.runtimeType}');
            print('Conteúdo aulasPorAno: $aulasPorAnoRaw');

            // Verificar se é um Map (estrutura esperada)
            if (aulasPorAnoRaw is Map<String, dynamic>) {
              final aulasPorAno = aulasPorAnoRaw;

              // Verificar se existe o ano especificado
              final anoString = ano.toString();
              if (aulasPorAno.containsKey(anoString)) {
                final aulasAnoRaw = aulasPorAno[anoString];
                if (aulasAnoRaw == null) continue;

                print(
                  'Processando ano $anoString, tipo: ${aulasAnoRaw.runtimeType}',
                );
                print('Conteúdo do ano: $aulasAnoRaw');

                // O valor do ano é uma Lista de aulas, não um Map
                if (aulasAnoRaw is List<dynamic>) {
                  final aulasArray = aulasAnoRaw;

                  for (int index = 0; index < aulasArray.length; index++) {
                    try {
                      final aula = aulasArray[index];
                      final aulaMap = aula as Map<String, dynamic>?;
                      if (aulaMap == null) continue;

                      final disciplinaAula = aulaMap['disciplina'] as String?;
                      if (disciplinaAula == disciplinaNome) {
                        final diaSemanaAula = aulaMap['diaSemana'] as String?;

                        final horario = HorarioModel(
                          id: '${doc.id}_${anoString}_$index',
                          disciplinaNome: disciplinaAula ?? '',
                          ano: ano,
                          diaSemana: diaSemanaAula ?? 'Segunda',
                          horaInicio:
                              (aulaMap['horaInicio'] as String?) ?? '08:00',
                          horaFim: (aulaMap['horaFim'] as String?) ?? '09:00',
                        );

                        horariosFiltrados.add(horario);
                        print(
                          'Horário encontrado: ${horario.disciplinaNome} - ${horario.diaSemana} ${horario.horaInicio}-${horario.horaFim}',
                        );
                      }
                    } catch (e) {
                      print('Erro ao processar aula individual: $e');
                      continue;
                    }
                  }
                } else {
                  print(
                    'Estrutura inesperada para ano $anoString: ${aulasAnoRaw.runtimeType}',
                  );
                }
              }
            } else if (aulasPorAnoRaw is List<dynamic>) {
              // Se aulasPorAno for uma lista, tentar processar de forma diferente
              print('aulasPorAno é uma lista, tentando processar...');

              final aulasList = aulasPorAnoRaw;

              for (var item in aulasList) {
                try {
                  if (item is Map<String, dynamic>) {
                    // Verificar se este item tem o ano que estamos procurando
                    final itemAno = item['ano'];
                    if (itemAno != null &&
                        itemAno.toString() == ano.toString()) {
                      print('Encontrado item para ano $ano: $item');

                      // Agora processar os dias da semana dentro deste item de ano
                      for (var key in item.keys) {
                        if (key == 'ano') continue; // Pular o campo 'ano'

                        try {
                          final aulasArrayRaw = item[key];
                          if (aulasArrayRaw == null) continue;

                          final aulasArray = aulasArrayRaw as List<dynamic>?;
                          if (aulasArray == null) continue;

                          for (var aula in aulasArray) {
                            try {
                              final aulaMap = aula as Map<String, dynamic>?;
                              if (aulaMap == null) continue;

                              final disciplinaAula =
                                  aulaMap['disciplina'] as String?;
                              if (disciplinaAula == disciplinaNome) {
                                // Mapear dia numérico para nome do dia
                                final Map<String, String> diasSemana = {
                                  '0': 'Segunda',
                                  '1': 'Terça',
                                  '2': 'Quarta',
                                  '3': 'Quinta',
                                  '4': 'Sexta',
                                  '5': 'Sábado',
                                  '6': 'Domingo',
                                };

                                final horario = HorarioModel(
                                  id: '${doc.id}_${key}',
                                  disciplinaNome: disciplinaAula ?? '',
                                  ano: ano,
                                  diaSemana: diasSemana[key] ?? 'Segunda',
                                  horaInicio:
                                      (aulaMap['horaInicio'] as String?) ??
                                      '08:00',
                                  horaFim:
                                      (aulaMap['horaFim'] as String?) ??
                                      '09:00',
                                );

                                horariosFiltrados.add(horario);
                                print(
                                  'Horário encontrado (Lista): ${horario.disciplinaNome} - ${horario.diaSemana} ${horario.horaInicio}-${horario.horaFim}',
                                );
                              }
                            } catch (e) {
                              print(
                                'Erro ao processar aula individual (Lista): $e',
                              );
                              continue;
                            }
                          }
                        } catch (e) {
                          print('Erro ao processar dia $key (Lista): $e');
                          continue;
                        }
                      }
                    }
                  }
                } catch (e) {
                  print('Erro ao processar item da lista: $e');
                  continue;
                }
              }
            } else {
              print(
                'Tipo de aulasPorAno não reconhecido: ${aulasPorAnoRaw.runtimeType}',
              );
            }
          }
        } catch (e) {
          print('Erro ao processar documento ${doc.id}: $e');
          continue;
        }
      }

      print('Total de horários encontrados: ${horariosFiltrados.length}');
      return horariosFiltrados;
    } catch (e) {
      print('Erro ao buscar horários: $e');
      return [];
    }
  }

  // Gerar datas de aula desde março até hoje para uma disciplina
  List<DateTime> gerarDatasAula(HorarioModel horario) {
    final List<DateTime> datas = [];
    final inicioMarco = DateTime(DateTime.now().year, 3, 1); // 1º de março
    final hoje = DateTime.now();

    // Mapear dia da semana para número
    final Map<String, int> diasSemana = {
      'Segunda': 1,
      'Terça': 2,
      'Quarta': 3,
      'Quinta': 4,
      'Sexta': 5,
      'Sábado': 6,
      'Domingo': 7,
    };

    final diaSemanaNum = diasSemana[horario.diaSemana];
    if (diaSemanaNum == null) return datas;

    // Encontrar a primeira ocorrência do dia da semana em março
    DateTime data = inicioMarco;
    while (data.weekday != diaSemanaNum) {
      data = data.add(const Duration(days: 1));
    }

    // Adicionar todas as datas até hoje
    while (data.isBefore(hoje) || data.isAtSameMomentAs(hoje)) {
      // Verificar se a aula já passou (comparando com hora atual)
      final agora = DateTime.now();
      final horaAula = _parseHora(horario.horaFim);
      final dataHoraAula = DateTime(
        data.year,
        data.month,
        data.day,
        horaAula.hour,
        horaAula.minute,
      );

      if (dataHoraAula.isBefore(agora)) {
        datas.add(data);
      }

      data = data.add(const Duration(days: 7)); // Próxima semana
    }

    return datas;
  }

  TimeOfDay _parseHora(String hora) {
    try {
      if (hora.isEmpty) {
        return const TimeOfDay(hour: 23, minute: 59); // Hora padrão
      }

      final parts = hora.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 23;
        final minute = int.tryParse(parts[1]) ?? 59;
        return TimeOfDay(hour: hour, minute: minute);
      }

      return const TimeOfDay(hour: 23, minute: 59); // Hora padrão
    } catch (e) {
      print('Erro ao fazer parse da hora "$hora": $e');
      return const TimeOfDay(hour: 23, minute: 59); // Hora padrão
    }
  }

  // Buscar presença de um aluno em uma data específica
  Future<PresencaModel?> getPresenca(
    String alunoId,
    String disciplinaNome,
    int ano,
    DateTime dataAula,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('presencas')
              .where('alunoId', isEqualTo: alunoId)
              .where('disciplinaNome', isEqualTo: disciplinaNome)
              .where('ano', isEqualTo: ano)
              .where('dataAula', isEqualTo: Timestamp.fromDate(dataAula))
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return PresencaModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar presença: $e');
      return null;
    }
  }

  // Marcar presença (presente ou ausente)
  Future<void> marcarPresenca(
    String alunoId,
    String disciplinaNome,
    int ano,
    DateTime dataAula,
    String diaSemana,
    String horaInicio,
    String horaFim,
    bool presente,
  ) async {
    try {
      // Verificar se já existe presença para esta data
      final presencaExistente = await getPresenca(
        alunoId,
        disciplinaNome,
        ano,
        dataAula,
      );

      final dadosPresenca = {
        'alunoId': alunoId,
        'disciplinaNome': disciplinaNome,
        'ano': ano,
        'dataAula': Timestamp.fromDate(dataAula),
        'diaSemana': diaSemana,
        'horaInicio': horaInicio,
        'horaFim': horaFim,
        'presente': presente,
        'marcadoEm': Timestamp.fromDate(DateTime.now()),
      };

      if (presencaExistente != null) {
        // Atualizar presença existente
        await _firestore
            .collection('presencas')
            .doc(presencaExistente.id)
            .update(dadosPresenca);
      } else {
        // Criar nova presença
        await _firestore.collection('presencas').add(dadosPresenca);
      }
    } catch (e) {
      print('Erro ao marcar presença: $e');
      throw e;
    }
  }

  // Buscar todas as presenças de uma disciplina em uma data específica
  Future<Map<String, PresencaModel>> getPresencasPorData(
    String disciplinaNome,
    int ano,
    DateTime dataAula,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('presencas')
              .where('disciplinaNome', isEqualTo: disciplinaNome)
              .where('ano', isEqualTo: ano)
              .where('dataAula', isEqualTo: Timestamp.fromDate(dataAula))
              .get();

      final Map<String, PresencaModel> presencas = {};
      for (var doc in querySnapshot.docs) {
        final presenca = PresencaModel.fromFirestore(doc.data(), doc.id);
        presencas[presenca.alunoId] = presenca;
      }

      return presencas;
    } catch (e) {
      print('Erro ao buscar presenças por data: $e');
      return {};
    }
  }
}
