import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/home/main_screen_page.dart';
import '../features/auth/login_page.dart';

/// ============================================================================
/// AUTH GATE
/// ============================================================================
/// Widget responsável por controlar o fluxo de autenticação da aplicação.
///
/// Este widget atua como uma "porta de entrada" que escuta o estado de
/// autenticação do Firebase e redireciona automaticamente o usuário para
/// a tela apropriada:
///   • [MainScreen] quando o usuário está autenticado
///   • [LoginPage] quando o usuário não está autenticado
///
/// Benefícios desta abordagem:
///   • Remove a necessidade de navegação manual após login/logout
///   • Evita flicker ao abrir o app (transições suaves)
///   • Garante segurança e experiência de usuário consistente
///   • Sincroniza automaticamente com mudanças no estado de auth
///
/// Recomendação:
/// Este widget deve ser usado como tela inicial no [MaterialApp],
/// substituindo rotas manuais de autenticação.
///
/// Exemplo de uso no main.dart:
/// ```dart
/// MaterialApp(
///   home: const AuthGate(),
/// )
/// ```
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      /// Escuta contínua do estado de autenticação do Firebase.
      /// 
      /// Este stream emite eventos quando:
      /// • Usuário faz login
      /// • Usuário faz logout
      /// • Sessão expira
      /// • Cadastro é concluído
      /// • Token é renovado
      stream: FirebaseAuth.instance.authStateChanges(),
      
      builder: (context, snapshot) {
        /// ---------------------------------------------------------------------
        /// Estado: Verificando autenticação
        /// ---------------------------------------------------------------------
        /// Enquanto o Firebase verifica o estado (token, sessão, cache local),
        /// exibimos um loading para evitar flash de conteúdo não autenticado.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        /// ---------------------------------------------------------------------
        /// Estado: Usuário autenticado
        /// ---------------------------------------------------------------------
        /// Se o snapshot contém dados, significa que existe uma sessão ativa.
        /// Neste caso, direcionamos para a tela principal do aplicativo.
        if (snapshot.hasData) {
          return const MainScreen();
        }

        /// ---------------------------------------------------------------------
        /// Estado: Usuário não autenticado
        /// ---------------------------------------------------------------------
        /// Caso não haja sessão ativa, direcionamos para a tela de login.
        return const LoginPage();
      },
    );
  }
}