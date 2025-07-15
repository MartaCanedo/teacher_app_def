import 'package:flutter/material.dart';
import 'package:teacher_app/models/teacher_model.dart';
import 'package:teacher_app/screens/login_page.dart';

import '../session/session.dart';

import '../controller/teacher_controller.dart';

import 'change_password_page.dart';

import '../utils/string_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Professor professor;
  Map<String, String> errors = {};

  final TextEditingController _moradaController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    professor = Session.currentProfessor!;
    _moradaController.text = professor.morada;
    _codigoPostalController.text = professor.codigoPostal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              child: Text(
                professor.nome.initials,
                style: TextStyle(fontSize: 32),
              ),
            ),
            SizedBox(height: 12),
            Text(
              professor.nome,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            _buildInfoRow("Email", professor.email),
            _buildInfoRow("Disciplina", professor.disciplinas[0]),
            _buildInfoRow("Nacionalidade", professor.nacionalidade),
            _buildInfoRow("Distrito", professor.distrito),
            _buildEditableField(
              title: 'Morada',
              controller: _moradaController,
              errorText: errors['morada'],
            ),
            _buildEditableField(
              title: "Código Postal",
              controller: _codigoPostalController,
              errorText: errors['codigoPostal'],
            ),
            _buildInfoRow("Data de Nascimento", professor.dataNascimento),
            _buildInfoRow("NIF", professor.nif),
            _buildInfoRow("IBAN", professor.iban),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("Guardar Alterações"),
              onPressed: () async {
                final morada = _moradaController.text.trim();
                final codigoPostal = _codigoPostalController.text.trim();

                setState(() {
                  errors.clear();

                  if (morada.isEmpty) {
                    errors['morada'] = 'A morada é obrigatória';
                  }
                  if (codigoPostal.isEmpty) {
                    errors['codigoPostal'] = 'O código postal é obrigatório';
                  } else if (!RegExp(
                    r'^[0-9]{4}-[0-9]{3}$',
                  ).hasMatch(codigoPostal)) {
                    errors['codigoPostal'] = 'Formato: 1234-123';
                  }
                });

                if (errors.isEmpty) {
                  final controller = TeacherController();
                  final sucesso = await controller.atualizarMoradaECodigoPostal(
                    novaMorada: morada,
                    novoCodigoPostal: codigoPostal,
                  );

                  if (sucesso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados atualizados com sucesso!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erro ao atualizar os dados.'),
                      ),
                    );
                  }
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.lock_reset),
              label: Text("Alterar Palavra-passe"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                );
              },
            ),
            SizedBox(height: 12),
            TextButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              onPressed: () {
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
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        leading: Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildEditableField({
    required String title,
    required TextEditingController controller,
    String? errorText,
    IconData icon = Icons.edit_location_alt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          errorText: errorText,
        ),
      ),
    );
  }
}
