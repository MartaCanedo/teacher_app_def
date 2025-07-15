import 'package:flutter/material.dart';
import 'package:teacher_app/utils/string_utils.dart';

class AlunosWidget extends StatelessWidget {
  final Map<String, String> alunos; // {alunoId: nomeAluno}

  const AlunosWidget({super.key, required this.alunos});

  @override
  Widget build(BuildContext context) {
    if (alunos.isEmpty) {
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
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.purple.shade300,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum aluno encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não foram encontrados alunos matriculados nesta disciplina.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alunos.length,
      itemBuilder: (context, index) {
        final alunoEntry = alunos.entries.elementAt(index);
        final alunoNome = alunoEntry.value;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              radius: 50,
              child: Text(alunoNome.initials, style: TextStyle(fontSize: 18)),
            ),
            title: Text(
              alunoNome,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Aluno ${index + 1} de ${alunos.length}'),
            // Agora temos acesso ao alunoId único (alunoEntry.key) se precisar para futuras funcionalidades
          ),
        );
      },
    );
  }
}
