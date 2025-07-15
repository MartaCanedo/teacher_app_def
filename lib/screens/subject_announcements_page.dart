import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_app/utils/file_utils.dart';

import 'homepage.dart';

import '../models/teacher_model.dart';
import '../models/anuncio_turma_model.dart';
import '../controller/anuncio_turma_controller.dart';
import '../session/session.dart';

class SubjectAnnouncementsPage extends StatefulWidget {
  const SubjectAnnouncementsPage({super.key});

  @override
  State<SubjectAnnouncementsPage> createState() => _SubjectAnnouncementsPage();
}

class _SubjectAnnouncementsPage extends State<SubjectAnnouncementsPage> {
  final String currentUser = 'ana@example.com';
  late Professor professor;
  final AnuncioTurmaController _controller = AnuncioTurmaController();
  List<AnuncioTurma> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    professor = Session.currentProfessor!;
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    final anuncios = await _controller.buscarPorDisciplina(
      professor.disciplinas[0],
    );
    setState(() {
      _announcements = anuncios;
      _isLoading = false;
    });
  }

  Future<void> _addAnnouncement(AnuncioTurma newAnnouncement) async {
    try {
      await _controller.criarAnuncioTurma(newAnnouncement);
      await _fetchAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anúncio criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar anúncio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editAnnouncement(int index) async {
    if (_announcements[index].ficheiro['author'] == professor.nome) {
      final updatedAnnouncement = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  EditAnnouncementPage(announcement: _announcements[index]),
        ),
      );
      if (updatedAnnouncement != null && updatedAnnouncement is AnuncioTurma) {
        await _controller.editarAnuncioTurma(updatedAnnouncement);
        await _fetchAnnouncements();
      }
    }
  }

  Future<void> _deleteAnnouncement(int index) async {
    if (_announcements[index].ficheiro['author'] == professor.nome) {
      await _controller.eliminarAnuncioTurma(_announcements[index].id);
      await _fetchAnnouncements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anúncios', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];
                  String shortTitle =
                      announcement.titulo.length > 30
                          ? '${announcement.titulo.substring(0, 30)}...'
                          : announcement.titulo;
                  String shortDesc =
                      announcement.descricao.length > 60
                          ? '${announcement.descricao.substring(0, 60)}...'
                          : announcement.descricao;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(shortTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shortDesc),
                          if (announcement.disciplina.isNotEmpty)
                            Text(
                              'Disciplina: ${announcement.disciplina}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (announcement.ficheiro['nome'] != null &&
                              (announcement.ficheiro['nome'] as String)
                                  .isNotEmpty)
                            Text(
                              'Ficheiro: ${announcement.ficheiro['nome']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      trailing:
                          announcement.ficheiro['author'] == professor.nome
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editAnnouncement(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteAnnouncement(index),
                                  ),
                                ],
                              )
                              : null,
                      onTap: () => _showAnnouncementDetails(announcement),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newAnnouncement = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AddAnnouncementPage(disciplina: professor.disciplinas[0]),
            ),
          );
          if (newAnnouncement != null && newAnnouncement is AnuncioTurma) {
            await _addAnnouncement(newAnnouncement);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAnnouncementDetails(AnuncioTurma anuncio) {
    showDialog(
      context: context,
      builder: (context) {
        final fileName = anuncio.ficheiro['nome'] ?? '';
        final base64Data = anuncio.ficheiro['base64'] ?? '';
        final hasFile = fileName.isNotEmpty && base64Data.isNotEmpty;
        return AlertDialog(
          title: Text(anuncio.titulo),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descrição: ${anuncio.descricao}'),
                const SizedBox(height: 8),
                Text('Disciplina: ${anuncio.disciplina}'),
                const SizedBox(height: 8),
                if (fileName.isNotEmpty) Text('Ficheiro: $fileName'),
                if (anuncio.ficheiro['author'] != null)
                  Text('Autor: ${anuncio.ficheiro['author']}'),
                if (hasFile)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Baixar Ficheiro'),
                      onPressed: () async {
                        final filePath = await downloadBase64File(
                          anuncio.ficheiro['base64'],
                          anuncio.ficheiro['author'] ?? 'ficheiro',
                          'pdf',
                        );

                        if (filePath != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Ficheiro salvo com sucesso em: $filePath',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao salvar o ficheiro'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class AddAnnouncementPage extends StatefulWidget {
  final String disciplina;
  const AddAnnouncementPage({super.key, required this.disciplina});

  @override
  _AddAnnouncementPageState createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<AddAnnouncementPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedFile;
  String? _fileBase64;

  Future<void> _saveAnnouncement() async {
    final title = _titleController.text;
    final description = _descriptionController.text;
    if (title.isNotEmpty && description.isNotEmpty) {
      final fileName = _selectedFile?.path.split('/').last ?? '';
      final fileMap = <String, dynamic>{
        'nome': fileName,
        'base64': _fileBase64 ?? '',
        'author': Session.currentProfessor?.nome ?? '',
      };
      final anuncio = AnuncioTurma(
        id: '',
        titulo: title,
        descricao: description,
        disciplina: widget.disciplina,
        ficheiro: fileMap,
      );
      Navigator.pop(context, anuncio);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      type: FileType.custom,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      // Check file size (limit to 5MB to avoid Firestore issues)
      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ficheiro muito grande. Tamanho máximo: 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = File(file.path!);
        // Always encode as base64!
        _fileBase64 = file.bytes != null ? base64Encode(file.bytes!) : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Anúncio',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Disciplina: ${widget.disciplina}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Selecionar Ficheiro'),
            ),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ficheiro: ${_selectedFile!.path.split('/').last}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAnnouncement,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditAnnouncementPage extends StatefulWidget {
  final AnuncioTurma announcement;
  const EditAnnouncementPage({super.key, required this.announcement});

  @override
  _EditAnnouncementPageState createState() => _EditAnnouncementPageState();
}

class _EditAnnouncementPageState extends State<EditAnnouncementPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _selectedFile;
  String? _fileBase64;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.titulo);
    _descriptionController = TextEditingController(
      text: widget.announcement.descricao,
    );
    _fileBase64 = widget.announcement.ficheiro['base64'] ?? '';
  }

  Future<void> _saveEditedAnnouncement() async {
    final updatedTitle = _titleController.text;
    final updatedDescription = _descriptionController.text;
    if (updatedTitle.isNotEmpty && updatedDescription.isNotEmpty) {
      final fileName =
          _selectedFile?.path.split('/').last ??
          widget.announcement.ficheiro['nome'] ??
          '';
      final fileMap = <String, dynamic>{
        'nome': fileName,
        'base64': _fileBase64 ?? '',
        'author': widget.announcement.ficheiro['author'] ?? 'ana@example.com',
      };
      final updatedAnuncio = AnuncioTurma(
        id: widget.announcement.id,
        titulo: updatedTitle,
        descricao: updatedDescription,
        disciplina: widget.announcement.disciplina,
        ficheiro: fileMap,
      );
      Navigator.pop(context, updatedAnuncio);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      type: FileType.custom,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;

      // Check file size (limit to 5MB to avoid Firestore issues)
      const maxFileSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxFileSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ficheiro muito grande. Tamanho máximo: 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = File(file.path!);
        // Always encode as base64!
        _fileBase64 = file.bytes != null ? base64Encode(file.bytes!) : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Anúncio',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Disciplina: ${widget.announcement.disciplina}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Selecionar Ficheiro'),
            ),
            if (_selectedFile != null ||
                widget.announcement.ficheiro['nome'] != '')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ficheiro: ${_selectedFile?.path.split('/').last ?? widget.announcement.ficheiro['nome']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEditedAnnouncement,
              child: const Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }
}
