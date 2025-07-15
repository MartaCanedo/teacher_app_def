import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teacher_app/screens/general_announcements_page.dart';
import 'package:teacher_app/screens/messages_page.dart';
import 'package:teacher_app/screens/subject_announcements_page.dart';
import 'package:teacher_app/screens/login_page.dart';
import 'subjects_detail_page.dart';
import 'chat_home_page.dart';
import 'profile_page.dart';

import 'package:diacritic/diacritic.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/session.dart';
import '../models/teacher_model.dart';
import '../models/announcement_model.dart';
import '../controller/announcements_controller.dart';
import '../controller/announcement_read_controller.dart';
import '../utils/string_utils.dart';

import '../controller/tarefa_controller.dart';
import '../controller/teste_controller.dart';
import '../models/tarefa_model.dart';
import '../models/teste_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<TarefaModel> tarefas = [];
  List<TesteModel> testes = [];
  bool isLoadingExtras = true;
  late Professor professor;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Announcement> anuncios = [];
  Set<String> readAnnouncements = {};
  final AnnouncementReadController _readController =
      AnnouncementReadController();

  final Map<DateTime, String> eventos = {
    DateTime.utc(2025, 4, 18): "📅 Teste de Programação I",
    DateTime.utc(2025, 4, 22): "📅 Reunião de Avaliação - Sala 2",
    DateTime.utc(2025, 5, 10): "📅 Reunião de avaliação do semestre",
    DateTime.utc(2025, 6, 5):
        "📅 Entrega de projeto de Desenvolvimento de Software",
  };

  void carregarAnuncios() async {
    final controller = AnnouncementController();
    final resultado = await controller.getAnnouncementsForProfessors();
    await _loadReadAnnouncements();

    setState(() {
      // Pegar apenas os 3 últimos anúncios
      anuncios = resultado.take(3).toList();
    });
  }

  Future<void> _loadReadAnnouncements() async {
    try {
      readAnnouncements = await _readController.getReadAnnouncementIds(
        professor.id,
      );
    } catch (e) {
      print('Erro ao carregar anúncios lidos: $e');
      readAnnouncements = {};
    }
  }

  bool _isUnread(String announcementId) {
    return !readAnnouncements.contains(announcementId);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => carregarDadosExtras());
    professor = Session.currentProfessor!;
    WidgetsBinding.instance.addObserver(this);
    carregarAnuncios();
    // Removido o redirecionamento automático para a disciplina
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recarregar dados quando a app volta a ficar ativa
      _refreshAnnouncementReadStatus();
    }
  }

  Future<void> _refreshAnnouncementReadStatus() async {
    await _loadReadAnnouncements();
    setState(() {});
  }

  final _menuStyle = const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    String? eventoDoDia;
    if (_selectedDay != null) {
      final normalizado = DateTime.utc(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      eventoDoDia = eventos[normalizado];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Página Inicial", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[700],
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Switch(
            value: AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark,
            onChanged: (value) {
              final theme =
                  value ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light;
              AdaptiveTheme.of(context).setThemeMode(theme);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.indigo[700],
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.indigo[700]),
                accountName: Text(
                  professor.nome,
                  style: TextStyle(fontSize: 18),
                ),
                accountEmail: Text(professor.email),
                currentAccountPicture: CircleAvatar(
                  radius: 50,
                  child: Text(
                    professor.nome.initials,
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              _drawerItem("Disciplina", Icons.book, () async {
                final professorId = professor.id;
                final doc =
                    await FirebaseFirestore.instance
                        .collection('professores')
                        .doc(professorId)
                        .get();
                final data = doc.data();
                final List<dynamic> disciplinas = data?['disciplinas'] ?? [];
                if (disciplinas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nenhuma disciplina encontrada para este professor.',
                      ),
                    ),
                  );
                  return;
                }

                final String disciplinaSelecionada =
                    disciplinas.first.toString();

                // Buscar informações completas da disciplina em todos os cursos
                String? courseId;
                int courseYear = 0;

                try {
                  final coursesSnap =
                      await FirebaseFirestore.instance
                          .collection('courses')
                          .get();

                  String normalizar(String s) {
                    return removeDiacritics(
                      s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
                    );
                  }

                  final disciplinaNormalizada = normalizar(
                    disciplinaSelecionada,
                  );

                  // Buscar em todos os cursos
                  for (final courseDoc in coursesSnap.docs) {
                    final subjectsSnap =
                        await FirebaseFirestore.instance
                            .collection('courses')
                            .doc(courseDoc.id)
                            .collection('subjects')
                            .get();

                    for (final subjectDoc in subjectsSnap.docs) {
                      final subjectName = subjectDoc['name'] ?? '';
                      if (normalizar(subjectName) == disciplinaNormalizada) {
                        courseId = courseDoc.id;
                        courseYear = subjectDoc['courseYear'] ?? 0;
                        break;
                      }
                    }
                    if (courseId != null) break;
                  }
                } catch (e) {
                  print('Erro ao buscar informações do curso: $e');
                }

                final atualizou = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DisciplinaDetalhePage(
                          nome: disciplinaSelecionada,
                          codigo: '',
                          semestre: '',
                          ano: '',
                          courseId: courseId ?? '',
                          courseYear: courseYear,
                          professorId: professor.id,
                        ),
                  ),
                );

                if (atualizou == true) {
                  await carregarDadosExtras(); // <- recarrega calendário, testes e tarefas
                }
              }),
              _drawerItem("Anúncios da Disciplina", Icons.announcement, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => SubjectAnnouncementsPage()),
                );
              }),
              _drawerItem(
                "Anúncios Gerais",
                Icons.announcement_rounded,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => GeneralAnnouncementsPage(
                            professorId: professor.id,
                          ),
                    ),
                  );
                  // Recarregar dados quando voltar
                  await _refreshAnnouncementReadStatus();
                },
              ),
              _drawerItem("Mensagens", Icons.message, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MessagesPage()),
                );
              }),
              _drawerItem("Perfil", Icons.person, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              }),
              const Spacer(),
              Divider(color: Colors.white54),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Sair', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Session.currentProfessor = null; // limpa a sessão

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false, // remove todas as rotas anteriores
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Anúncios
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => GeneralAnnouncementsPage(
                            professorId: professor.id,
                          ),
                    ),
                  );
                  // Recarregar os dados quando voltar da página de anúncios
                  await _loadReadAnnouncements();
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '📢 Anúncios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (anuncios.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Nenhum anúncio disponível."),
                        )
                      else
                        ...anuncios.map(
                          (announcement) => ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _isUnread(announcement.id)
                                        ? Colors.green
                                        : Colors.transparent,
                              ),
                            ),
                            title: Text(
                              announcement.title,
                              style: TextStyle(
                                fontWeight:
                                    _isUnread(announcement.id)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              announcement.message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            dense: true,
                          ),
                        ),
                      if (anuncios.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Center(
                            child: Text(
                              'Toque para ver todos os anúncios',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card do Calendário
            Card(
              elevation: 4,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate:
                          (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: const Color.fromARGB(255, 36, 35, 35),
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: TextStyle(color: Colors.red),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final evento =
                              eventos.entries
                                  .firstWhere(
                                    (entry) => isSameDay(entry.key, day),
                                    orElse: () => MapEntry(DateTime(1900), ''),
                                  )
                                  .value;

                          if (evento.isNotEmpty) {
                            Color corEvento;

                            if (evento.contains('Teste')) {
                              corEvento = Colors.orange; // cor para Testes
                            } else if (evento.contains('Tarefa')) {
                              corEvento = Colors.purple; // cor para Tarefas
                            } else {
                              corEvento =
                                  Colors
                                      .greenAccent; // cor padrão (ex: reunião)
                            }

                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: corEvento,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (eventoDoDia != null)
                      Card(
                        elevation: 4,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.orange[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📌 Evento no dia ${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}/${_selectedDay!.year}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(eventoDoDia, style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: _menuStyle.copyWith(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Fecha o drawer antes de navegar
        onTap();
      },
    );
  }

  Future<void> carregarDadosExtras() async {
    try {
      final professorDisciplina = professor.disciplinas.first;
      final normalizar =
          (String s) => removeDiacritics(
            s.toLowerCase().replaceAll(RegExp(r'\\s+'), ' ').trim(),
          );
      final normalizadoNomeDisciplina = normalizar(professorDisciplina);

      final coursesSnap =
          await FirebaseFirestore.instance.collection('courses').get();

      String? courseId;
      String? subjectId;

      for (final course in coursesSnap.docs) {
        final subjectsSnap =
            await FirebaseFirestore.instance
                .collection('courses')
                .doc(course.id)
                .collection('subjects')
                .get();

        for (final subject in subjectsSnap.docs) {
          final nome = subject['name'] ?? '';
          if (normalizar(nome) == normalizadoNomeDisciplina) {
            courseId = course.id;
            subjectId = subject.id;
            break;
          }
        }

        if (courseId != null && subjectId != null) break;
      }

      if (courseId == null || subjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curso ou disciplina não encontrados.')),
        );
        return;
      }

      final tarefasCarregadas = await TarefaController().getTarefas(
        subjectId,
        professor.id,
      );
      final testesCarregados = await TesteController().getTestes(
        subjectId,
        professor.id,
      );

      final novosEventos = <DateTime, String>{};

      for (final t in testesCarregados) {
        final data = t.dataHora;
        final normalizado = DateTime.utc(data.year, data.month, data.day);
        novosEventos[normalizado] = "📘 Teste: ${t.nome}";
      }

      for (final t in tarefasCarregadas) {
        final data = t.dataLimite;
        final normalizado = DateTime.utc(data.year, data.month, data.day);
        novosEventos[normalizado] = "📗 Tarefa: ${t.titulo}";
      }

      setState(() {
        tarefas = tarefasCarregadas;
        testes = testesCarregados;
        eventos.addAll(novosEventos);
        isLoadingExtras = false;
      });
    } catch (e) {
      setState(() {
        isLoadingExtras = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar tarefas/testes: $e')),
      );
    }
  }
}
