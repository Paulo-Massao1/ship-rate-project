import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
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
  runApp(const StartupWidget());
}

class StartupWidget extends StatefulWidget {
  const StartupWidget({super.key});

  static bool firebaseReady = false;
  static String? firebaseError;

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
    StartupWidget.firebaseReady = false;
    StartupWidget.firebaseError = null;

    try {
      await _initializeFirebase();
      StartupWidget.firebaseReady = true;
      debugPrint('Firebase init SUCCESS');
    } catch (e, stackTrace) {
      StartupWidget.firebaseError = e.toString();
      debugPrint('Firebase init failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (StartupWidget.firebaseReady && kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e) {
        debugPrint('Firestore web persistence setup skipped: $e');
      }
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

    if (StartupWidget.firebaseReady) {
      try {
        await NotificationService.setupNotificationTapHandlers()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Notification setup error: $e');
      }
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

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;

    if (kIsWeb) {
      await _initializeFirebaseWeb();
      return;
    }

    // On iOS the native app is configured from GoogleService-Info.plist.
    // Initialize Dart Firebase from that default app first, then fall back.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 20));
        return;
      } catch (e) {
        debugPrint('Native iOS Firebase default init failed: $e');
      }
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));
  }

  Future<void> _initializeFirebaseWeb() async {
    const timeout = Duration(seconds: 45);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      ).timeout(timeout);
      return;
    } catch (e) {
      debugPrint('Firebase web init first attempt failed: $e');
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    if (Firebase.apps.isNotEmpty) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    ).timeout(timeout);
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
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}
