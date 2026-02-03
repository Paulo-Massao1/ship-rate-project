import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/auth_gate.dart';
import 'core/theme/app_theme.dart';

/// Entry point for the ShipRate application.
///
/// Responsibilities:
/// - Initialize Flutter binding
/// - Initialize Firebase with platform-specific options
/// - Launch the root widget
///
/// Initialization flow:
/// 1. WidgetsFlutterBinding.ensureInitialized()
///    - Ensures Flutter binding is ready before async operations
///
/// 2. Firebase.initializeApp(...)
///    - Initializes Firebase with current platform configuration
///    - App does NOT continue until Firebase is fully initialized
///
/// 3. runApp(ShipRateApp)
///    - Starts the main application widget
///
/// Future extensions:
/// - Crashlytics / Logging setup
/// - Remote Config initialization
/// - Dependency injection container (GetIt, Riverpod, etc.)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ShipRateApp());
}

/// Root widget for the ShipRate application.
///
/// Responsibilities:
/// - Declare MaterialApp configuration
/// - Register global theme (light/dark)
/// - Define authentication flow via AuthGate
///
/// AuthGate behavior:
/// - Listens to FirebaseAuth state
/// - Redirects to LoginPage when logged out
/// - Redirects to MainScreen when authenticated
class ShipRateApp extends StatelessWidget {
  const ShipRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
