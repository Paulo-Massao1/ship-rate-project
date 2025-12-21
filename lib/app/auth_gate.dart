import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/home/main_screen_page.dart';
import '../features/auth/login_page.dart';

/// AuthGate
/// --------
/// Este widget atua como uma "porta de entrada" da aplicação.
/// Ele escuta o estado de autenticação do Firebase e redireciona
/// automaticamente o usuário para a tela correta:
///   • `MainScreen()` quando autenticado
///   • `LoginPage()` quando não autenticado
///
/// Benefícios desta abordagem:
///   • remove a necessidade de navegação manual após login/logout
///   • evita telas piscando ao abrir o app
///   • garante maior segurança e UX consistente
///
/// É recomendado que este widget seja usado como tela inicial
/// no `MaterialApp`, substituindo rotas manuais.
///
/// Exemplo no main.dart:
/// ```dart
/// home: const AuthGate()
/// ```
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escuta contínua do estado atual do Firebase Auth.
      // Emite eventos quando:
      // • usuário faz login
      // • usuário faz logout
      // • sessão expira
      // • cadastro é concluído
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Enquanto o Firebase verifica o estado (token, sessão, cache),
        // exibimos um carregamento simples para evitar flicker.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Caso snapshot contenha dados, significa que o usuário está autenticado.
        // Nesse caso, o app deve exibir a Home (main screen).
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Caso não tenha sessão ativa, direcionamos para login.
        return const LoginPage();
      },
    );
  }
}
