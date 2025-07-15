import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/teste_model.dart';
import '../models/tarefa_model.dart';
import '../models/nota_model.dart';
import '../controller/teste_controller.dart';
import '../controller/tarefa_controller.dart';
import '../controller/nota_controller.dart';

class NotasFinaisWidget extends StatefulWidget {
  final Map<String, String> alunos; // {alunoId: nomeAluno}
  final String disciplinaNome;
  final String professorId;
  final String courseId;

  const NotasFinaisWidget({
    super.key,
    required this.alunos,
    required this.disciplinaNome,
    required this.professorId,
    required this.courseId,
  });

  @override
  State<NotasFinaisWidget> createState() => _NotasFinaisWidgetState();
}

class _NotasFinaisWidgetState extends State<NotasFinaisWidget> {
  final TesteController _testeController = TesteController();
  final TarefaController _tarefaController = TarefaController();
  final NotaController _notaController = NotaController();

  List<TesteModel> testes = [];
  List<TarefaModel> tarefas = [];

  // Notas dos testes: {testeId: {aluno: nota}}
  Map<String, Map<String, double>> notasTestes = {};

  // Notas das tarefas: {tarefaId: {aluno: nota}}
  Map<String, Map<String, double>> notasTarefas = {};

  // Controllers para os campos de texto
  Map<String, Map<String, TextEditingController>> controllersTestesNotas = {};
  Map<String, Map<String, TextEditingController>> controllersTarefasNotas = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    // Limpar todos os controllers
    for (var testeControllers in controllersTestesNotas.values) {
      for (var controller in testeControllers.values) {
        controller.dispose();
      }
    }
    for (var tarefaControllers in controllersTarefasNotas.values) {
      for (var controller in tarefaControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await Future.wait([_carregarTestes(), _carregarTarefas()]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _carregarTestes() async {
    try {
      print('Iniciando carregamento de testes...');
      print('Course ID: ${widget.courseId}');
      print('Disciplina Nome: ${widget.disciplinaNome}');
      print('Professor ID: ${widget.professorId}');

      final disciplinaId = await _getDisciplinaId();
      print('Disciplina ID obtido: $disciplinaId');

      if (disciplinaId == null) {
        print('Disciplina ID é null, abortando carregamento de testes');
        return;
      }

      final lista = await _testeController.getTestes(
        disciplinaId,
        widget.professorId,
      );

      print('Testes carregados: ${lista.length}');

      setState(() {
        testes = lista;
      });

      // Carregar notas existentes para cada teste
      await _carregarNotasTestes(disciplinaId);
    } catch (e) {
      print('Erro ao carregar testes: $e');
    }
  }

  Future<void> _carregarTarefas() async {
    try {
      print('Iniciando carregamento de tarefas...');

      final disciplinaId = await _getDisciplinaId();
      print('Disciplina ID obtido para tarefas: $disciplinaId');

      if (disciplinaId == null) {
        print('Disciplina ID é null, abortando carregamento de tarefas');
        return;
      }

      final lista = await _tarefaController.getTarefas(
        disciplinaId,
        widget.professorId,
      );

      print('Tarefas carregadas: ${lista.length}');

      setState(() {
        tarefas = lista;
      });

      // Carregar notas existentes para cada tarefa
      await _carregarNotasTarefas(disciplinaId);
    } catch (e) {
      print('Erro ao carregar tarefas: $e');
    }
  }

  Future<String?> _getDisciplinaId() async {
    try {
      String normalizar(String s) {
        return removeDiacritics(
          s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
        );
      }

      final coursesSnap =
          await FirebaseFirestore.instance.collection('courses').get();
      final normalizadoCourseId = normalizar(widget.courseId);
      QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc;

      try {
        courseDoc = coursesSnap.docs.firstWhere(
          (doc) =>
              normalizar(doc.id) == normalizadoCourseId ||
              normalizar(doc['name'] ?? '') == normalizadoCourseId,
        );
      } catch (e) {
        try {
          courseDoc = coursesSnap.docs.firstWhere(
            (doc) =>
                normalizar(doc.id).contains(normalizadoCourseId) ||
                normalizar(doc['name'] ?? '').contains(normalizadoCourseId),
          );
        } catch (e) {
          courseDoc = null;
        }
      }

      if (courseDoc == null) {
        print('Curso não encontrado: ${widget.courseId}');
        return null;
      }

      final courseId = courseDoc.id;

      final subjectsSnap =
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(courseId)
              .collection('subjects')
              .get();

      final normalizadoWidgetNome = normalizar(widget.disciplinaNome);
      QueryDocumentSnapshot<Map<String, dynamic>>? subjectDoc;

      try {
        subjectDoc = subjectsSnap.docs.firstWhere(
          (doc) => normalizar(doc['name'] ?? '') == normalizadoWidgetNome,
        );
      } catch (e) {
        print('Disciplina não encontrada: ${widget.disciplinaNome}');
        subjectDoc = null;
      }

      if (subjectDoc == null) {
        return null;
      }

      print('DisciplinaId encontrado: ${subjectDoc.id}');
      return subjectDoc.id;
    } catch (e) {
      print('Erro ao obter disciplinaId: $e');
      return null;
    }
  }

  Future<void> _carregarNotasTestes(String disciplinaId) async {
    try {
      for (var teste in testes) {
        // Inicializar estruturas
        notasTestes[teste.id] = {};
        controllersTestesNotas[teste.id] = {};

        // Buscar notas existentes para este teste
        final notasExistentes = await _notaController.getNotasTeste(
          disciplinaId: disciplinaId,
          testeId: teste.id,
        );

        // Criar mapa de notas existentes por aluno
        final notasPorAluno = <String, double>{};
        for (var nota in notasExistentes) {
          notasPorAluno[nota.alunoId] = nota.nota;
        }

        // Inicializar controllers e notas para cada aluno
        for (var alunoEntry in widget.alunos.entries) {
          final alunoId = alunoEntry.key;
          final notaExistente = notasPorAluno[alunoId] ?? 0.0;
          notasTestes[teste.id]![alunoId] = notaExistente;
          controllersTestesNotas[teste.id]![alunoId] = TextEditingController(
            text: notaExistente == 0.0 ? '' : notaExistente.toString(),
          );
        }
      }
    } catch (e) {
      print('Erro ao carregar notas dos testes: $e');
    }
  }

  Future<void> _carregarNotasTarefas(String disciplinaId) async {
    try {
      for (var tarefa in tarefas) {
        // Inicializar estruturas
        notasTarefas[tarefa.id] = {};
        controllersTarefasNotas[tarefa.id] = {};

        // Buscar notas existentes para esta tarefa
        final notasExistentes = await _notaController.getNotasTarefa(
          disciplinaId: disciplinaId,
          tarefaId: tarefa.id,
        );

        // Criar mapa de notas existentes por aluno
        final notasPorAluno = <String, double>{};
        for (var nota in notasExistentes) {
          notasPorAluno[nota.alunoId] = nota.nota;
        }

        // Inicializar controllers e notas para cada aluno
        for (var alunoEntry in widget.alunos.entries) {
          final alunoId = alunoEntry.key;
          final notaExistente = notasPorAluno[alunoId] ?? 0.0;
          notasTarefas[tarefa.id]![alunoId] = notaExistente;
          controllersTarefasNotas[tarefa.id]![alunoId] = TextEditingController(
            text: notaExistente == 0.0 ? '' : notaExistente.toString(),
          );
        }
      }
    } catch (e) {
      print('Erro ao carregar notas das tarefas: $e');
    }
  }

  // Método para validar e mostrar resumo das notas
  void _validarEMostrarResumo(String id, String nome, bool ehTeste) {
    final alunosSemNota = <String>[];
    final alunosComErro = <String>[];
    final alunosOk = <String>[];

    for (var alunoEntry in widget.alunos.entries) {
      final alunoId = alunoEntry.key;
      final alunoNome = alunoEntry.value;
      TextEditingController? controller;
      double? nota;

      if (ehTeste) {
        controller = controllersTestesNotas[id]?[alunoId];
        nota = notasTestes[id]?[alunoId];
      } else {
        controller = controllersTarefasNotas[id]?[alunoId];
        nota = notasTarefas[id]?[alunoId];
      }

      final textoNota = controller?.text.trim() ?? '';

      if (textoNota.isEmpty || nota == 0.0) {
        alunosSemNota.add(alunoNome);
      } else if (!NotaModel.isNotaValida(nota ?? 0.0)) {
        alunosComErro.add('$alunoNome (${nota ?? 0.0})');
      } else {
        alunosOk.add('$alunoNome (${nota ?? 0.0})');
      }
    }

    // Construir mensagem do resumo
    String titulo = 'Resumo - ${ehTeste ? 'Teste' : 'Tarefa'}: $nome';
    String mensagem = '';

    if (alunosOk.isNotEmpty) {
      mensagem += '✅ Notas válidas (${alunosOk.length}):\n';
      mensagem += alunosOk.join('\n') + '\n\n';
    }

    if (alunosSemNota.isNotEmpty) {
      mensagem += '❌ Sem nota (${alunosSemNota.length}):\n';
      mensagem += alunosSemNota.join(', ') + '\n\n';
    }

    if (alunosComErro.isNotEmpty) {
      mensagem += '⚠️ Notas inválidas (${alunosComErro.length}):\n';
      mensagem += alunosComErro.join('\n') + '\n\n';
    }

    final podeSerSalvo = alunosSemNota.isEmpty && alunosComErro.isEmpty;

    if (podeSerSalvo) {
      mensagem +=
          '🎉 Todas as notas estão preenchidas corretamente!\nPode proceder com o salvamento.';
    } else {
      mensagem += '⚠️ Corrija os problemas antes de salvar.';
    }

    // Mostrar dialog com resumo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(child: Text(mensagem)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            if (podeSerSalvo)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (ehTeste) {
                    final teste = testes.firstWhere((t) => t.id == id);
                    _salvarNotasTeste(teste);
                  } else {
                    final tarefa = tarefas.firstWhere((t) => t.id == id);
                    _salvarNotasTarefa(tarefa);
                  }
                },
                child: const Text('Salvar Agora'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Testes
            _buildTestesSection(),
            const SizedBox(height: 24),

            // Seção de Tarefas
            _buildTarefasSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestesSection() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Text(
          'Testes (${testes.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.quiz),
        children:
            testes.isEmpty
                ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhum teste encontrado para esta disciplina.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ]
                : testes.map((teste) => _buildTesteCard(teste)).toList(),
      ),
    );
  }

