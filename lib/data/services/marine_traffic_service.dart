import 'package:universal_html/html.dart' as html;

/// Service for opening MarineTraffic website.
///
/// Opens the ship's specific page if IMO is available,
/// otherwise opens the main MarineTraffic page.
class MarineTrafficService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _baseUrl = 'https://www.marinetraffic.com';
  static const String _shipDetailPath = '/en/ais/details/ships/imo:';

  /// IMO values considered invalid.
  static const List<String> _invalidImoValues = ['', 'N/A', '0', 'null'];

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Opens MarineTraffic in a new browser tab.
  ///
  /// Parameters:
  /// - [shipName]: Ship name (kept for API compatibility, not currently used)
  /// - [imo]: Optional IMO number for direct ship page access
  ///
  /// Returns `true` if opened successfully, `false` on error.
  static Future<bool> openMarineTraffic({
    required String shipName,
    String? imo,
  }) async {
    try {
      final url = _buildUrl(imo);
      html.window.open(url, '_blank');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Builds the appropriate URL based on IMO availability.
  static String _buildUrl(String? imo) {
    if (_isValidImo(imo)) {
      return '$_baseUrl$_shipDetailPath$imo';
    }
    return _baseUrl;
  }

  /// Checks if IMO is valid and usable.
  static bool _isValidImo(String? imo) {
    if (imo == null) return false;
    return !_invalidImoValues.contains(imo);
  }
}