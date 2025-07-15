import 'package:flutter/material.dart';
import '../controller/announcements_controller.dart';
import '../controller/announcement_read_controller.dart';
import '../models/announcement_model.dart';
import '../utils/file_utils.dart';

class GeneralAnnouncementsPage extends StatefulWidget {
  final String professorId;

  const GeneralAnnouncementsPage({super.key, required this.professorId});

  @override
  State<GeneralAnnouncementsPage> createState() =>
      _GeneralAnnouncementsPageState();
}

class _GeneralAnnouncementsPageState extends State<GeneralAnnouncementsPage> {
  final AnnouncementController _controller = AnnouncementController();
  final AnnouncementReadController _readController =
      AnnouncementReadController();
  List<Announcement> announcements = [];
  Set<String> readAnnouncements = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadReadAnnouncements();
    await _loadAnnouncements();
  }

  Future<void> _loadReadAnnouncements() async {
    try {
      readAnnouncements = await _readController.getReadAnnouncementIds(
        widget.professorId,
      );
      setState(() {});
    } catch (e) {
      print('Erro ao carregar anúncios lidos: $e');
      setState(() {
        readAnnouncements = {};
      });
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final result = await _controller.getAnnouncementsForProfessors();
      setState(() {
        announcements = result;
        isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar anúncios: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String announcementId) async {
    try {
      final success = await _readController.markAnnouncementAsRead(
        widget.professorId,
        announcementId,
      );

      if (success) {
        setState(() {
          readAnnouncements.add(announcementId);
        });
      }
    } catch (e) {
      print('Erro ao marcar anúncio como lido: $e');
    }
  }

  bool _isUnread(String announcementId) {
    return !readAnnouncements.contains(announcementId);
  }

  void _showAnnouncementDetails(Announcement announcement) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(announcement.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(announcement.message),
                  if (announcement.files.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Arquivos anexados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...announcement.files.map(
                      (file) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.attach_file),
                        title: Text(file['name'] ?? 'Arquivo'),
                        trailing: const Icon(
                          Icons.download,
                          color: Colors.blue,
                        ),
                        onTap: () async {
                          final base64Data = file['bytesBase64'] ?? '';
                          final fileName = file['name'] ?? 'arquivo';

                          if (base64Data.isNotEmpty) {
                            // Extrair a extensão do nome do ficheiro
                            String extension = 'pdf'; // padrão
                            if (fileName.contains('.')) {
                              extension =
                                  fileName.split('.').last.toLowerCase();
                            }

                            // Remover a extensão do nome para evitar duplicação
                            String nameWithoutExtension = fileName;
                            if (fileName.contains('.')) {
                              nameWithoutExtension = fileName.substring(
                                0,
                                fileName.lastIndexOf('.'),
                              );
                            }

                            final filePath = await downloadBase64File(
                              base64Data,
                              nameWithoutExtension,
                              extension,
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
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ficheiro não contém dados válidos',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );

    // Marcar como lido após visualizar
    if (_isUnread(announcement.id)) {
      _markAsRead(announcement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anúncios Gerais'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : announcements.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.announcement_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Nenhum anúncio disponível',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final isUnread = _isUnread(announcement.id);

                    return Container(
                      height: 120, // Altura fixa para todos os boxes
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: isUnread ? 4 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              isUnread
                                  ? const BorderSide(
                                    color: Colors.blue,
                                    width: 1,
                                  )
                                  : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showAnnouncementDetails(announcement),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Indicador de não lido
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isUnread
                                            ? Colors.green
                                            : Colors.transparent,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Conteúdo do anúncio
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        announcement.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              isUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                          color:
                                              isUnread
                                                  ? Colors.black
                                                  : Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        announcement.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (announcement.files.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.attach_file,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${announcement.files.length} arquivo(s)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Ícone de seta
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
