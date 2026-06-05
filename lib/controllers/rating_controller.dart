import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/services/medias_calculator.dart';

/// Controller responsible for ship rating business logic.
///
/// Responsibilities:
/// - Create and save ship ratings
/// - Auto-create ships if they don't exist
/// - Normalize form data
/// - Recalculate aggregated ship averages
/// - Load ships for autocomplete
/// - Load recent rated ships summaries
/// - Manage likes for ship ratings
class RatingController extends ChangeNotifier {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const Duration _cacheStaleThreshold = Duration(seconds: 30);

  // ===========================================================================
  // CACHE
  // ===========================================================================

  static List<LastRatedShipItem>? _cachedLastRatedShips;
  static DateTime? _lastRatedShipsFetchTime;

  static final Map<String, bool> _cachedLikeStates = {};
  static final Map<String, int> _cachedLikeCounts = {};
  static final Map<String, List<String>> _cachedLikerNames = {};
  static final Map<String, String> _cachedRatingOwnerIds = {};

  static String? _currentUserCallSign;

  // ===========================================================================
  // PUBLIC GETTERS
  // ===========================================================================

  String? get currentUserId => _auth.currentUser?.uid;

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Loads list of ships for autocomplete.
  ///
  /// Returns unique list of ship names and IMOs.
  Future<List<String>> loadShips() async {
    final snapshot = await _firestore.collection(AppConstants.shipsCollection).get();
    final names = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Skip merged ships
      if (data['merged'] == true) continue;

      final name = (data['nome'] ?? '').toString().trim();
      final imo = (data['imo'] ?? '').toString().trim();

      if (name.isNotEmpty) names.add(name);
      if (imo.isNotEmpty) names.add(imo);
    }

