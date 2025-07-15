import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_app/services/notification_service.dart';
import 'package:teacher_app/session/session.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/tarefa_model.dart';
import '../controller/tarefa_controller.dart';

class TarefasWidget extends StatefulWidget {
  final List<TarefaModel> tarefas;
  final Map<String, String> alunos; // {alunoId: nomeAluno}
  final bool isTeste;
  final String courseId;
  final String disciplinaNome;
  final String professorId;
  final VoidCallback onRefresh;

  const TarefasWidget({
    super.key,
    required this.tarefas,
    required this.alunos,
    required this.isTeste,
    required this.courseId,
    required this.disciplinaNome,
    required this.professorId,
    required this.onRefresh,
  });

  @override
  State<TarefasWidget> createState() => _TarefasWidgetState();
}

class _TarefasWidgetState extends State<TarefasWidget> {
  final TarefaController _tarefaController = TarefaController();

  // Função para fazer download do ficheiro
  Future<void> _downloadFicheiro(String nomeFile, String base64Data) async {
    try {
      // Verificar se os dados base64 estão disponíveis
      if (base64Data.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ficheiro não disponível para download'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Decodificar o base64 para bytes
      final Uint8List bytes = base64Decode(base64Data);

      // Abrir o seletor de diretório para o usuário escolher onde salvar
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Criar o caminho completo do arquivo
        final String filePath =
            '$selectedDirectory${Platform.pathSeparator}$nomeFile';
        final File file = File(filePath);

        // Escrever os bytes no arquivo
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ficheiro "$nomeFile" transferido com sucesso para $selectedDirectory',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao transferir ficheiro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar todas as tarefas sem filtro
    final tarefasFiltradas = widget.tarefas;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoTarefa(),
            icon: const Icon(Icons.add),
            label: Text(
              widget.isTeste ? 'Adicionar Teste' : 'Adicionar Tarefa',
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                tarefasFiltradas.isEmpty
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  widget.isTeste
                                      ? Icons.quiz_outlined
                                      : Icons.assignment_outlined,
                                  size: 48,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.isTeste
                                    ? 'Nenhum teste criado'
                                    : 'Nenhuma tarefa criada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isTeste
                                    ? 'Clique no botão "Adicionar Teste" para criar o primeiro teste desta disciplina.'
                                    : 'Clique no botão "Adicionar Tarefa" para criar a primeira tarefa desta disciplina.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      itemCount: tarefasFiltradas.length,
                      itemBuilder: (context, index) {
                        final tarefa = tarefasFiltradas[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              tarefa.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              'Data limite: ${tarefa.dataLimite.day.toString().padLeft(2, '0')}/${tarefa.dataLimite.month.toString().padLeft(2, '0')}/${tarefa.dataLimite.year} ${tarefa.horaLimite}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: [
                              Text(
                                '📄 Descrição: ${tarefa.descricao}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '📎 Ficheiros:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...tarefa.ficheiros.map(
                                (f) => ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.attach_file,
                                    size: 16,
                                  ),
                                  title: Text(
                                    f['nome'] ?? 'Ficheiro sem nome',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle:
                                      (f['base64']?.isEmpty ?? true)
                                          ? const Text(
                                            'Ficheiro não disponível',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          )
                                          : null,
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.download,
                                      size: 16,
                                      color:
                                          (f['base64']?.isEmpty ?? true)
                                              ? Colors.grey
                                              : null,
                                    ),
                                    onPressed: () {
                                      _downloadFicheiro(
                                        f['nome'] ?? 'ficheiro',
                                        f['base64'] ?? '',
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const Divider(),
                              const Text(
                                '📬 Entregas dos Alunos:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...widget.alunos.entries.map((alunoEntry) {
                                final alunoId = alunoEntry.key;
                                final alunoNome = alunoEntry.value;
                                final entregue =
                                    tarefa.entregas[alunoId] ?? false;
                                final ficheirosAluno =
                                    tarefa.entregasFicheiros[alunoId] ?? [];

                                // Verificar se a data limite já passou
                                final now = DateTime.now();
                                final dataLimiteCompleta = DateTime(
                                  tarefa.dataLimite.year,
                                  tarefa.dataLimite.month,
                                  tarefa.dataLimite.day,
                                  int.parse(tarefa.horaLimite.split(':')[0]),
                                  int.parse(tarefa.horaLimite.split(':')[1]),
                                );
                                final dataPassou = now.isAfter(
                                  dataLimiteCompleta,
                                );

                                // Determinar o status e cor
                                String status;
                                Color statusColor;
                                if (entregue) {
                                  status = 'Entregue';
                                  statusColor = Colors.green;
                                } else if (dataPassou) {
                                  status = 'Não entregue';
                                  statusColor = Colors.red;
                                } else {
                                  status = 'Pendente';
                                  statusColor = Colors.orange;
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  color:
                                      dataPassou && !entregue
                                          ? Theme.of(context)
                                              .colorScheme
                                              .errorContainer
                                              .withOpacity(0.3)
                                          : null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side:
                                        dataPassou && !entregue
                                            ? BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error
                                                  .withOpacity(0.5),
                                              width: 1,
                                            )
                                            : BorderSide.none,
                                  ),
                                  child: ExpansionTile(
                                    leading: Icon(
                                      entregue
                                          ? Icons.check_circle
                                          : dataPassou
                                          ? Icons.cancel
                                          : Icons.radio_button_unchecked,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                    title: Text(
                                      alunoNome,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight:
                                            dataPassou && !entregue
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    children:
                                        entregue && ficheirosAluno.isNotEmpty
                                            ? [
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'Ficheiros entregues:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              ...ficheirosAluno.map(
                                                (ficheiro) => ListTile(
                                                  dense: true,
                                                  leading: const Icon(
                                                    Icons.file_present,
                                                    size: 16,
                                                    color: Colors.blue,
                                                  ),
                                                  title: Text(
                                                    ficheiro['nome'] ??
                                                        'Ficheiro sem nome',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  subtitle:
                                                      (ficheiro['base64']
                                                                  ?.isEmpty ??
                                                              true)
                                                          ? const Text(
                                                            'Ficheiro não disponível',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.red,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                            ),
                                                          )
                                                          : null,
                                                  trailing: IconButton(
                                                    icon: Icon(
                                                      Icons.download,
                                                      size: 16,
                                                      color:
                                                          (ficheiro['base64']
                                                                      ?.isEmpty ??
                                                                  true)
                                                              ? Colors.grey
                                                              : Colors.blue,
                                                    ),
                                                    onPressed: () {
                                                      _downloadFicheiro(
                                                        '${alunoNome}_${ficheiro['nome']}',
                                                        ficheiro['base64'] ??
                                                            '',
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ]
                                            : entregue
                                            ? [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: Text(
                                                  'Nenhum ficheiro anexado',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                            ]
                                            : [],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              // Resumo das entregas
                              Builder(
                                builder: (context) {
                                  final totalAlunos = widget.alunos.length;
                                  final entregues =
                                      widget.alunos.keys
                                          .where(
                                            (alunoId) =>
                                                tarefa.entregas[alunoId] ??
                                                false,
                                          )
                                          .length;
                                  final now = DateTime.now();
                                  final dataLimiteCompleta = DateTime(
                                    tarefa.dataLimite.year,
                                    tarefa.dataLimite.month,
                                    tarefa.dataLimite.day,
                                    int.parse(tarefa.horaLimite.split(':')[0]),
                                    int.parse(tarefa.horaLimite.split(':')[1]),
                                  );
                                  final dataPassou = now.isAfter(
                                    dataLimiteCompleta,
                                  );
                                  final naoEntregues = totalAlunos - entregues;

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$entregues',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              'Entregues',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              dataPassou
                                                  ? Icons.cancel
                                                  : Icons.pending,
                                              color:
                                                  dataPassou
                                                      ? Colors.red
                                                      : Colors.orange,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$naoEntregues',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              dataPassou
                                                  ? 'Não entregues'
                                                  : 'Pendentes',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.group,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$totalAlunos',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              'Total',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed:
                                        () => _mostrarDialogoTarefa(
                                          tarefaAntiga: tarefa,
                                        ),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Editar'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _removerTarefa(tarefa),
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Remover'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoTarefa({TarefaModel? tarefaAntiga}) async {
    final tituloController = TextEditingController(
      text: tarefaAntiga?.titulo ?? '',
    );
    final descricaoController = TextEditingController(
      text: tarefaAntiga?.descricao ?? '',
    );
    // Quando editando, sempre usar a data atual como data de publicação
    DateTime dataPublicacao = DateTime.now();
    DateTime dataLimite =
        tarefaAntiga?.dataLimite ?? DateTime.now().add(const Duration(days: 7));
    String horaLimite = tarefaAntiga?.horaLimite ?? '23:59';
    List<Map<String, String>> ficheiros = List<Map<String, String>>.from(
      tarefaAntiga?.ficheiros ?? [],
    );
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                tarefaAntiga != null
                    ? 'Editar ${widget.isTeste ? "Teste" : "Tarefa"}'
                    : 'Nova ${widget.isTeste ? "Teste" : "Tarefa"}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tarefaAntiga != null
                                  ? 'Ao editar uma tarefa, a data de publicação será automaticamente alterada para hoje. A data limite deve ser posterior à data de publicação. Se escolher hoje como data limite, a hora deve ser posterior à hora atual.'
                                  : 'A data de publicação deve ser hoje ou posterior. A data limite deve ser posterior à data de publicação. Se escolher hoje como data limite, a hora deve ser posterior à hora atual.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Data de Publicação: ${dataPublicacao.day.toString().padLeft(2, '0')}/${dataPublicacao.month.toString().padLeft(2, '0')}/${dataPublicacao.year}${tarefaAntiga != null ? ' (Hoje)' : ''}',
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: tarefaAntiga != null ? Colors.grey : null,
                          ),
                          onPressed:
                              tarefaAntiga != null
                                  ? null // Desabilitar quando editando
                                  : () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: dataPublicacao,
                                      firstDate:
                                          DateTime.now(), // Não permitir datas anteriores a hoje
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        dataPublicacao = picked;
                                        // Se a data limite for anterior à nova data de publicação, ajustá-la
                                        if (dataLimite.isBefore(picked)) {
                                          dataLimite = picked.add(
                                            const Duration(days: 1),
                                          );
                                        }
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
                            'Data Limite: ${dataLimite.day.toString().padLeft(2, '0')}/${dataLimite.month.toString().padLeft(2, '0')}/${dataLimite.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dataLimite,
                              firstDate:
                                  dataPublicacao, // Data limite não pode ser antes da data de publicação
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => dataLimite = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('Hora Limite: $horaLimite')),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: int.parse(horaLimite.split(':')[0]),
                                minute: int.parse(horaLimite.split(':')[1]),
                              ),
                            );
                            if (picked != null) {
                              setState(
                                () => horaLimite = picked.format(context),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed:
                          loading
                              ? null
                              : () async {
                                final result = await FilePicker.platform.pickFiles(
                                  allowMultiple: true,
                                  withData:
                                      true, // Permite obter os bytes do arquivo
                                );
                                if (result != null) {
                                  setState(() {
                                    for (var file in result.files) {
                                      if (file.bytes != null) {
                                        final base64String = base64Encode(
                                          file.bytes!,
                                        );
                                        ficheiros.add({
                                          'nome': file.name,
                                          'base64': base64String,
                                        });
                                      }
                                    }
                                  });
                                }
                              },
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Anexar Ficheiros"),
                    ),
                    if (ficheiros.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            ficheiros
                                .map(
                                  (f) => Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          f['nome'] ?? '',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            loading
                                                ? null
                                                : () {
                                                  setState(() {
                                                    ficheiros.remove(f);
                                                  });
                                                },
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
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
                            // Validações de data
                            final now = DateTime.now();

                            // Verificar data de publicação (apenas data, não hora)
                            if (dataPublicacao.isBefore(
                              DateTime(now.year, now.month, now.day),
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A data de publicação não pode ser anterior a hoje',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Verificar data limite com hora
                            final dataLimiteCompleta = DateTime(
                              dataLimite.year,
                              dataLimite.month,
                              dataLimite.day,
                              int.parse(horaLimite.split(':')[0]),
                              int.parse(horaLimite.split(':')[1]),
                            );

                            final dataPublicacaoCompleta = DateTime(
                              dataPublicacao.year,
                              dataPublicacao.month,
                              dataPublicacao.day,
                              0, // Início do dia para publicação
                              0,
                            );

                            if (dataLimiteCompleta.isBefore(
                              dataPublicacaoCompleta,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A data limite não pode ser anterior à data de publicação',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Se a data limite for hoje, verificar se a hora não é no passado
                            if (dataLimite.year == now.year &&
                                dataLimite.month == now.month &&
                                dataLimite.day == now.day) {
                              if (dataLimiteCompleta.isBefore(now)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'A hora limite não pode ser anterior à hora atual',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            setState(() => loading = true);
                            // Buscar disciplinaId
                            final coursesSnap =
                                await FirebaseFirestore.instance
                                    .collection('courses')
                                    .get();
                            normalizar(String s) => removeDiacritics(
                              s
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'\\s+'), ' ')
                                  .trim(),
                            );
                            final normalizadoCourseId = normalizar(
                              widget.courseId,
                            );
                            QueryDocumentSnapshot<Map<String, dynamic>>?
                            courseDoc;
                            try {
                              courseDoc = coursesSnap.docs.firstWhere(
                                (doc) =>
                                    normalizar(doc.id) == normalizadoCourseId ||
                                    normalizar(doc['name'] ?? '') ==
                                        normalizadoCourseId,
                              );
                            } catch (e) {
                              try {
                                courseDoc = coursesSnap.docs.firstWhere(
                                  (doc) =>
                                      normalizar(
                                        doc.id,
                                      ).contains(normalizadoCourseId) ||
                                      normalizar(
                                        doc['name'] ?? '',
                                      ).contains(normalizadoCourseId),
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
                            final normalizadoWidgetNome = normalizar(
                              widget.disciplinaNome,
                            );
                            QueryDocumentSnapshot<Map<String, dynamic>>?
                            subjectDoc;
                            try {
                              subjectDoc = subjectsSnap.docs.firstWhere(
                                (doc) =>
                                    normalizar(doc['name'] ?? '') ==
                                    normalizadoWidgetNome,
                              );
                            } catch (e) {
                              subjectDoc = null;
                            }
                            if (subjectDoc == null) return;
                            final disciplinaId = subjectDoc.id;
                            if (tarefaAntiga == null) {
                              await _tarefaController.addTarefa(
                                titulo: tituloController.text,
                                descricao: descricaoController.text,
                                disciplinaId: disciplinaId,
                                professorId: widget.professorId,
                                dataLimite: dataLimite,
                                dataPublicacao: dataPublicacao,
                                horaLimite: horaLimite,
                                ficheiros: ficheiros,
                              );
                            } else {
                              final tarefaEditada = TarefaModel(
                                id: tarefaAntiga.id,
                                titulo: tituloController.text,
                                descricao: descricaoController.text,
                                disciplinaId: disciplinaId,
                                professorId: widget.professorId,
                                dataLimite: dataLimite,
                                dataPublicacao: dataPublicacao,
                                horaLimite: horaLimite,
                                ficheiros: ficheiros,
                                entregas: tarefaAntiga.entregas,
                                entregasFicheiros:
                                    tarefaAntiga.entregasFicheiros,
                              );
                              await _tarefaController.updateTarefa(
                                tarefaEditada,
                              );
                            }
                            final senderName =
                                Session.currentProfessor?.nome ?? 'Professor';

                            // Enviar notificações para todos os alunos da disciplina
                            await NotificationService.sendTaskNotificationToStudents(
                              courseId: widget.courseId,
                              disciplinaNome: widget.disciplinaNome,
                              professorName: senderName,
                              taskTitle: tituloController.text,
                              isTest: widget.isTeste,
                            );

                            print(
                              'Calling onRefresh after adding/editing tarefa',
                            );
                            widget.onRefresh();
                            if (mounted) Navigator.pop(context, true);
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

  void _removerTarefa(TarefaModel tarefa) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text(
            'Tem certeza que deseja remover a ${widget.isTeste ? "teste" : "tarefa"} "${tarefa.titulo}"?',
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
        await _tarefaController.deleteTarefa(tarefa.id);
        print('Calling onRefresh after deleting tarefa');
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.isTeste ? "Teste" : "Tarefa"} removida com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao remover ${widget.isTeste ? "teste" : "tarefa"}: $e',
              ),
            ),
          );
        }
      }
    }
  }
}
