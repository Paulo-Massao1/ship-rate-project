import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/auth_gate.dart';
import 'core/theme/app_theme.dart';

/// ============================================================================
/// main.dart
/// ============================================================================
/// Ponto de entrada do aplicativo ShipRate.
///
/// Responsabilidades deste arquivo:
///  • Inicializar corretamente o Flutter e o Firebase.
///  • Carregar configurações específicas da plataforma (web/android/ios)
///    usando `firebase_options.dart`, gerado automaticamente via FlutterFire.
///  • Registrar o tema global da aplicação.
///  • Definir o widget raiz (`ShipRateApp`), responsável pelo roteamento inicial
///    e controle de autenticação via AuthGate.
///
/// Fluxo de inicialização:
///  1) WidgetsFlutterBinding.ensureInitialized()
///       - garante que o binding do Flutter esteja pronto antes de interagir
///         com serviços assíncronos (Firebase).
///
///  2) Firebase.initializeApp(...)
///       - inicializa a instância padrão do Firebase na plataforma atual.
///       - App **não continua** até que o Firebase esteja totalmente inicializado.
///
///  3) runApp(ShipRateApp)
///       - inicia o app com o tema e página inicial.
///
/// Poderia futuramente ser estendido para:
///  • Logging / Crashlytics
///  • Remote Config
///  • Contêiner de dependências (GetIt, Riverpod, etc.)
///
/// ============================================================================
void main() async {
  /// Garante que o Flutter esteja pronto antes da inicialização do Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  /// Inicializa o Firebase com opções específicas da plataforma.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Inicia o aplicativo principal.
  runApp(const ShipRateApp());
}

/// ============================================================================
/// ShipRateApp
/// ============================================================================
/// Widget raiz da aplicação.
///
/// Responsabilidades:
///  • Declarar MaterialApp
///  • Registrar tema claro (ou futuro dark theme)
///  • Definir o fluxo de autenticação via AuthGate
///
/// AuthGate:
///   - Escuta o estado do FirebaseAuth
///   - Direciona para página de Login quando deslogado
///   - Direciona para MainScreen quando autenticado
///
/// ============================================================================
class ShipRateApp extends StatelessWidget {
  const ShipRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate',

      /// Remove o banner DEBUG no topo da interface
      debugShowCheckedModeBanner: false,

      /// Define tema principal — localizado em core/theme/app_theme.dart
      theme: AppTheme.light,

      /// A primeira tela é controlada pelo AuthGate
      home: const AuthGate(),
    );
  }
}
