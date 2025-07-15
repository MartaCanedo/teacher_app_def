import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:teacher_app/screens/homepage.dart';
import 'package:teacher_app/screens/login_page.dart';
import 'package:window_size/window_size.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase já está inicializado no main()
  print('📨 Notificação em background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDq9RHvJCE0Fv0KGl2M3v9nP39ri_YiTLk",
      authDomain: "campus-link-def.firebaseapp.com",
      projectId: "campus-link-def",
      storageBucket: "campus-link-def.firebasestorage.app",
      messagingSenderId: "821984532953",
      appId: "1:821984532953:web:166c5b12a2a85e019421c8",
      measurementId: "G-0W8N9BZWJD",
    ),
  );

  setWindowMinSize(Size(1200, 800));

  runApp(const TeacherApp());
}

class TeacherApp extends StatefulWidget {
  const TeacherApp({super.key});

  @override
  State<TeacherApp> createState() => _TeacherAppState();
}

class _TeacherAppState extends State<TeacherApp> {
  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicita permissão (necessário no Android 13+ e iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissão concedida');

      // Obtém o token do dispositivo
      final token = await messaging.getToken();
      print('📱 Token FCM: $token');

      // Podes salvar este token no Firestore para enviar notificações depois
    }

    // Receber notificações em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Mensagem em foreground!');
      print('🔹 Título: ${message.notification?.title}');
      print('🔹 Corpo: ${message.notification?.body}');
    });

    // Quando abre app por notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Abriu a notificação!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData.light(),
      dark: ThemeData.dark(),
      initial:
          AdaptiveThemeMode.system, // Define o tema inicial como adaptativo
      builder: (lightTheme, darkTheme) {
        return Builder(
          builder: (context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode:
                  AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
                      ? ThemeMode.dark
                      : ThemeMode.light, // Corrigido para usar ThemeMode
              initialRoute: '/login', // Define Login como a rota inicial
              routes: {
                '/login': (context) => const LoginPage(),
                '/home': (context) => const HomePage(),
              },
            );
          },
        );
      },
    );
  }
}
