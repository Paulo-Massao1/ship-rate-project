import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'app/auth_gate.dart';
import 'core/theme/app_theme.dart';
import 'controllers/locale_controller.dart';

final localeController = LocaleController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await localeController.loadSavedLocale();

  runApp(const ShipRateApp());
}

class ShipRateApp extends StatefulWidget {
  const ShipRateApp({super.key});

  @override
  State<ShipRateApp> createState() => _ShipRateAppState();
}

class _ShipRateAppState extends State<ShipRateApp> {
  @override
  void initState() {
    super.initState();
    localeController.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    localeController.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: localeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}
