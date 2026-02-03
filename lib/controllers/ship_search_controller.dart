import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/marine_traffic_service.dart';

/// Controller for ship search functionality.
///
/// Responsibilities:
/// - Search ships by name or IMO
/// - Load ship ratings
/// - Open MarineTraffic
/// - Manage ship data display
class ShipSearchController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _shipsCollection = 'navios';
  static const String _ratingsSubcollection = 'avaliacoes';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Searches ships by name or IMO.
  Future<List<QueryDocumentSnapshot>> searchShips(String query) async {
    if (query.isEmpty) return [];

    final term = query.toLowerCase().trim();
    final results = <String, QueryDocumentSnapshot>{};

    final snapshot = await _firestore.collection(_shipsCollection).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['nome'] as String? ?? '').toLowerCase();
      final imo = (data['imo'] as String? ?? '').toLowerCase();

      if (name.contains(term) || (imo.isNotEmpty && imo.contains(term))) {
        results[doc.id] = doc;
      }
    }

    return results.values.toList();
  }

  /// Loads all ratings for a ship.
  Future<List<QueryDocumentSnapshot>> loadShipRatings(String shipId) async {
    final ratingsSnapshot = await _firestore
        .collection(_shipsCollection)
        .doc(shipId)
        .collection(_ratingsSubcollection)
        .get();

    final ratingsList = ratingsSnapshot.docs;
    _sortByDateDescending(ratingsList);

    return ratingsList;
  }

  /// Opens MarineTraffic for a ship.
  Future<bool> openMarineTraffic({
    required String shipName,
    String? imo,
  }) async {
    return MarineTrafficService.openMarineTraffic(
      shipName: shipName,
      imo: imo,
    );
  }

  /// Extracts ship display data from document.
  ShipDisplayData extractShipData(QueryDocumentSnapshot ship) {
    final data = ship.data() as Map<String, dynamic>;

    return ShipDisplayData(
      id: ship.id,
      name: data['nome'] ?? 'Navio sem nome',
      imo: data['imo'],
      averages: (data['medias'] ?? {}) as Map<String, dynamic>,
      info: (data['info'] ?? {}) as Map<String, dynamic>,
    );
  }

  /// Resolves amenities from ship info and ratings (legacy support).
  Map<String, bool?> resolveAmenities(
    Map<String, dynamic> info,
    List<QueryDocumentSnapshot>? ratings,
  ) {
    bool? frigobar = info['frigobar'];
    bool? pia = info['pia'];
    bool? microondas = info['microondas'];

    // Fallback to ratings data (legacy support)
    if (frigobar == null && pia == null && microondas == null) {
      if (ratings != null && ratings.isNotEmpty) {
        final lastRatingData = ratings.first.data() as Map<String, dynamic>;
        final bridgeInfo =
            (lastRatingData['infoPassadico'] ?? {}) as Map<String, dynamic>;

        frigobar = bridgeInfo['frigobar'] as bool?;
        pia = bridgeInfo['pia'] as bool?;
        microondas = bridgeInfo['microondas'] as bool?;
      }
    }

    return {
      'frigobar': frigobar,
      'pia': pia,
      'microondas': microondas,
    };
  }

  /// Calculates relative time string from timestamp.
  String getRelativeTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Avaliado agora';

    final date = timestamp.toDate().toUtc();
    final now = DateTime.now().toUtc();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Avaliado agora';
    if (diff.inMinutes < 60) return 'Avaliado há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Avaliado há ${diff.inHours}h';
    if (diff.inDays == 1) return 'Avaliado ontem';
    if (diff.inDays < 7) return 'Avaliado há ${diff.inDays} dias';

    return 'Avaliado em ${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  void _sortByDateDescending(List<QueryDocumentSnapshot> ratings) {
    ratings.sort((a, b) {
      final aData = a.data() as Map;
      final bData = b.data() as Map;

      final aTimestamp = aData['dataDesembarque'] ?? aData['data'] ?? Timestamp.now();
      final bTimestamp = bData['dataDesembarque'] ?? bData['data'] ?? Timestamp.now();

      return bTimestamp.compareTo(aTimestamp);
    });
  }
}

// =============================================================================
// DATA CLASS
// =============================================================================

/// Data class for ship display information.
class ShipDisplayData {
  final String id;
  final String name;
  final String? imo;
  final Map<String, dynamic> averages;
  final Map<String, dynamic> info;

  ShipDisplayData({
    required this.id,
    required this.name,
    required this.imo,
    required this.averages,
    required this.info,
  });
}