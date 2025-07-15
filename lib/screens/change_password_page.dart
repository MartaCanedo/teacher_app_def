import 'package:flutter/material.dart';
import 'package:teacher_app/models/teacher_model.dart';

import '../controller/teacher_controller.dart';
import 'package:teacher_app/session/session.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  late Professor professor;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    professor = Session.currentProfessor!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Alterar Palavra-passe",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.indigo[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField("Palavra-passe atual", _oldPassword),
              _buildPasswordField("Nova palavra-passe", _newPassword),
              _buildPasswordField(
                "Confirmar nova palavra-passe",
                _confirmPassword,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Guardar"),
                onPressed: () async {
                  final controller = TeacherController();

                  final erro = await controller.atualizarSenha(
                    senhaAtual: _oldPassword.text.trim(),
                    novaSenha: _newPassword.text.trim(),
                    confirmarSenha: _confirmPassword.text.trim(),
                  );

                  if (erro != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(erro)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Senha atualizada com sucesso!"),
                      ),
                    );
                    Navigator.pop(context); // volta à página anterior
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obrigatório';
          return null;
        },
      ),
    );
  }
}
