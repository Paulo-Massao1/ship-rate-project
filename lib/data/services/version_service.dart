// lib/data/services/version_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for app version checking and update banner management.
///
/// Compares the locally stored version with the remote version (Firestore)
/// to determine if an update banner should be displayed.
///
/// Flow:
/// 1. User opens app
/// 2. Service fetches remote version from Firestore
/// 3. Compares with the locally stored version
/// 4. If version changed AND banner not seen → show banner
/// 5. User clicks OK → marks as seen
/// 6. User reopens app → local version updates
class VersionService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// Local preference key for the current running version.
  static const String _localVersionKey = 'app_local_version';

  /// Local preference key for the version whose banner was already seen.
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
      final preferences = await SharedPreferences.getInstance();
      final localVersion = preferences.getString(_localVersionKey);
      final seenVersion = preferences.getString(_seenVersionKey);

      // First time user - save version and skip banner
      if (localVersion == null) {
        await preferences.setString(_localVersionKey, remoteVersion);
        return _noUpdateResult();
      }

      // Same version - no update needed
      if (localVersion == remoteVersion) {
        return _noUpdateResult();
      }

      // Already saw banner - update local version
      if (seenVersion == remoteVersion) {
        await preferences.setString(_localVersionKey, remoteVersion);
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
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_seenVersionKey, remoteVersion);
      }
    } catch (e) {
      // Silently ignore - not critical
    }
  }

  /// Clears all locally stored version data.
  ///
  /// Useful for testing and debugging purposes only.
  static Future<void> clearVersionData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_localVersionKey);
    await preferences.remove(_seenVersionKey);
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

  /// Returns a standard "no update" result.
  static Map<String, dynamic> _noUpdateResult() {
    return {'shouldShow': false, 'message': null};
  }
}
