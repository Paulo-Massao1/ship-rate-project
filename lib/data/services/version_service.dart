// lib/data/services/version_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:universal_html/html.dart' as html;

/// Service responsible for app version checking and update banner management.
///
/// Compares local version (localStorage) with remote version (Firestore)
/// to determine if an update banner should be displayed.
///
/// Flow:
/// 1. User opens app
/// 2. Service fetches remote version from Firestore
/// 3. Compares with localStorage version
/// 4. If version changed AND banner not seen → show banner
/// 5. User clicks OK → marks as seen
/// 6. User reopens app → local version updates
class VersionService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// LocalStorage key for the current running version.
  static const String _localVersionKey = 'app_local_version';

  /// LocalStorage key for the version whose banner was already seen.
  static const String _seenVersionKey = 'seen_banner_version';

  /// Firestore collection and document path.
  static const String _configCollection = 'config';
  static const String _versionDocument = 'app_version';

  /// Default update message when none is provided.
  static const String _defaultUpdateMessage =
      'Nova atualização disponível. Por favor, feche e reabra o app para aplicar as melhorias.';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Checks if the update banner should be displayed.
  ///
  /// Returns a Map containing:
  /// - `shouldShow` (bool): Whether to display the banner
  /// - `message` (String?): Custom message from Firestore
  /// - `version` (String?): Remote version number
  ///
  /// Decision logic:
  /// - First time → Save version, don't show banner
  /// - Same version → Don't show banner
  /// - Already saw banner for this version → Update local, don't show
  /// - New version detected → Show banner!
  static Future<Map<String, dynamic>> shouldShowUpdateBanner() async {
    try {
      final remoteData = await _fetchRemoteVersion();
      if (remoteData == null) {
        return _noUpdateResult();
      }

      final remoteVersion = remoteData['version'] as String?;
      if (remoteVersion == null) {
        return _noUpdateResult();
      }

      final message = remoteData['message'] as String? ?? _defaultUpdateMessage;
      final localVersion = _getLocalValue(_localVersionKey);
      final seenVersion = _getLocalValue(_seenVersionKey);

      // First time user - save version and skip banner
      if (localVersion == null) {
        _setLocalValue(_localVersionKey, remoteVersion);
        return _noUpdateResult();
      }

      // Same version - no update needed
      if (localVersion == remoteVersion) {
        return _noUpdateResult();
      }

      // Already saw banner - update local version
      if (seenVersion == remoteVersion) {
        _setLocalValue(_localVersionKey, remoteVersion);
        return _noUpdateResult();
      }

      // New version detected - show banner!
      return {
        'shouldShow': true,
        'message': message,
        'version': remoteVersion,
      };
    } catch (e) {
      // Fail-safe: don't show banner on error
      return _noUpdateResult();
    }
  }

  /// Marks the current version's banner as seen.
  ///
  /// Called when user clicks "OK" on the update banner.
  /// Prevents showing the same banner again.
  static Future<void> markBannerAsSeen() async {
    try {
      final remoteData = await _fetchRemoteVersion();
      final remoteVersion = remoteData?['version'] as String?;

      if (remoteVersion != null) {
        _setLocalValue(_seenVersionKey, remoteVersion);
      }
    } catch (e) {
      // Silently ignore - not critical
    }
  }

  /// Clears all version data from localStorage.
  ///
  /// Useful for testing and debugging purposes only.
  static void clearVersionData() {
    html.window.localStorage.remove(_localVersionKey);
    html.window.localStorage.remove(_seenVersionKey);
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Fetches version data from Firestore.
  static Future<Map<String, dynamic>?> _fetchRemoteVersion() async {
    final doc = await FirebaseFirestore.instance
        .collection(_configCollection)
        .doc(_versionDocument)
        .get();

    return doc.exists ? doc.data() : null;
  }

  /// Gets a value from localStorage.
  static String? _getLocalValue(String key) {
    return html.window.localStorage[key];
  }

  /// Sets a value in localStorage.
  static void _setLocalValue(String key, String value) {
    html.window.localStorage[key] = value;
  }

  /// Returns a standard "no update" result.
  static Map<String, dynamic> _noUpdateResult() {
    return {'shouldShow': false, 'message': null};
  }
}