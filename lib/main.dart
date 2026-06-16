import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'app/auth_gate.dart';
import 'core/app_cache.dart';
import 'core/theme/app_theme.dart';
import 'controllers/locale_controller.dart';
import 'data/services/notification_service.dart';

final localeController = LocaleController();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Scaffold(
    backgroundColor: Color(0xFF0A1628),
    body: Center(
      child: Text(
        '${details.exception}',
        style: TextStyle(color: Colors.red),
      ),
    ),
  );
  runApp(const StartupWidget());
}

class StartupWidget extends StatefulWidget {
  const StartupWidget({super.key});

  static bool firebaseReady = false;

  @override
  State<StartupWidget> createState() => _StartupWidgetState();
}

class _StartupWidgetState extends State<StartupWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      StartupWidget.firebaseReady = true;
    } catch (e) {
      if (e.toString().contains('duplicate-app') ||
          e.toString().contains('already been initialized')) {
        StartupWidget.firebaseReady = true;
      } else {
        debugPrint('Firebase initialization error: $e');
      }
    }

    if (StartupWidget.firebaseReady && kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      AppCache.nomeGuerra = prefs.getString('cached_nomeGuerra');
      AppCache.stats = {
        'ships': prefs.getInt('cached_ships') ?? 0,
        'ratings': prefs.getInt('cached_ratings') ?? 0,
        'crossings': prefs.getInt('cached_crossings') ?? 0,
        'pilots': prefs.getInt('cached_pilots') ?? 0,
        'topRaterCount': prefs.getInt('cached_topRaterCount') ?? 0,
      };
    } catch (e) {
      debugPrint('SharedPreferences initialization error: $e');
    }

    try {
      await localeController
          .loadSavedLocale()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Locale loading error: $e');
    }

    try {
      await NotificationService.setupNotificationTapHandlers()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Notification setup error: $e');
    }

    if (kIsWeb) {
      final route = Uri.base.queryParameters['route'];
      if (route == 'nav_safety' || route == 'crossing') {
        NotificationService.pendingRoute ??= route;
      }
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A1628),
        ),
      );
    }

    return ShipRateApp(localeController: localeController);
  }
}

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