  // Método auxiliar para contar notas preenchidas de um teste
  int _contarNotasPreenchidas(String testeId, bool ehTeste) {
    int contador = 0;
    for (var alunoEntry in widget.alunos.entries) {
      final alunoId = alunoEntry.key;
      TextEditingController? controller;
      if (ehTeste) {
        controller = controllersTestesNotas[testeId]?[alunoId];
      } else {
        controller = controllersTarefasNotas[testeId]?[alunoId];
      }

      if ((controller?.text.trim().isNotEmpty) == true) {
        contador++;
      }
    }
    return contador;
  }

  Widget _buildTarefasSection() {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Text(
          'Tarefas (${tarefas.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.assignment),
        children:
            tarefas.isEmpty
                ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhuma tarefa encontrada para esta disciplina.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ]
                : tarefas.map((tarefa) => _buildTarefaCard(tarefa)).toList(),
      ),
    );
  }

  Widget _buildTesteCard(TesteModel teste) {
    final notasPreenchidas = _contarNotasPreenchidas(teste.id, true);
    final totalAlunos = widget.alunos.length;
    final progresso =
        totalAlunos > 0 ? (notasPreenchidas / totalAlunos * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    teste.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progresso == 100 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$notasPreenchidas/$totalAlunos ($progresso%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Data: ${teste.dataHora}'),
            if (progresso < 100) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ ${totalAlunos - notasPreenchidas} aluno(s) sem nota',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...widget.alunos.entries.map((alunoEntry) {
              final alunoId = alunoEntry.key;
              final alunoNome = alunoEntry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Text(alunoNome),
                          const SizedBox(width: 8),
                          // Indicador visual se já tem nota
                          if ((notasTestes[teste.id]?[alunoId] ?? 0.0) > 0.0)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllersTestesNotas[teste.id]?[alunoId],
                        decoration: InputDecoration(
                          labelText: 'Nota (0-20)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTestesNotas[teste.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTestesNotas[teste.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTestesNotas[teste.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          helperText:
                              (controllersTestesNotas[teste.id]?[alunoId]?.text
                                          .trim()
                                          .isEmpty ??
                                      true)
                                  ? 'Obrigatório'
                                  : null,
                          helperStyle: const TextStyle(color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            final nota = double.tryParse(value);
                            if (nota != null) {
                              if (nota >= 0 && nota <= 20) {
                                notasTestes[teste.id]![alunoId] = nota;
                              } else {
                                // Mostrar feedback visual para nota inválida
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Nota deve estar entre 0 e 20',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else if (value.isEmpty) {
                              notasTestes[teste.id]![alunoId] = 0.0;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => _validarEMostrarResumo(teste.id, teste.nome, true),
                  icon: Icon(
                    progresso == 100 ? Icons.check_circle : Icons.warning,
                    color: progresso == 100 ? Colors.green : Colors.orange,
                  ),
                  label: Text(progresso == 100 ? 'Validar' : 'Verificar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        progresso == 100
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      progresso == 100 ? () => _salvarNotasTeste(teste) : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Notas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        progresso == 100 ? null : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportarExcelTeste(teste),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarefaCard(TarefaModel tarefa) {
    final notasPreenchidas = _contarNotasPreenchidas(tarefa.id, false);
    final totalAlunos = widget.alunos.length;
    final progresso =
        totalAlunos > 0 ? (notasPreenchidas / totalAlunos * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tarefa.titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progresso == 100 ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$notasPreenchidas/$totalAlunos ($progresso%)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Data de Entrega: ${tarefa.dataLimite}'),
            if (progresso < 100) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ ${totalAlunos - notasPreenchidas} aluno(s) sem nota',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...widget.alunos.entries.map((alunoEntry) {
              final alunoId = alunoEntry.key;
              final alunoNome = alunoEntry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Text(alunoNome),
                          const SizedBox(width: 8),
                          // Indicador visual se já tem nota
                          if ((notasTarefas[tarefa.id]?[alunoId] ?? 0.0) > 0.0)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            controllersTarefasNotas[tarefa.id]?[alunoId],
                        decoration: InputDecoration(
                          labelText: 'Nota (0-20)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTarefasNotas[tarefa.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTarefasNotas[tarefa.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color:
                                  (controllersTarefasNotas[tarefa.id]?[alunoId]
                                              ?.text
                                              .trim()
                                              .isEmpty ??
                                          true)
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          helperText:
                              (controllersTarefasNotas[tarefa.id]?[alunoId]
                                          ?.text
                                          .trim()
                                          .isEmpty ??
                                      true)
                                  ? 'Obrigatório'
                                  : null,
                          helperStyle: const TextStyle(color: Colors.red),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            final nota = double.tryParse(value);
                            if (nota != null) {
                              if (nota >= 0 && nota <= 20) {
                                notasTarefas[tarefa.id]![alunoId] = nota;
                              } else {
                                // Mostrar feedback visual para nota inválida
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Nota deve estar entre 0 e 20',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else if (value.isEmpty) {
                              notasTarefas[tarefa.id]![alunoId] = 0.0;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => _validarEMostrarResumo(
                        tarefa.id,
                        tarefa.titulo,
                        false,
                      ),
                  icon: Icon(
                    progresso == 100 ? Icons.check_circle : Icons.warning,
                    color: progresso == 100 ? Colors.green : Colors.orange,
                  ),
                  label: Text(progresso == 100 ? 'Validar' : 'Verificar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        progresso == 100
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      progresso == 100
                          ? () => _salvarNotasTarefa(tarefa)
                          : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar Notas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        progresso == 100 ? null : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportarExcelTarefa(tarefa),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarNotasTeste(TesteModel teste) async {
    try {
      final disciplinaId = await _getDisciplinaId();
      if (disciplinaId == null) {
        throw Exception('Disciplina ID não encontrado');
      }

      // Preparar notas para salvar
      final notasPorAluno = <String, double>{};
      final erros = <String>[];
      final alunosSemNota = <String>[];

      for (var alunoEntry in widget.alunos.entries) {
        final alunoId = alunoEntry.key;
        final alunoNome = alunoEntry.value;
        final nota = notasTestes[teste.id]?[alunoId] ?? 0.0;
        final controller = controllersTestesNotas[teste.id]?[alunoId];
        final textoNota = controller?.text.trim() ?? '';

        // Verificar se a nota foi realmente preenchida (não é apenas 0.0 por padrão)
        if (textoNota.isEmpty || nota == 0.0) {
          alunosSemNota.add(alunoNome);
          continue;
        }

        // Validar nota
        if (!NotaModel.isNotaValida(nota)) {
          erros.add('$alunoNome: nota deve estar entre 0 e 20 (atual: $nota)');
          continue;
        }

        notasPorAluno[alunoId] = nota;
      }

      // VALIDAÇÃO OBRIGATÓRIA: Todos os alunos devem ter nota
      if (alunosSemNota.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERRO: Todos os alunos devem ter nota!\n'
              'Alunos sem nota (${alunosSemNota.length}): ${alunosSemNota.join(', ')}\n'
              'Preencha todas as notas antes de salvar.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // Se há erros de validação de notas, mostrar e parar
      if (erros.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erros encontrados:\n${erros.join('\n')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Confirmar que todas as notas foram preenchidas
      if (notasPorAluno.length != widget.alunos.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERRO: Nem todos os alunos têm nota válida!\n'
              'Esperado: ${widget.alunos.length}, Preenchido: ${notasPorAluno.length}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Salvar notas
      final resultados = await _notaController.salvarNotasLote(
        disciplinaId: disciplinaId,
        professorId: widget.professorId,
        notasPorAluno: notasPorAluno,
        testeId: teste.id,
      );

      // Verificar resultados
      final sucessos = resultados.values.where((r) => r).length;
      final falhas = resultados.length - sucessos;

      if (falhas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Todas as notas do teste "${teste.nome}" foram salvas com sucesso!\n'
              '${sucessos}/${resultados.length} alunos avaliados.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notas salvas parcialmente: $sucessos sucessos, $falhas falhas',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar notas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarNotasTarefa(TarefaModel tarefa) async {
    try {
      final disciplinaId = await _getDisciplinaId();
      if (disciplinaId == null) {
        throw Exception('Disciplina ID não encontrado');
      }

      // Preparar notas para salvar
      final notasPorAluno = <String, double>{};
      final erros = <String>[];
      final alunosSemNota = <String>[];

      for (var alunoEntry in widget.alunos.entries) {
        final alunoId = alunoEntry.key;
        final alunoNome = alunoEntry.value;
        final nota = notasTarefas[tarefa.id]?[alunoId] ?? 0.0;
        final controller = controllersTarefasNotas[tarefa.id]?[alunoId];
        final textoNota = controller?.text.trim() ?? '';

        // Verificar se a nota foi realmente preenchida (não é apenas 0.0 por padrão)
        if (textoNota.isEmpty || nota == 0.0) {
          alunosSemNota.add(alunoNome);
          continue;
        }

        // Validar nota
        if (!NotaModel.isNotaValida(nota)) {
          erros.add('$alunoNome: nota deve estar entre 0 e 20 (atual: $nota)');
          continue;
        }

        notasPorAluno[alunoId] = nota;
      }

      // VALIDAÇÃO OBRIGATÓRIA: Todos os alunos devem ter nota
      if (alunosSemNota.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERRO: Todos os alunos devem ter nota!\n'
              'Alunos sem nota (${alunosSemNota.length}): ${alunosSemNota.join(', ')}\n'
              'Preencha todas as notas antes de salvar.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }

      // Se há erros de validação de notas, mostrar e parar
      if (erros.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erros encontrados:\n${erros.join('\n')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Confirmar que todas as notas foram preenchidas
      if (notasPorAluno.length != widget.alunos.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ERRO: Nem todos os alunos têm nota válida!\n'
              'Esperado: ${widget.alunos.length}, Preenchido: ${notasPorAluno.length}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Salvar notas
      final resultados = await _notaController.salvarNotasLote(
        disciplinaId: disciplinaId,
        professorId: widget.professorId,
        notasPorAluno: notasPorAluno,
        tarefaId: tarefa.id,
      );

      // Verificar resultados
      final sucessos = resultados.values.where((r) => r).length;
      final falhas = resultados.length - sucessos;

      if (falhas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Todas as notas da tarefa "${tarefa.titulo}" foram salvas com sucesso!\n'
              '${sucessos}/${resultados.length} alunos avaliados.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notas salvas parcialmente: $sucessos sucessos, $falhas falhas',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar notas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportarExcelTeste(TesteModel teste) async {
    try {
      // Criar um novo arquivo Excel
      final excel = Excel.createExcel();
      final sheet = excel['Notas_Teste'];

      // Remover a sheet padrão se existir
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Configurar cabeçalhos
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Teste: ${teste.nome}',
      );
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Data: ${teste.dataHora}',
      );
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Disciplina: ${widget.disciplinaNome}',
      );

      // Cabeçalhos da tabela
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Aluno');
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('Nota');
      sheet.cell(CellIndex.indexByString('C5')).value = TextCellValue('Status');

      // Estilizar cabeçalhos
      for (String cell in ['A5', 'B5', 'C5']) {
        final cellObj = sheet.cell(CellIndex.indexByString(cell));
        cellObj.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E6E6E6'),
        );
      }

      // Preencher dados dos alunos
      int linha = 6;
      for (var alunoEntry in widget.alunos.entries) {
        final alunoId = alunoEntry.key;
        final alunoNome = alunoEntry.value;
        final nota = notasTestes[teste.id]?[alunoId] ?? 0.0;
        final controller = controllersTestesNotas[teste.id]?[alunoId];
        final temNota =
            (controller?.text.trim().isNotEmpty ?? false) && nota > 0;

        sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
          alunoNome,
        );
        sheet.cell(CellIndex.indexByString('B$linha')).value =
            temNota ? DoubleCellValue(nota) : TextCellValue('Sem nota');
        sheet.cell(CellIndex.indexByString('C$linha')).value = TextCellValue(
          temNota ? 'Avaliado' : 'Pendente',
        );

        // Colorir linha se sem nota
        if (!temNota) {
          for (String col in ['A$linha', 'B$linha', 'C$linha']) {
            sheet.cell(CellIndex.indexByString(col)).cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFCCCC'),
            );
          }
        }

        linha++;
      }

      // Estatísticas
      final notasPreenchidas = _contarNotasPreenchidas(teste.id, true);
      final totalAlunos = widget.alunos.length;

      linha += 2;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'RESUMO:',
      );
      sheet.cell(CellIndex.indexByString('A$linha')).cellStyle = CellStyle(
        bold: true,
      );

      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Total de alunos: $totalAlunos',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Notas lançadas: $notasPreenchidas',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Pendentes: ${totalAlunos - notasPreenchidas}',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Percentual completo: ${(notasPreenchidas / totalAlunos * 100).round()}%',
      );

      // Obter bytes do arquivo Excel
      final excelBytes = excel.save();

      if (excelBytes != null) {
        // Solicitar local de salvamento
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar arquivo Excel',
          fileName: 'notas_teste_${teste.nome.replaceAll(' ', '_')}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(excelBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Excel salvo com sucesso!\nLocal: $result'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Salvamento cancelado pelo usuário'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Falha ao gerar arquivo Excel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao gerar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportarExcelTarefa(TarefaModel tarefa) async {
    try {
      // Criar um novo arquivo Excel
      final excel = Excel.createExcel();
      final sheet = excel['Notas_Tarefa'];

      // Remover a sheet padrão se existir
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Configurar cabeçalhos
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
        'Tarefa: ${tarefa.titulo}',
      );
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'Data de Entrega: ${tarefa.dataLimite}',
      );
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'Disciplina: ${widget.disciplinaNome}',
      );

      // Cabeçalhos da tabela
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Aluno');
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue('Nota');
      sheet.cell(CellIndex.indexByString('C5')).value = TextCellValue('Status');

      // Estilizar cabeçalhos
      for (String cell in ['A5', 'B5', 'C5']) {
        final cellObj = sheet.cell(CellIndex.indexByString(cell));
        cellObj.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E6E6E6'),
        );
      }

      // Preencher dados dos alunos
      int linha = 6;
      for (var alunoEntry in widget.alunos.entries) {
        final alunoId = alunoEntry.key;
        final alunoNome = alunoEntry.value;
        final nota = notasTarefas[tarefa.id]?[alunoId] ?? 0.0;
        final controller = controllersTarefasNotas[tarefa.id]?[alunoId];
        final temNota =
            (controller?.text.trim().isNotEmpty ?? false) && nota > 0;

        sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
          alunoNome,
        );
        sheet.cell(CellIndex.indexByString('B$linha')).value =
            temNota ? DoubleCellValue(nota) : TextCellValue('Sem nota');
        sheet.cell(CellIndex.indexByString('C$linha')).value = TextCellValue(
          temNota ? 'Avaliado' : 'Pendente',
        );

        // Colorir linha se sem nota
        if (!temNota) {
          for (String col in ['A$linha', 'B$linha', 'C$linha']) {
            sheet.cell(CellIndex.indexByString(col)).cellStyle = CellStyle(
              backgroundColorHex: ExcelColor.fromHexString('#FFCCCC'),
            );
          }
        }

        linha++;
      }

      // Estatísticas
      final notasPreenchidas = _contarNotasPreenchidas(tarefa.id, false);
      final totalAlunos = widget.alunos.length;

      linha += 2;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'RESUMO:',
      );
      sheet.cell(CellIndex.indexByString('A$linha')).cellStyle = CellStyle(
        bold: true,
      );

      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Total de alunos: $totalAlunos',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Notas lançadas: $notasPreenchidas',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Pendentes: ${totalAlunos - notasPreenchidas}',
      );
      linha++;
      sheet.cell(CellIndex.indexByString('A$linha')).value = TextCellValue(
        'Percentual completo: ${(notasPreenchidas / totalAlunos * 100).round()}%',
      );

      // Obter bytes do arquivo Excel
      final excelBytes = excel.save();

      if (excelBytes != null) {
        // Solicitar local de salvamento
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar arquivo Excel',
          fileName: 'notas_tarefa_${tarefa.titulo.replaceAll(' ', '_')}.xlsx',
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(excelBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Excel salvo com sucesso!\nLocal: $result'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Salvamento cancelado pelo usuário'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Falha ao gerar arquivo Excel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao gerar Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
