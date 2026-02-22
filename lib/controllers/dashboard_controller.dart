import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Controller for loading dashboard statistics and recent activity.
///
/// Responsibilities:
/// - Count total registered ships
/// - Count total ratings across all ships
/// - Count ratings made by the current user
/// - Load the user's 3 most recent ratings (shipName + date + average)
class DashboardController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _shipsCollection = 'navios';
  static const String _usersCollection = 'usuarios';
  static const String _ratingsSubcollection = 'avaliacoes';
  static const int _recentRatingsLimit = 3;
  static const Duration _queryTimeout = Duration(seconds: 15);

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Gets the current user's ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Loads all dashboard data in a single pass over Firestore.
  ///
  /// Returns a [DashboardData] with totals and recent activity.
  /// Returns [DashboardData.empty] if user is not authenticated.
  /// Returns [DashboardData.empty] on timeout or unrecoverable errors.
  Future<DashboardData> loadDashboardData() async {
    // Use currentUser directly — AuthGate's StreamBuilder guarantees
    // the user is authenticated before this widget is ever mounted.
    // Do NOT use authStateChanges().firstWhere() here: creating a new
    // stream subscription may not replay the current state on Flutter Web,
    // causing an indefinite hang.
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[Dashboard] No authenticated user, returning empty');
      return DashboardData.empty();
    }

    final userId = user.uid;

    try {
      debugPrint('[Dashboard] Loading data for user: $userId');

      // Force token validation before Firestore queries.
      // On Flutter Web, the Firestore JS SDK needs a valid auth token
      // to execute authenticated queries. getIdToken() ensures the token
      // is refreshed and propagated to the SDK — no arbitrary delays needed.
      await user.getIdToken().timeout(_queryTimeout);

      // Step 1: Get user callSign (non-blocking on failure)
      final callSign = await _getUserCallSign(userId);
      debugPrint('[Dashboard] CallSign: $callSign');

      // Step 2: Fetch all ships
      final shipsSnapshot = await _firestore
          .collection(_shipsCollection)
          .get()
          .timeout(_queryTimeout);
      debugPrint('[Dashboard] Ships found: ${shipsSnapshot.docs.length}');

      int totalRatings = 0;
      int userRatings = 0;
      final userRatingsList = <_RatingEntry>[];

      // Step 3: Fetch all ship ratings in parallel instead of sequentially
      final ratingsFutures = shipsSnapshot.docs.map((ship) {
        return ship.reference
            .collection(_ratingsSubcollection)
            .get()
            .timeout(_queryTimeout)
            .then((snapshot) => _ShipRatingsResult(ship: ship, ratings: snapshot))
            .catchError((e) {
          final shipName = ship.data()['nome'] ?? 'Navio sem nome';
          debugPrint('[Dashboard] Error loading ratings for $shipName: $e');
          return _ShipRatingsResult(ship: ship, ratings: null);
        });
      }).toList();

      final results = await Future.wait(ratingsFutures);

      // Step 4: Process results
      for (final result in results) {
        if (result.ratings == null) continue;

        final shipData = result.ship.data() as Map<String, dynamic>;
        final shipName = shipData['nome'] ?? 'Navio sem nome';

        totalRatings += result.ratings!.docs.length;

        for (final rating in result.ratings!.docs) {
          final data = rating.data() as Map<String, dynamic>;

          if (_ratingBelongsToUser(data, userId, callSign)) {
            userRatings++;
            userRatingsList.add(_RatingEntry(
              shipName: shipName,
              data: data,
            ));
          }
        }
      }

      debugPrint('[Dashboard] Total ratings: $totalRatings, user: $userRatings');

      _sortByDateDescending(userRatingsList);

      final recentRatings = userRatingsList
          .take(_recentRatingsLimit)
          .map((entry) => RecentRating(
                shipName: entry.shipName,
                date: _resolveRatingDate(entry.data),
                averageScore: _calculateAverage(entry.data),
              ))
          .toList();

      debugPrint('[Dashboard] Load complete');

      return DashboardData(
        totalShips: shipsSnapshot.docs.length,
        totalRatings: totalRatings,
        userRatings: userRatings,
        recentRatings: recentRatings,
      );
    } catch (e, stack) {
      debugPrint('[Dashboard] FATAL error: $e');
      debugPrint('[Dashboard] Stack: $stack');
      rethrow;
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Gets user callSign. Returns null instead of throwing on failure,
  /// so the dashboard can still load without callSign matching.
  Future<String?> _getUserCallSign(String userId) async {
    try {
      final userSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get()
          .timeout(_queryTimeout);

      if (!userSnapshot.exists) {
        debugPrint('[Dashboard] User doc not found, continuing without callSign');
        return null;
      }

      return userSnapshot.data()?['nomeGuerra'];
    } catch (e) {
      debugPrint('[Dashboard] Error fetching callSign: $e');
      return null;
    }
  }

  bool _ratingBelongsToUser(
    Map<String, dynamic> data,
    String userId,
    String? callSign,
  ) {
    final ratingUserId = data['usuarioId'];
    final ratingCallSign = data['nomeGuerra'];

    return (ratingUserId != null && ratingUserId == userId) ||
        (ratingUserId == null &&
            callSign != null &&
            ratingCallSign == callSign);
  }

  DateTime _resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'];
    if (ts is Timestamp) {
      return ts.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  double _calculateAverage(Map<String, dynamic> data) {
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

  void _sortByDateDescending(List<_RatingEntry> entries) {
    entries.sort((a, b) {
      final aDate = _resolveRatingDate(a.data);
      final bDate = _resolveRatingDate(b.data);
      return bDate.compareTo(aDate);
    });
  }
}

// =============================================================================
// PRIVATE DATA CLASS
// =============================================================================

/// Internal helper to hold the result of a parallel ship ratings query.
class _ShipRatingsResult {
  final QueryDocumentSnapshot ship;
  final QuerySnapshot? ratings;

  _ShipRatingsResult({required this.ship, required this.ratings});
}

/// Internal helper to hold raw rating data before mapping to [RecentRating].
class _RatingEntry {
  final String shipName;
  final Map<String, dynamic> data;

  _RatingEntry({required this.shipName, required this.data});
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Holds all dashboard statistics and recent activity.
class DashboardData {
  final int totalShips;
  final int totalRatings;
  final int userRatings;
  final List<RecentRating> recentRatings;

  DashboardData({
    required this.totalShips,
    required this.totalRatings,
    required this.userRatings,
    required this.recentRatings,
  });

  factory DashboardData.empty() => DashboardData(
        totalShips: 0,
        totalRatings: 0,
        userRatings: 0,
        recentRatings: [],
      );
}

/// Summary of a single recent rating for dashboard display.
class RecentRating {
  final String shipName;
  final DateTime date;
  final double averageScore;

  RecentRating({
    required this.shipName,
    required this.date,
    required this.averageScore,
  });
}
