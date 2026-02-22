import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'app/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'controllers/locale_controller.dart';

/// Entry point for the ShipRate application.
///
/// Responsibilities:
/// - Initialize Flutter binding
/// - Initialize Firebase with platform-specific options
/// - Load saved locale preference
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
/// 3. LocaleController.loadSavedLocale()
///    - Loads the user's saved language preference
///
/// 4. runApp(ShipRateApp)
///    - Starts the main application widget
///
/// Future extensions:
/// - Crashlytics / Logging setup
/// - Remote Config initialization
/// - Dependency injection container (GetIt, Riverpod, etc.)

/// Global locale controller instance, accessible across the app.
final localeController = LocaleController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await localeController.loadSavedLocale();

  runApp(ShipRateApp(localeController: localeController));
}

/// Root widget for the ShipRate application.
///
/// Responsibilities:
/// - Declare MaterialApp configuration
/// - Register global theme (light/dark)
/// - Configure localization (i18n) support
/// - Define authentication flow via AuthGate
///
/// AuthGate behavior:
/// - Listens to FirebaseAuth state
/// - Redirects to LoginPage when logged out
/// - Redirects to MainScreen when authenticated
class ShipRateApp extends StatelessWidget {
  final LocaleController localeController;

  const ShipRateApp({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'ShipRate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,

          // i18n configuration
          locale: localeController.locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const AuthGate(),
        );
      },
    );
  }
}
