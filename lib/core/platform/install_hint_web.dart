
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'install_hint_service.dart';

/// Web implementation of the installation hint service.
///
/// Uses the Web API `MediaQuery` to detect if the PWA is running:
/// - As an installed PWA (standalone mode)
/// - In the browser (not installed)
///
/// Detection method: `(display-mode: standalone)`
///
/// Returns:
/// - `false`: Already installed as PWA → don't show hint
/// - `true`: Running in browser → suggest installation
class InstallHintWebService implements InstallHintService {
  /// Checks if PWA is running in browser (not installed).
  ///
  /// Uses CSS media query to detect display mode.
  @override
  bool shouldShowInstallHint() {
    final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
    return !mediaQuery.matches;
  }
}

/// Factory function for web platform.
///
/// Returns the web implementation which checks for PWA installation status.
InstallHintService getInstallHintService() => InstallHintWebService();