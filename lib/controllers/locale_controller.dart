import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing application locale (language).
///
/// Responsibilities:
/// - Load saved locale preference from SharedPreferences
/// - Change locale and persist the preference
/// - Notify listeners when locale changes
class LocaleController extends ChangeNotifier {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _localeKey = 'locale';
  static const Locale _defaultLocale = Locale('pt');
  static const List<Locale> supportedLocales = [
    Locale('pt'),
    Locale('en'),
  ];

  // ===========================================================================
  // STATE
  // ===========================================================================

  Locale _locale = _defaultLocale;

  /// The current locale.
  Locale get locale => _locale;

  // ===========================================================================
  // METHODS
  // ===========================================================================

  /// Loads the saved locale preference from SharedPreferences.
  ///
  /// Falls back to the default locale (pt) if no preference is saved
  /// or if an error occurs during loading.
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null) {
        _locale = Locale(savedLocale);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  /// Changes the application locale and persists the preference.
  ///
  /// [newLocale] must be one of the supported locales.
  Future<void> changeLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, newLocale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale preference: $e');
    }
  }
}
