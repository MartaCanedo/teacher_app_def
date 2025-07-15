import 'package:flutter/material.dart';
import 'package:teacher_app/screens/homepage.dart';

import '../session/session.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width:
                size.width > 500
                    ? 400
                    : size.width * 0.9, // largura fixa no centro
            child: Column(
              children: [
                // Imagem topo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Image.asset('assets/logo.webp', height: 250)],
                ),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Bem-vindo de volta!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // Email
                      TextFormField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Insira seu email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Palavra-passe
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Palavra-passe",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Insira sua palavra-passe";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Botão de login
                      _isLoading
                          ? CircularProgressIndicator()
                          : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: handleLogin,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  "Entrar",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                      SizedBox(height: 16),

                      // Esqueceu a senha
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final loginController = LoginController();
    final professor = await loginController.login(
      _email.text.trim(),
      _password.text.trim(),
    );

    setState(() => _isLoading = false);

    if (professor != null) {
      Session.currentProfessor = professor;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email ou senha incorretos")),
      );
    }
  }

  // void _login() {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() => _isLoading = true);

  //     // Simula login
  //     Future.delayed(Duration(seconds: 2), () {
  //       setState(() => _isLoading = false);
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Login bem-sucedido!")));
  //       // Navega para home
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => HomePage()),
  //       );
  //     });
  //   }
  // }
}
