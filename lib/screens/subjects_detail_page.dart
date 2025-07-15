import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_app/services/notification_service.dart';
import 'package:teacher_app/session/session.dart';
import '../controller/material_controller.dart';
import '../models/material_model.dart';
import '../widgets/materiais_widget.dart';
import '../controller/tarefa_controller.dart';
import '../models/tarefa_model.dart';
import '../controller/teste_controller.dart';
import '../models/teste_model.dart';
import '../widgets/alunos_widget.dart';
import '../widgets/aulas_widget.dart';
import '../widgets/tarefas_widget.dart';
import '../widgets/testes_widget.dart';
import '../widgets/notas_finais_widget.dart';

class DisciplinaDetalhePage extends StatefulWidget {
  final String nome;
  final String codigo;
  final String semestre;
  final String ano;
  final String courseId;
  final int courseYear;
  final String professorId;

  const DisciplinaDetalhePage({
    super.key,
    required this.nome,
    required this.codigo,
    required this.semestre,
    required this.ano,
    required this.courseId,
    required this.courseYear,
    required this.professorId,
  });

  @override
  State<DisciplinaDetalhePage> createState() => _DisciplinaDetalhePageState();
}

class _DisciplinaDetalhePageState extends State<DisciplinaDetalhePage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  Map<String, String> alunosMap = {}; // {alunoId: nomeAluno}
  int disciplinaAno = 0; // Ano da disciplina baseado nos alunos
  List<MaterialModel> materiais = [];
  List<TarefaModel> tarefas = [];
  List<TesteModel> testes = [];
  final MaterialController _materialController = MaterialController();
  final TarefaController _tarefaController = TarefaController();
  final TesteController _testeController = TesteController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _buscarAlunos();
    _buscarMateriais();
    _buscarTarefas();
    _buscarTestes();
  }

  Future<void> _buscarTarefas() async {
    try {
      print('=== _buscarTarefas iniciado ===');
      print('CourseId: ${widget.courseId}');
      print('Disciplina nome: ${widget.nome}');
      print('Professor ID: ${widget.professorId}');

      final disciplinaId = await _getDisciplinaId();
      print('Disciplina ID encontrado: $disciplinaId');

      if (disciplinaId == null) {
        print('ERRO: disciplinaId é null, abortando busca');
        return;
      }

      final lista = await _tarefaController.getTarefas(
        disciplinaId,
        widget.professorId,
      );

      print('Tarefas encontradas: ${lista.length}');
      for (final tarefa in lista) {
        print('- ${tarefa.titulo} (${tarefa.id})');
      }

      setState(() {
        tarefas = lista;
      });

      print('State atualizado com ${tarefas.length} tarefas');
    } catch (e) {
      print('Erro ao buscar tarefas: $e');
      setState(() {
        tarefas = [];
      });
    }
  }

  Future<void> _buscarMateriais() async {
    try {
      final disciplinaId = await _getDisciplinaId();
      if (disciplinaId == null) return;

      final lista = await _materialController.getMateriais(
        disciplinaId,
        widget.professorId,
      );

      setState(() {
        materiais = lista;
      });
    } catch (e) {
      print('Erro em _buscarMateriais: $e');
      setState(() {
        materiais = [];
      });
    }
  }

  Future<void> _buscarAlunos() async {
    // Busca alunos inscritos na disciplina, considerando courseId e year, cruzando as coleções courses/{courseId}/subjects e students
    print('Buscando alunos para disciplina: ${widget.nome}');
    try {
      String normalizar(String s) {
        return removeDiacritics(
          s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
        );
      }

      // 1. Buscar a disciplina em todos os cursos se courseId estiver vazio ou não encontrado
      final coursesSnap =
          await FirebaseFirestore.instance.collection('courses').get();

      QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc;
      QueryDocumentSnapshot<Map<String, dynamic>>? subjectDoc;

      // Se courseId foi fornecido, tentar primeiro com ele
      if (widget.courseId.isNotEmpty) {
        final normalizadoCourseId = normalizar(widget.courseId);
        try {
          courseDoc = coursesSnap.docs.firstWhere(
            (doc) =>
                normalizar(doc.id) == normalizadoCourseId ||
                normalizar(doc['name'] ?? '') == normalizadoCourseId,
          );
        } catch (e) {
          // Tenta casar por substring (caso o nome do curso seja parte do id ou vice-versa)
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

        if (courseDoc != null) {
          // Buscar a disciplina dentro deste curso
          final subjectsSnap =
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseDoc.id)
                  .collection('subjects')
                  .get();
          final normalizadoWidgetNome = normalizar(widget.nome);
          try {
            subjectDoc = subjectsSnap.docs.firstWhere(
              (doc) => normalizar(doc['name'] ?? '') == normalizadoWidgetNome,
            );
          } catch (e) {
            subjectDoc = null;
          }
        }
      }

      // Se não encontrou com courseId ou courseId estava vazio, buscar em todos os cursos
      if (courseDoc == null || subjectDoc == null) {
        print(
          'Fazendo busca ampla em todos os cursos para disciplina: ${widget.nome}',
        );
        final normalizadoWidgetNome = normalizar(widget.nome);

        for (final course in coursesSnap.docs) {
          final subjectsSnap =
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(course.id)
                  .collection('subjects')
                  .get();

          for (final subject in subjectsSnap.docs) {
            final subjectName = subject['name'] ?? '';
            if (normalizar(subjectName) == normalizadoWidgetNome) {
              courseDoc = course;
              subjectDoc = subject;
              print(
                'Disciplina encontrada no curso: ${course.id} (${course['name']})',
              );
              break;
            }
          }
          if (courseDoc != null && subjectDoc != null) break;
        }
      }

      if (courseDoc == null || subjectDoc == null) {
        print('Disciplina "${widget.nome}" não encontrada em nenhum curso');
        setState(() {
          alunosMap = {};
        });
        return;
      }

      final courseId = courseDoc.id;
      final subject = subjectDoc.data();
      final int subjectCourseYear = subject['courseYear'] ?? 0;

      // 3. Buscar alunos do mesmo courseId e year
      // Buscar alunos tanto por courseId igual ao id quanto ao nome do curso
      final studentsSnap =
          await FirebaseFirestore.instance
              .collection('students')
              .where('courseId', whereIn: [courseId, courseDoc['name']])
              .where('year', isEqualTo: subjectCourseYear)
              .get();

      print('Curso encontrado: $courseId (${courseDoc['name']})');
      print('Ano da disciplina: $subjectCourseYear');
      print('Quantidade de alunos encontrados: ${studentsSnap.docs.length}');
      for (var doc in studentsSnap.docs) {
        print('Aluno: ${doc.data()}');
      }
      setState(() {
        // Criar mapa com ID e nome para todos os widgets
        alunosMap = {
          for (var doc in studentsSnap.docs) doc.id: doc['nome'] as String,
        };
        disciplinaAno = subjectCourseYear; // Atualiza o ano da disciplina
      });
    } catch (e) {
      print('Erro ao buscar alunos: $e');
      setState(() {
        alunosMap = {};
      });
    }
  }

  Future<void> _buscarTestes() async {
    try {
      final disciplinaId = await _getDisciplinaId();
      if (disciplinaId == null) return;

      final lista = await _testeController.getTestes(
        disciplinaId,
        widget.professorId,
      );

      setState(() {
        testes = lista;
      });
    } catch (e) {
      print('Erro ao buscar testes: $e');
      setState(() {
        testes = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // <- força retorno de "houve alteração"
        return false; // impede o pop automático padrão
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[700],
          title: Text(widget.nome, style: TextStyle(color: Colors.white)),
          iconTheme: IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Alunos'),
              Tab(text: 'Aulas'),
              Tab(text: 'Materiais'),
              Tab(text: 'Tarefas'),
              Tab(text: 'Testes'),
              Tab(text: 'Notas Finais'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAlunos(),
            _buildAulas(),
            _buildMateriais(),
            _buildTarefas(isTeste: false),
            _buildTestes(),
            _buildNotasFinais(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunos() {
    return AlunosWidget(alunos: alunosMap);
  }

  Widget _buildAulas() {
    return AulasWidget(
      alunos: alunosMap,
      disciplinaNome: widget.nome,
      ano: disciplinaAno,
    );
  }

  Widget _buildMateriais() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _adicionarMaterialDialog,
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Material"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: MateriaisWidget(
            materiais: materiais,
            onEditar: (material) => _editarMaterialDialog(material),
            onRemover: (material) => _removerMaterial(material),
          ),
        ),
      ],
    ),
  );

  Widget _buildTarefas({required bool isTeste}) {
    return TarefasWidget(
      tarefas: tarefas,
      alunos: alunosMap,
      isTeste: isTeste,
      courseId: widget.courseId,
      disciplinaNome: widget.nome,
      professorId: widget.professorId,
      onRefresh: _buscarTarefas,
    );
  }

  Widget _buildTestes() {
    return TestesWidget(
      testes: testes,
      courseId: widget.courseId,
      disciplinaNome: widget.nome,
      professorId: widget.professorId,
      onRefresh: _buscarTestes,
    );
  }

  Widget _buildNotasFinais() {
    return NotasFinaisWidget(
      alunos: alunosMap,
      disciplinaNome: widget.nome,
      professorId: widget.professorId,
      courseId: widget.courseId,
    );
  }

  Future<String?> _getDisciplinaId() async {
    try {
      String normalizar(String s) => removeDiacritics(
        s.toLowerCase().replaceAll(RegExp(r'\\s+'), ' ').trim(),
      );

      final coursesSnap =
          await FirebaseFirestore.instance.collection('courses').get();

      QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc;
      QueryDocumentSnapshot<Map<String, dynamic>>? subjectDoc;

      // Se courseId foi fornecido, tentar primeiro com ele
      if (widget.courseId.isNotEmpty) {
        final normalizadoCourseId = normalizar(widget.courseId);
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

        if (courseDoc != null) {
          final subjectsSnap =
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(courseDoc.id)
                  .collection('subjects')
                  .get();
          final normalizadoWidgetNome = normalizar(widget.nome);
          try {
            subjectDoc = subjectsSnap.docs.firstWhere(
              (doc) => normalizar(doc['name'] ?? '') == normalizadoWidgetNome,
            );
          } catch (e) {
            subjectDoc = null;
          }
        }
      }

      // Se não encontrou com courseId ou courseId estava vazio, buscar em todos os cursos
      if (courseDoc == null || subjectDoc == null) {
        final normalizadoWidgetNome = normalizar(widget.nome);

        for (final course in coursesSnap.docs) {
          final subjectsSnap =
              await FirebaseFirestore.instance
                  .collection('courses')
                  .doc(course.id)
                  .collection('subjects')
                  .get();

          for (final subject in subjectsSnap.docs) {
            final subjectName = subject['name'] ?? '';
            if (normalizar(subjectName) == normalizadoWidgetNome) {
              subjectDoc = subject;
              break;
            }
          }
          if (subjectDoc != null) break;
        }
      }

      if (subjectDoc == null) {
        return null;
      }

      return subjectDoc.id;
    } catch (e) {
      print('Erro ao obter disciplinaId: $e');
      return null;
    }
  }

  void _adicionarMaterialDialog() async {
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();
    File? file;
    String? nomeArquivo;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 80,
                vertical: 60,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Novo Material',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tituloController,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                          maxHeight: 180,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: descricaoController,
                              maxLines: null,
                              minLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed:
                            loading
                                ? null
                                : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles();
                                  if (result != null &&
                                      result.files.single.path != null) {
                                    setState(() {
                                      file = File(result.files.single.path!);
                                      nomeArquivo = result.files.single.name;
                                    });
                                  }
                                },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Selecionar Ficheiro'),
                      ),
                      if (file != null && nomeArquivo != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nomeArquivo!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Remover ficheiro',
                              onPressed:
                                  loading
                                      ? null
                                      : () {
                                        setState(() {
                                          file = null;
                                          nomeArquivo = null;
                                        });
                                      },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                loading
                                    ? null
                                    : () async {
                                      if (tituloController.text.isEmpty ||
                                          file == null ||
                                          nomeArquivo == null) {
                                        return;
                                      }
                                      setState(() {
                                        loading = true;
                                      });
                                      try {
                                        // Buscar disciplinaId (subjectId)
                                        final coursesSnap =
                                            await FirebaseFirestore.instance
                                                .collection('courses')
                                                .get();
                                        normalizar(String s) =>
                                            removeDiacritics(
                                              s
                                                  .toLowerCase()
                                                  .replaceAll(
                                                    RegExp(r'\\s+'),
                                                    ' ',
                                                  )
                                                  .trim(),
                                            );
                                        final normalizadoCourseId = normalizar(
                                          widget.courseId,
                                        );
                                        QueryDocumentSnapshot<
                                          Map<String, dynamic>
                                        >?
                                        courseDoc;
                                        try {
                                          courseDoc = coursesSnap.docs
                                              .firstWhere(
                                                (doc) =>
                                                    normalizar(doc.id) ==
                                                        normalizadoCourseId ||
                                                    normalizar(
                                                          doc['name'] ?? '',
                                                        ) ==
                                                        normalizadoCourseId,
                                              );
                                        } catch (e) {
                                          try {
                                            courseDoc = coursesSnap.docs
                                                .firstWhere(
                                                  (doc) =>
                                                      normalizar(
                                                        doc.id,
                                                      ).contains(
                                                        normalizadoCourseId,
                                                      ) ||
                                                      normalizar(
                                                        doc['name'] ?? '',
                                                      ).contains(
                                                        normalizadoCourseId,
                                                      ),
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
                                        final normalizadoWidgetNome =
                                            normalizar(widget.nome);
                                        QueryDocumentSnapshot<
                                          Map<String, dynamic>
                                        >?
                                        subjectDoc;
                                        try {
                                          subjectDoc = subjectsSnap.docs
                                              .firstWhere(
                                                (doc) =>
                                                    normalizar(
                                                      doc['name'] ?? '',
                                                    ) ==
                                                    normalizadoWidgetNome,
                                              );
                                        } catch (e) {
                                          subjectDoc = null;
                                        }
                                        if (subjectDoc == null) return;
                                        final disciplinaId = subjectDoc.id;
                                        await _materialController.addMaterial(
                                          titulo: tituloController.text,
                                          descricao: descricaoController.text,
                                          file: file!,
                                          disciplinaId: disciplinaId,
                                          nomeArquivo: nomeArquivo!,
                                          professorId: widget.professorId,
                                        );

                                        // Enviar notificações para todos os alunos da disciplina
                                        final professorName =
                                            Session.currentProfessor?.nome ??
                                            'Professor';
                                        await NotificationService.sendMaterialNotificationToStudents(
                                          courseId: widget.courseId,
                                          disciplinaNome: widget.nome,
                                          professorName: professorName,
                                          materialTitle: tituloController.text,
                                        );

                                        await _buscarMateriais();
                                        if (mounted) Navigator.pop(context);
                                      } catch (e) {
                                        print('Erro ao salvar material: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erro ao salvar material: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => loading = false);
                                        }
                                      }
                                    },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editarMaterialDialog(MaterialModel material) async {
    final tituloController = TextEditingController(text: material.titulo);
    final descricaoController = TextEditingController(text: material.descricao);
    File? novoArquivo;
    String? novoNomeArquivo;
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 80,
                vertical: 60,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Editar Material',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: tituloController,
                        decoration: const InputDecoration(labelText: 'Título'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                          maxHeight: 180,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: descricaoController,
                              maxLines: null,
                              minLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed:
                            loading
                                ? null
                                : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles();
                                  if (result != null &&
                                      result.files.single.path != null) {
                                    setState(() {
                                      novoArquivo = File(
                                        result.files.single.path!,
                                      );
                                      novoNomeArquivo =
                                          result.files.single.name;
                                    });
                                  }
                                },
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Selecionar Novo Ficheiro'),
                      ),
                      if (novoArquivo != null && novoNomeArquivo != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                novoNomeArquivo!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Remover ficheiro',
                              onPressed:
                                  loading
                                      ? null
                                      : () {
                                        setState(() {
                                          novoArquivo = null;
                                          novoNomeArquivo = null;
                                        });
                                      },
                            ),
                          ],
                        ),
                      ] else ...[
                        if (material.nomeArquivo != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  size: 18,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    material.nomeArquivo!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                loading
                                    ? null
                                    : () async {
                                      setState(() => loading = true);
                                      try {
                                        if (novoArquivo != null &&
                                            novoNomeArquivo != null) {
                                          // Atualiza tudo, inclusive o arquivo
                                          await _materialController.addMaterial(
                                            titulo: tituloController.text,
                                            descricao: descricaoController.text,
                                            file: novoArquivo!,
                                            disciplinaId: material.disciplinaId,
                                            nomeArquivo: novoNomeArquivo!,
                                            professorId: material.professorId,
                                          );
                                          await _materialController
                                              .deleteMaterial(material.id);
                                        } else {
                                          // Só atualiza título/descrição
                                          await _materialController
                                              .updateMaterial(
                                                material.id,
                                                tituloController.text,
                                                descricaoController.text,
                                              );
                                        }
                                        await _buscarMateriais();
                                        if (mounted) Navigator.pop(context);
                                      } catch (e) {
                                        print('Erro ao salvar material: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erro ao salvar material: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => loading = false);
                                        }
                                      }
                                    },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _removerMaterial(MaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remover Material'),
            content: Text(
              'Tem certeza que deseja remover o material "${material.titulo}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await _materialController.deleteMaterial(material.id);
      await _buscarMateriais();
    }
  }
}
