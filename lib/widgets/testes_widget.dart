import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:teacher_app/services/notification_service.dart';
import 'package:teacher_app/session/session.dart';
import '../models/teste_model.dart';
import '../controller/teste_controller.dart';

class TestesWidget extends StatefulWidget {
  final List<TesteModel> testes;
  final String courseId;
  final String disciplinaNome;
  final String professorId;
  final VoidCallback onRefresh;

  const TestesWidget({
    super.key,
    required this.testes,
    required this.courseId,
    required this.disciplinaNome,
    required this.professorId,
    required this.onRefresh,
  });

  @override
  State<TestesWidget> createState() => _TestesWidgetState();
}

class _TestesWidgetState extends State<TestesWidget> {
  final TesteController _testeController = TesteController();

  @override
  Widget build(BuildContext context) {
    // Ordenar testes por data/hora (mais recentes primeiro)
    final testesordenados = List<TesteModel>.from(widget.testes);
    testesordenados.sort((a, b) => b.dataHora.compareTo(a.dataHora));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _adicionarTesteDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Adicionar Teste"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                testesordenados.isEmpty
                    ? Center(
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
                                  Icons.quiz_outlined,
                                  size: 48,
                                  color: Colors.blue.shade300,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhum teste criado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Clique no botão "Adicionar Teste" para criar seu primeiro teste para esta disciplina.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: testesordenados.length,
                      itemBuilder: (context, index) {
                        final teste = testesordenados[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.quiz,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teste.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'editar') {
                                          _editarTesteDialog(teste);
                                        } else if (value == 'remover') {
                                          _removerTeste(teste);
                                        }
                                      },
                                      itemBuilder:
                                          (context) => [
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'remover',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Remover',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (teste.dataHora.isAfter(DateTime.now())) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Agendado para: ${teste.dataHora.day.toString().padLeft(2, '0')}/${teste.dataHora.month.toString().padLeft(2, '0')}/${teste.dataHora.year} às ${teste.dataHora.hour.toString().padLeft(2, '0')}:${teste.dataHora.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 16,
                                          color: Colors.orange.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Realizado em: ${teste.dataHora.day.toString().padLeft(2, '0')}/${teste.dataHora.month.toString().padLeft(2, '0')}/${teste.dataHora.year} às ${teste.dataHora.hour.toString().padLeft(2, '0')}:${teste.dataHora.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _adicionarTesteDialog() async {
    final nomeController = TextEditingController();
    DateTime dataHora = DateTime.now().add(const Duration(days: 1));
    bool loading = false;

    // Buscar disciplinaId
    final coursesSnap =
        await FirebaseFirestore.instance.collection('courses').get();

    normalizar(String s) => removeDiacritics(
      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
    );

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

    if (courseDoc == null) return;
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
      subjectDoc = null;
    }

    if (subjectDoc == null) return;
    final disciplinaId = subjectDoc.id;

    // Gerar próximo nome automático
    final proximoNome = await _testeController.getProximoNomeTeste(
      disciplinaId,
      widget.professorId,
    );
    nomeController.text = proximoNome;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Novo Teste'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Teste',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Data: ${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataHora,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dataHora = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  dataHora.hour,
                                  dataHora.minute,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hora: ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: dataHora.hour,
                                minute: dataHora.minute,
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                dataHora = DateTime(
                                  dataHora.year,
                                  dataHora.month,
                                  dataHora.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : () async {
                            setState(() => loading = true);
                            try {
                              await _testeController.addTeste(
                                nome: nomeController.text,
                                disciplinaId: disciplinaId,
                                professorId: widget.professorId,
                                dataHora: dataHora,
                              );

                              // Enviar notificações para todos os alunos da disciplina
                              final professorName =
                                  Session.currentProfessor?.nome ?? 'Professor';
                              await NotificationService.sendTaskNotificationToStudents(
                                courseId: widget.courseId,
                                disciplinaNome: widget.disciplinaNome,
                                professorName: professorName,
                                taskTitle: nomeController.text,
                                isTest: true,
                              );

                              widget.onRefresh();
                              if (mounted) Navigator.pop(context, true);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao adicionar teste: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                            setState(() => loading = false);
                          },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editarTesteDialog(TesteModel teste) async {
    final nomeController = TextEditingController(text: teste.nome);
    DateTime dataHora = teste.dataHora;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Teste'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Teste',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Data: ${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataHora,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                dataHora = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  dataHora.hour,
                                  dataHora.minute,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Hora: ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: dataHora.hour,
                                minute: dataHora.minute,
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                dataHora = DateTime(
                                  dataHora.year,
                                  dataHora.month,
                                  dataHora.day,
                                  picked.hour,
                                  picked.minute,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : () async {
                            setState(() => loading = true);
                            try {
                              final testeEditado = teste.copyWith(
                                nome: nomeController.text,
                                dataHora: dataHora,
                              );
                              await _testeController.updateTeste(testeEditado);
                              widget.onRefresh();
                              if (mounted) Navigator.pop(context, true);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro ao editar teste: $e'),
                                  ),
                                );
                              }
                            }
                            setState(() => loading = false);
                          },
                  child: const Text("Salvar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removerTeste(TesteModel teste) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text(
            'Tem certeza que deseja remover o teste "${teste.nome}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmacao == true) {
      try {
        await _testeController.deleteTeste(teste.id);
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teste removido com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao remover teste: $e')));
        }
      }
    }
  }
}