    return names.toList();
  }

  /// Loads the ships whose latest rating is the most recent across the app.
  ///
  /// Each item represents a single ship with its latest available rating.
  Future<List<LastRatedShipItem>> loadLastRatedShips({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedLastRatedShips != null &&
        !_isCacheStale(_lastRatedShipsFetchTime)) {
      return _cachedLastRatedShips!;
    }

    final shipsSnapshot = await _firestore.collection(AppConstants.shipsCollection).get();
    final shipDocs = shipsSnapshot.docs.where((doc) => doc.data()['merged'] != true).toList();

    final futures = shipDocs.map(_loadLatestRatingForShip);
    final results = await Future.wait(futures);

    final items = results.whereType<LastRatedShipItem>().toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    _cachedLastRatedShips = items.take(limit).toList();
    _lastRatedShipsFetchTime = DateTime.now();
    return _cachedLastRatedShips!;
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
    String? existingShipId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final normalizedName = nomeNavio.trim();
    final normalizedImo = imoInicial.trim();

    // Find or create ship
    final DocumentReference<Map<String, dynamic>> shipRef;
    if (existingShipId != null) {
      shipRef = _firestore.collection(AppConstants.shipsCollection).doc(existingShipId);
      if (normalizedImo.isNotEmpty) {
        await shipRef.update({'imo': normalizedImo});
      }
    } else {
      shipRef = await _findOrCreateShip(normalizedName, normalizedImo);
    }

    // Get pilot's call sign
    final callSign = await _getUserCallSign(userId);

    // Normalize data
    final normalizedItems = _normalizeRatingItems(itens);
    final normalizedShipInfo = _normalizeShipInfo(infoNavio);
    final normalizedBridgeInfo = _normalizeBridgeInfo(infoPassadico);

    // Save rating
    await shipRef.collection(AppConstants.ratingsSubcollection).add({
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

    if (normalizedShipInfo.isNotEmpty) {
      await shipRef.set({'info': normalizedShipInfo}, SetOptions(merge: true));
    }

    await _updateAverages(shipRef);
    _invalidateRecentShipsCache();
  }

  /// Toggles a like for a ship rating using optimistic updates.
  Future<void> toggleRatingLike(String shipId, String ratingId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final key = _ratingLikeKey(shipId, ratingId);
    final cachedOwnerId = _cachedRatingOwnerIds[key];
    final ownerId = cachedOwnerId != null && cachedOwnerId.isNotEmpty
        ? cachedOwnerId
        : await _loadRatingOwnerId(shipId, ratingId);
    if (ownerId == uid) return;

    final likeRef = _firestore
        .collection(AppConstants.shipsCollection)
        .doc(shipId)
        .collection(AppConstants.ratingsSubcollection)
        .doc(ratingId)
        .collection(AppConstants.likesSubcollection)
        .doc(uid);

    final liked = _cachedLikeStates[key] ?? false;

    if (liked) {
      final userName = await _getCurrentUserCallSign();
      _cachedLikeStates[key] = false;
      _cachedLikeCounts[key] = ((_cachedLikeCounts[key] ?? 1) - 1).clamp(0, 999999);
      _cachedLikerNames[key]?.remove(userName);
      notifyListeners();

      try {
        await likeRef.delete();
      } catch (e) {
        _cachedLikeStates[key] = true;
        _cachedLikeCounts[key] = (_cachedLikeCounts[key] ?? 0) + 1;
        if (userName.isNotEmpty) {
          _cachedLikerNames[key] ??= [];
          if (!_cachedLikerNames[key]!.contains(userName)) {
            _cachedLikerNames[key]!.insert(0, userName);
          }
        }
        notifyListeners();
        debugPrint('[Ratings] Error removing rating like: $e');
      }
      return;
    }

    final nomeGuerra = await _getCurrentUserCallSign();
    _cachedLikeStates[key] = true;
    _cachedLikeCounts[key] = (_cachedLikeCounts[key] ?? 0) + 1;
    if (nomeGuerra.isNotEmpty) {
      _cachedLikerNames[key] ??= [];
      if (!_cachedLikerNames[key]!.contains(nomeGuerra)) {
        _cachedLikerNames[key]!.insert(0, nomeGuerra);
      }
    }
    notifyListeners();

    try {
      await likeRef.set({
        'nomeGuerra': nomeGuerra,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _cachedLikeStates[key] = false;
      _cachedLikeCounts[key] = ((_cachedLikeCounts[key] ?? 1) - 1).clamp(0, 999999);
      _cachedLikerNames[key]?.remove(nomeGuerra);
      notifyListeners();
      debugPrint('[Ratings] Error adding rating like: $e');
    }
  }

  /// Returns whether the current user has liked a rating.
  bool hasUserLikedRating(String shipId, String ratingId) {
    return _cachedLikeStates[_ratingLikeKey(shipId, ratingId)] ?? false;
  }

  /// Returns the cached like count for a rating.
  int getRatingLikeCount(String shipId, String ratingId) {
    return _cachedLikeCounts[_ratingLikeKey(shipId, ratingId)] ?? 0;
  }

  /// Returns the cached liker names for a rating.
  List<String> getRatingLikerNames(String shipId, String ratingId) {
    return _cachedLikerNames[_ratingLikeKey(shipId, ratingId)] ?? const <String>[];
  }

  /// Loads like state, count, and recent liker names for a list of ratings.
  Future<void> loadRatingLikeStates(
    String shipId,
    List<String> ratingIds, {
    bool notify = true,
  }) async {
    final uid = currentUserId;
    if (uid == null || ratingIds.isEmpty) return;

    final futures = ratingIds.map((ratingId) {
      return _loadLikeStateForRating(
        uid: uid,
        shipId: shipId,
        ratingId: ratingId,
      );
    });

    await Future.wait(futures);
    if (notify) notifyListeners();
  }

  /// Fetches all liker names for the rating, used by the bottom sheet.
  Future<List<String>> fetchAllRatingLikerNames(
    String shipId,
    String ratingId,
  ) async {
    final likesSnapshot = await _firestore
        .collection(AppConstants.shipsCollection)
        .doc(shipId)
        .collection(AppConstants.ratingsSubcollection)
        .doc(ratingId)
        .collection(AppConstants.likesSubcollection)
        .orderBy('timestamp', descending: true)
        .get();

    return _resolveLikeNames(likesSnapshot.docs);
  }

  /// Calculates the average rating from rating items.
  double calculateAverageRating(Map<String, dynamic> data) {
    final itens = data['itens'] as Map<String, dynamic>?;
    if (itens == null || itens.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final item in itens.values) {
      if (item is Map<String, dynamic>) {
        final nota = item['nota'];
        if (nota is num) {
          total += nota.toDouble();
          count++;
        }
      }
    }

    return count > 0 ? total / count : 0.0;
  }

  /// Resolves the rating date used for recency sorting and display.
  DateTime resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'] ?? data['dataDesembarque'];
    if (ts is Timestamp) {
      return ts.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Formats a date as dd/MM/yyyy.
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ===========================================================================
  // PRIVATE METHODS - SHIP MANAGEMENT
  // ===========================================================================

  Future<DocumentReference<Map<String, dynamic>>> _findOrCreateShip(
    String name,
    String imo,
  ) async {
    final shipsRef = _firestore.collection(AppConstants.shipsCollection);

    QuerySnapshot<Map<String, dynamic>> query;
    if (imo.isNotEmpty) {
      query = await shipsRef.where('imo', isEqualTo: imo).limit(1).get();
    } else {
      query = await shipsRef.where('nome', isEqualTo: name).limit(1).get();
    }

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();

      if (data['merged'] == true && data['mergedInto'] != null) {
        return _firestore.collection(AppConstants.shipsCollection).doc(data['mergedInto']);
      }
      return doc.reference;
    }

    final newShipRef = shipsRef.doc();
    await newShipRef.set({
      'nome': name,
      'imo': imo.isNotEmpty ? imo : null,
      'medias': {},
      'info': {},
    });

    return newShipRef;
  }

  Future<LastRatedShipItem?> _loadLatestRatingForShip(
    QueryDocumentSnapshot<Map<String, dynamic>> shipDoc,
  ) async {
    try {
      final ratingsSnapshot =
          await shipDoc.reference.collection(AppConstants.ratingsSubcollection).get();
      if (ratingsSnapshot.docs.isEmpty) return null;

      QueryDocumentSnapshot<Map<String, dynamic>>? latestRating;
      var latestDate = DateTime.fromMillisecondsSinceEpoch(0);

      for (final ratingDoc in ratingsSnapshot.docs) {
        final ratingDate = resolveRatingDate(ratingDoc.data());
        if (latestRating == null || ratingDate.isAfter(latestDate)) {
          latestRating = ratingDoc;
          latestDate = ratingDate;
        }
      }

      if (latestRating == null) return null;

      final shipData = shipDoc.data();
      final ratingData = latestRating.data();
      final shipName = (shipData['nome'] ?? '').toString().trim();
      final shipImo = (shipData['imo'] ?? '').toString().trim();
      final ratedBy = (ratingData['nomeGuerra'] ?? '').toString().trim();
      final userId = (ratingData['usuarioId'] ?? '').toString().trim();
      final likeCount = ratingData['likeCount'] as int? ?? 0;
      final key = _ratingLikeKey(shipDoc.id, latestRating.id);

      _cachedLikeCounts[key] = likeCount;
      if (userId.isNotEmpty) {
        _cachedRatingOwnerIds[key] = userId;
      }

      return LastRatedShipItem(
        shipId: shipDoc.id,
        shipName: shipName,
        shipImo: shipImo,
        rating: latestRating,
        ratedBy: ratedBy,
        userId: userId,
        date: latestDate,
        averageScore: calculateAverageRating(ratingData),
      );
    } catch (e) {
      debugPrint('[Ratings] Error loading latest rating for ship ${shipDoc.id}: $e');
      return null;
    }
  }

  Future<String> _getUserCallSign(String userId) async {
    final userSnapshot =
        await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
    return (userSnapshot.data()?['nomeGuerra'] ?? 'Prático').toString();
  }

  Future<String> _getCurrentUserCallSign() async {
    if (_currentUserCallSign != null && _currentUserCallSign!.isNotEmpty) {
      return _currentUserCallSign!;
    }

    final userId = currentUserId;
    if (userId == null) return '';

    final authDisplayName = (_auth.currentUser?.displayName ?? '').trim();

    try {
      final userDoc =
          await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      final firestoreName = (userDoc.data()?['nomeGuerra'] ?? '').toString().trim();
      _currentUserCallSign = firestoreName.isNotEmpty ? firestoreName : authDisplayName;
    } catch (_) {
      _currentUserCallSign = authDisplayName;
    }

    return _currentUserCallSign ?? '';
  }

  // ===========================================================================
  // PRIVATE METHODS - DATA NORMALIZATION
  // ===========================================================================

  Map<String, Map<String, dynamic>> _normalizeRatingItems(
    Map<String, Map<String, dynamic>> items,
  ) {
    return {
      for (final criterion in MediasCalculator.ratingCriteria)
        criterion: {
          'nota': _toDouble(items[criterion]?['nota']),
          'observacao': (items[criterion]?['observacao'] ?? '').toString(),
        }
    };
  }

  Map<String, dynamic> _normalizeShipInfo(Map<String, dynamic>? info) {
    if (info == null) return {};

    final normalized = <String, dynamic>{};

    if (info['nacionalidadeTripulacao'] != null) {
      final nationality = info['nacionalidadeTripulacao'];
      if (nationality is List) {
        final filtered = nationality
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (filtered.isNotEmpty) {
          normalized['nacionalidadeTripulacao'] = filtered;
        }
      } else {
        final value = nationality.toString().trim();
        if (value.isNotEmpty) {
          normalized['nacionalidadeTripulacao'] = [value];
        }
      }
    }

    if (info['numeroCabines'] != null) {
      final cabinCount = info['numeroCabines'];
      if (cabinCount is int) {
        if (cabinCount > 0) {
          normalized['numeroCabines'] = cabinCount >= 3 ? '3+' : cabinCount.toString();
        }
      } else if (cabinCount is String && ['1', '2', '3+'].contains(cabinCount)) {
        normalized['numeroCabines'] = cabinCount;
      }
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
  // PRIVATE METHODS - LIKES
  // ===========================================================================

  String _ratingLikeKey(String shipId, String ratingId) => '$shipId/$ratingId';

  Future<void> _loadLikeStateForRating({
    required String uid,
    required String shipId,
    required String ratingId,
  }) async {
    final ratingRef = _firestore
        .collection(AppConstants.shipsCollection)
        .doc(shipId)
        .collection(AppConstants.ratingsSubcollection)
        .doc(ratingId);

    final ratingDoc = await ratingRef.get();
    if (!ratingDoc.exists) return;

    final ratingData = ratingDoc.data() ?? const <String, dynamic>{};
    final key = _ratingLikeKey(shipId, ratingId);
    final serverLikeCount = ratingData['likeCount'] as int? ?? 0;
    final ownerId = (ratingData['usuarioId'] ?? '').toString().trim();
    if (ownerId.isNotEmpty) {
      _cachedRatingOwnerIds[key] = ownerId;
    }

    final shouldRefresh = !_cachedLikeStates.containsKey(key) ||
        _cachedLikeCounts[key] != serverLikeCount ||
        (serverLikeCount > 0 && (_cachedLikerNames[key]?.isEmpty ?? true));
    if (!shouldRefresh) return;

    final likesRef = ratingRef.collection(AppConstants.likesSubcollection);
    final userLikeDoc = await likesRef.doc(uid).get();
    _cachedLikeStates[key] = userLikeDoc.exists;
    _cachedLikeCounts[key] = serverLikeCount;

    final likesSnapshot =
        await likesRef.orderBy('timestamp', descending: true).limit(5).get();
    _cachedLikerNames[key] = await _resolveLikeNames(likesSnapshot.docs);
  }

  Future<String> _loadRatingOwnerId(String shipId, String ratingId) async {
    final ratingDoc = await _firestore
        .collection(AppConstants.shipsCollection)
        .doc(shipId)
        .collection(AppConstants.ratingsSubcollection)
        .doc(ratingId)
        .get();
    if (!ratingDoc.exists) return '';

    final ownerId = (ratingDoc.data()?['usuarioId'] ?? '').toString().trim();
    final key = _ratingLikeKey(shipId, ratingId);
    if (ownerId.isNotEmpty) {
      _cachedRatingOwnerIds[key] = ownerId;
    }
    _cachedLikeCounts[key] = ratingDoc.data()?['likeCount'] as int? ?? 0;
    return ownerId;
  }

  Future<List<String>> _resolveLikeNames(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> likeDocs,
  ) async {
    final names = await Future.wait(likeDocs.map(_resolveLikeName));
    return names.where((name) => name.isNotEmpty).toList();
  }

  Future<String> _resolveLikeName(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final storedName = (doc.data()['nomeGuerra'] ?? '').toString().trim();
    if (storedName.isNotEmpty) return storedName;

    try {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(doc.id).get();
      final fallbackName = (userDoc.data()?['nomeGuerra'] ?? '').toString().trim();
      if (fallbackName.isNotEmpty) {
        await doc.reference.set({
          'nomeGuerra': fallbackName,
        }, SetOptions(merge: true));
      }
      return fallbackName;
    } catch (_) {
      return '';
    }
  }

  // ===========================================================================
  // PRIVATE METHODS - AVERAGES
  // ===========================================================================

  Future<void> _updateAverages(
    DocumentReference<Map<String, dynamic>> shipRef,
  ) async {
    final snapshot = await shipRef.collection(AppConstants.ratingsSubcollection).get();
    if (snapshot.docs.isEmpty) return;

    final averages = MediasCalculator.calculate(snapshot.docs.map((d) => d.data()));
    await shipRef.update({'medias': averages});
  }

  // ===========================================================================
  // PRIVATE METHODS - HELPERS
  // ===========================================================================

  bool _isCacheStale(DateTime? fetchTime) {
    if (fetchTime == null) return true;
    return DateTime.now().difference(fetchTime) > _cacheStaleThreshold;
  }

  static void clearAllCaches() {
    _cachedLastRatedShips = null;
    _lastRatedShipsFetchTime = null;
    _cachedLikeStates.clear();
    _cachedLikeCounts.clear();
    _cachedLikerNames.clear();
    _cachedRatingOwnerIds.clear();
    _currentUserCallSign = null;
  }

  void _invalidateRecentShipsCache() {
    _cachedLastRatedShips = null;
    _lastRatedShipsFetchTime = null;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Summary model used by the "Last rated ships" page.
class LastRatedShipItem {
  final String shipId;
  final String shipName;
  final String shipImo;
  final QueryDocumentSnapshot<Map<String, dynamic>> rating;
  final String ratedBy;
  final String userId;
  final DateTime date;
  final double averageScore;

  LastRatedShipItem({
    required this.shipId,
    required this.shipName,
    required this.shipImo,
    required this.rating,
    required this.ratedBy,
    required this.userId,
    required this.date,
    required this.averageScore,
  });

  String get ratingId => rating.id;

  int get serverLikeCount => (rating.data()['likeCount'] as int?) ?? 0;
}
