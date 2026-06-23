// lib/data/services/version_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service responsible for checking whether a newer app version is available.
class VersionService {
  static const String _configCollection = 'config';
  static const String _versionDocument = 'app_version';

  /// Firestore fields to update after each platform release is available.
  static const String iosVersionField = 'iosVersion';
  static const String webVersionField = 'webVersion';
  static const String _legacyVersionField = 'version';

  /// Checks the installed version against the current platform's remote version.
  static Future<Map<String, dynamic>> shouldShowUpdateBanner() async {
    try {
      final versionField = _versionFieldForCurrentPlatform;
      if (versionField == null) return _noUpdateResult();

      final packageInfo = await PackageInfo.fromPlatform(
        baseUrl: kIsWeb ? Uri.base.origin : null,
      );
      final installedVersion = packageInfo.version.trim();
      if (installedVersion.isEmpty) return _noUpdateResult();

      final remoteData = await _fetchRemoteVersion();
      final remoteValue =
          remoteData?[versionField] ?? remoteData?[_legacyVersionField];

      if (remoteValue is! String || remoteValue.trim().isEmpty) {
        return _noUpdateResult();
      }

      final remoteVersion = remoteValue.trim();

      return {
        'shouldShow': _isNewerVersion(
          candidateVersion: remoteVersion,
          currentVersion: installedVersion,
        ),
        'version': remoteVersion,
      };
    } catch (error, stackTrace) {
      // Fail safely when Firestore is unavailable or contains invalid data.
      debugPrint('[VersionService] Update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _noUpdateResult();
    }
  }

  static String? get _versionFieldForCurrentPlatform {
    if (kIsWeb) return webVersionField;
    if (defaultTargetPlatform == TargetPlatform.iOS) return iosVersionField;
    return null;
  }

  static Future<Map<String, dynamic>?> _fetchRemoteVersion() async {
    final doc =
        await FirebaseFirestore.instance
            .collection(_configCollection)
            .doc(_versionDocument)
            .get();

    return doc.exists ? doc.data() : null;
  }

  static bool _isNewerVersion({
    required String candidateVersion,
    required String currentVersion,
  }) {
    final candidateParts = _parseVersion(candidateVersion);
    final currentParts = _parseVersion(currentVersion);

    if (candidateParts == null || currentParts == null) return false;

    final partCount =
        candidateParts.length > currentParts.length
            ? candidateParts.length
            : currentParts.length;

    for (var index = 0; index < partCount; index++) {
      final candidatePart =
          index < candidateParts.length ? candidateParts[index] : 0;
      final currentPart = index < currentParts.length ? currentParts[index] : 0;

      if (candidatePart > currentPart) return true;
      if (candidatePart < currentPart) return false;
    }

    return false;
  }

  static List<int>? _parseVersion(String version) {
    var normalized = version.trim().split('+').first.split('-').first;
    if (normalized.toLowerCase().startsWith('v')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty) return null;

    final parts = <int>[];
    for (final part in normalized.split('.')) {
      final parsedPart = int.tryParse(part);
      if (parsedPart == null) return null;
      parts.add(parsedPart);
    }

    return parts;
  }

  static Map<String, dynamic> _noUpdateResult() {
    return {'shouldShow': false, 'version': null};
  }
}
