import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller responsible for ship rating business logic.
///
/// Responsibilities:
/// - Create and save ship ratings
/// - Auto-create ships if they don't exist
/// - Normalize form data
/// - Recalculate aggregated ship averages
/// - Load ships for autocomplete
///
/// Important:
/// - Contains NO UI logic
/// - Does NOT depend on Widgets
/// - Complete separation between presentation and business
///
/// Data Structure:
/// ```
/// navios/{shipId}/
///   - nome: String
///   - imo: String?
///   - medias: Map<String, String>
///   - info: Map<String, dynamic>
///   - avaliacoes/{ratingId}/
///       - usuarioId: String
///       - nomeGuerra: String
///       - dataDesembarque: Timestamp
///       - createdAt: Timestamp (server)
///       - tipoCabine: String
///       - deckCabine: String?
///       - observacaoGeral: String
///       - infoNavio: Map
///       - infoPassadico: Map
///       - itens: Map<String, Map>
/// ```
class RatingController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// Firestore collection names.
  static const String _shipsCollection = 'navios';
  static const String _usersCollection = 'usuarios';
  static const String _ratingsSubcollection = 'avaliacoes';

  /// Official order of rating criteria.
  /// ⚠️ CRITICAL: Do NOT change without migrating existing Firestore data.
  /// This order defines data structure and average calculations.
  static const List<String> _ratingCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// Maps full criteria names to short keys used in 'medias' field.
  /// ⚠️ CRITICAL: Do NOT change without migrating existing data.
  static const Map<String, String> _averageKeyMap = {
    'Dispositivo de Embarque/Desembarque': 'dispositivo',
    'Temperatura da Cabine': 'temp_cabine',
    'Limpeza da Cabine': 'limpeza_cabine',
    'Passadiço – Equipamentos': 'passadico_equip',
    'Passadiço – Temperatura': 'passadico_temp',
    'Comida': 'comida',
    'Relacionamento com comandante/tripulação': 'relacionamento',
  };

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Loads list of ships for autocomplete.
  ///
  /// Returns unique list of ship names and IMOs.
  ///
  /// Example:
  /// ```dart
  /// final ships = await controller.loadShips();
  /// // ['MSC Divina', 'MSC Opera', '9876543', ...]
  /// ```
  Future<List<String>> loadShips() async {
    final snapshot = await _firestore.collection(_shipsCollection).get();
    final names = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['nome'] ?? '').toString().trim();
      final imo = (data['imo'] ?? '').toString().trim();

      if (name.isNotEmpty) names.add(name);
      if (imo.isNotEmpty) names.add(imo);
    }

    return names.toList();
  }

  /// Saves a ship rating.
  ///
  /// Flow:
  /// 1. Validates user authentication
  /// 2. Searches for ship by IMO (priority) or name
  /// 3. Creates ship if it doesn't exist
  /// 4. Fetches pilot's call sign
  /// 5. Normalizes rating data
  /// 6. Saves rating to subcollection
  /// 7. Updates consolidated ship info
  /// 8. Recalculates aggregated averages
  ///
  /// Parameters:
  /// - [nomeNavio]: Ship name
  /// - [imoInicial]: Ship IMO (optional)
  /// - [dataDesembarque]: Pilot's disembarkation date
  /// - [tipoCabine]: Cabin type (Pilot, OWNER, etc.)
  /// - [deckCabine]: Cabin deck (A-G, optional)
  /// - [observacaoGeral]: General observation
  /// - [itens]: Map of criteria with scores and observations
  /// - [infoNavio]: Ship information (optional)
  /// - [infoPassadico]: Bridge information (optional)
  ///
  /// Throws [Exception] if user is not authenticated.
  Future<void> salvarAvaliacao({
    required String nomeNavio,
    required String imoInicial,
    required DateTime dataDesembarque,
    required String tipoCabine,
    String? deckCabine,
    required String observacaoGeral,
    required Map<String, Map<String, dynamic>> itens,
    Map<String, dynamic>? infoNavio,
    Map<String, dynamic>? infoPassadico,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final normalizedName = nomeNavio.trim();
    final normalizedImo = imoInicial.trim();

    // Find or create ship
    final shipRef = await _findOrCreateShip(normalizedName, normalizedImo);

    // Get pilot's call sign
    final callSign = await _getUserCallSign(userId);

    // Normalize data
    final normalizedItems = _normalizeRatingItems(itens);
    final normalizedShipInfo = _normalizeShipInfo(infoNavio);
    final normalizedBridgeInfo = _normalizeBridgeInfo(infoPassadico);

    // Save rating
    await shipRef.collection(_ratingsSubcollection).add({
      'usuarioId': userId,
      'nomeGuerra': callSign,
      'dataDesembarque': Timestamp.fromDate(dataDesembarque),
      'createdAt': FieldValue.serverTimestamp(),
      'tipoCabine': tipoCabine,
      'deckCabine': deckCabine,
      'observacaoGeral': observacaoGeral,
      'infoNavio': normalizedShipInfo,
      'infoPassadico': normalizedBridgeInfo,
      'itens': normalizedItems,
    });

    // Update consolidated ship info (merge)
    if (normalizedShipInfo.isNotEmpty) {
      await shipRef.set({'info': normalizedShipInfo}, SetOptions(merge: true));
    }

    // Recalculate averages
    await _updateAverages(shipRef);
  }

  // ===========================================================================
  // PRIVATE METHODS - SHIP MANAGEMENT
  // ===========================================================================

  /// Finds existing ship or creates a new one.
  ///
  /// Search priority: IMO > Name
  Future<DocumentReference<Map<String, dynamic>>> _findOrCreateShip(
    String name,
    String imo,
  ) async {
    final shipsRef = _firestore.collection(_shipsCollection);

    // Search by IMO first (more reliable), then by name
    QuerySnapshot<Map<String, dynamic>> query;
    if (imo.isNotEmpty) {
      query = await shipsRef.where('imo', isEqualTo: imo).limit(1).get();
    } else {
      query = await shipsRef.where('nome', isEqualTo: name).limit(1).get();
    }

    // Return existing ship reference
    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    // Create new ship
    final newShipRef = shipsRef.doc();
    await newShipRef.set({
      'nome': name,
      'imo': imo.isNotEmpty ? imo : null,
      'medias': {},
      'info': {},
    });

    return newShipRef;
  }

  /// Gets user's call sign from Firestore.
  Future<String> _getUserCallSign(String userId) async {
    final userSnapshot =
        await _firestore.collection(_usersCollection).doc(userId).get();
    return userSnapshot.data()?['nomeGuerra'] ?? 'Prático';
  }

  // ===========================================================================
  // PRIVATE METHODS - DATA NORMALIZATION
  // ===========================================================================

  /// Normalizes rating items to consistent structure.
  Map<String, Map<String, dynamic>> _normalizeRatingItems(
    Map<String, Map<String, dynamic>> items,
  ) {
    return {
      for (final criterion in _ratingCriteria)
        criterion: {
          'nota': _toDouble(items[criterion]?['nota']),
          'observacao': (items[criterion]?['observacao'] ?? '').toString(),
        }
    };
  }

  /// Normalizes ship information.
  Map<String, dynamic> _normalizeShipInfo(Map<String, dynamic>? info) {
    if (info == null) return {};

    final normalized = <String, dynamic>{};

    if (info['nacionalidadeTripulacao'] != null) {
      normalized['nacionalidadeTripulacao'] =
          info['nacionalidadeTripulacao'].toString().trim();
    }

    if (info['numeroCabines'] != null) {
      final cabinCount = info['numeroCabines'];
      normalized['numeroCabines'] =
          cabinCount is int ? cabinCount : int.tryParse(cabinCount.toString()) ?? 0;
    }

    if (info['frigobar'] != null) {
      normalized['frigobar'] = info['frigobar'] == true;
    }

    if (info['pia'] != null) {
      normalized['pia'] = info['pia'] == true;
    }

    if (info['microondas'] != null) {
      normalized['microondas'] = info['microondas'] == true;
    }

    return normalized;
  }

  /// Normalizes bridge information (kept for backwards compatibility).
  Map<String, dynamic> _normalizeBridgeInfo(Map<String, dynamic>? info) {
    if (info == null) return {};

    final normalized = <String, dynamic>{};

    if (info['frigobar'] != null) {
      normalized['frigobar'] = info['frigobar'] == true;
    }
    if (info['pia'] != null) {
      normalized['pia'] = info['pia'] == true;
    }
    if (info['microondas'] != null) {
      normalized['microondas'] = info['microondas'] == true;
    }

    return normalized;
  }

  // ===========================================================================
  // PRIVATE METHODS - AVERAGES
  // ===========================================================================

  /// Recalculates aggregated ship averages.
  ///
  /// Logic:
  /// 1. Fetches all ratings for the ship
  /// 2. Sums scores by criterion
  /// 3. Calculates average (total / count)
  /// 4. Saves to main ship document
  ///
  /// Notes:
  /// - Averages are saved as String with 1 decimal place
  /// - Keys are normalized via [_getAverageKey]
  /// - Ratings without scores are ignored
  Future<void> _updateAverages(
    DocumentReference<Map<String, dynamic>> shipRef,
  ) async {
    final snapshot = await shipRef.collection(_ratingsSubcollection).get();
    if (snapshot.docs.isEmpty) return;

    // Accumulators for sum and count per criterion
    final totals = {for (final c in _ratingCriteria) c: 0.0};
    final counts = {for (final c in _ratingCriteria) c: 0};

    // Sum all ratings
    for (final doc in snapshot.docs) {
      final items = doc.data()['itens'] as Map?;
      if (items == null) continue;

      for (final criterion in _ratingCriteria) {
        final value = items[criterion];
        if (value is Map) {
          final score = _toDouble(value['nota']);
          if (score > 0) {
            totals[criterion] = totals[criterion]! + score;
            counts[criterion] = counts[criterion]! + 1;
          }
        }
      }
    }

    // Calculate final averages
    final averages = <String, String>{};
    for (final criterion in _ratingCriteria) {
      if (counts[criterion]! > 0) {
        final average = totals[criterion]! / counts[criterion]!;
        averages[_getAverageKey(criterion)] = average.toStringAsFixed(1);
      }
    }

    // Update ship document
    await shipRef.update({'medias': averages});
  }

  /// Gets the short key for a criterion (used in 'medias' field).
  String _getAverageKey(String criterion) {
    return _averageKeyMap[criterion] ?? criterion.toLowerCase();
  }

  // ===========================================================================
  // PRIVATE METHODS - HELPERS
  // ===========================================================================

  /// Converts dynamic value to double.
  ///
  /// Accepts: int, double, String (with comma or dot).
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}