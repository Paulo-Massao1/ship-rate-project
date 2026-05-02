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
  Future<DashboardData> loadDashboardData() async {
    // Use currentUser directly — AuthGate's StreamBuilder guarantees
    // the user is authenticated before this widget is ever mounted.
    final user = _auth.currentUser;
    if (user == null) return DashboardData.empty();

    final userId = user.uid;

    try {
      // Force token validation before Firestore queries.
      // On Flutter Web, the Firestore JS SDK needs a valid auth token.
      await user.getIdToken().timeout(_queryTimeout);

      // Fetch callSign and ships in parallel
      final results = await Future.wait([
        _getUserCallSign(userId),
        _firestore.collection(_shipsCollection).get().timeout(_queryTimeout),
      ]);

      final callSign = results[0] as String?;
      final shipsSnapshot = results[1] as QuerySnapshot;

      int totalRatings = 0;
      int userRatings = 0;
      final userRatingsList = <_RatingEntry>[];
      String? lastRatedShipName;
      String? lastRatedByPilot;
      DateTime? lastRatedDate;

      // Fetch all ship ratings in parallel
      final ratingsFutures = shipsSnapshot.docs.map((ship) {
        return ship.reference
            .collection(_ratingsSubcollection)
            .get()
            .timeout(_queryTimeout)
            .then((snapshot) => _ShipRatingsResult(ship: ship, ratings: snapshot))
            .catchError((e) {
          return _ShipRatingsResult(ship: ship, ratings: null);
        });
      }).toList();

      final ratingsResults = await Future.wait(ratingsFutures);

      for (final result in ratingsResults) {
        if (result.ratings == null) continue;

        final shipData = result.ship.data() as Map<String, dynamic>;
        final shipName = shipData['nome'] ?? 'Navio sem nome';

        totalRatings += result.ratings!.docs.length;

        for (final rating in result.ratings!.docs) {
          final data = rating.data() as Map<String, dynamic>;

          final ratingDate = _resolveRatingDate(data);
          if (ratingDate.millisecondsSinceEpoch > 0 &&
              (lastRatedDate == null || ratingDate.isAfter(lastRatedDate))) {
            lastRatedDate = ratingDate;
            lastRatedShipName = shipName;
            lastRatedByPilot = data['nomeGuerra'] as String?;
          }

          if (_ratingBelongsToUser(data, userId, callSign)) {
            userRatings++;
            userRatingsList.add(_RatingEntry(
              shipName: shipName,
              data: data,
            ));
          }
        }
      }

      _sortByDateDescending(userRatingsList);

      final recentRatings = userRatingsList
          .take(_recentRatingsLimit)
          .map((entry) => RecentRating(
                shipName: entry.shipName,
                date: _resolveRatingDate(entry.data),
                averageScore: _calculateAverage(entry.data),
              ))
          .toList();

      return DashboardData(
        totalShips: shipsSnapshot.docs.length,
        totalRatings: totalRatings,
        userRatings: userRatings,
        recentRatings: recentRatings,
        lastRatedShipName: lastRatedShipName,
        lastRatedByPilot: lastRatedByPilot,
        lastRatedDate: lastRatedDate,
      );
    } catch (e) {
      debugPrint('[Dashboard] Error loading data: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Gets user callSign. Returns null on failure so dashboard can still load.
  Future<String?> _getUserCallSign(String userId) async {
    try {
      final userSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get()
          .timeout(_queryTimeout);

      if (!userSnapshot.exists) return null;
      return userSnapshot.data()?['nomeGuerra'];
    } catch (e) {
      debugPrint('[Dashboard] Error fetching callSign: $e');
      return null;
    }
  }

  /// Checks if a rating belongs to the current user by uid or callSign fallback.
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

  /// Resolves a rating's date from createdAt or data timestamp fields.
  DateTime _resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'];
    if (ts is Timestamp) {
      return ts.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Calculates the average score from rating items.
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

  /// Sorts rating entries by date descending.
  void _sortByDateDescending(List<_RatingEntry> entries) {
    entries.sort((a, b) {
      final aDate = _resolveRatingDate(a.data);
      final bDate = _resolveRatingDate(b.data);
      return bDate.compareTo(aDate);
    });
  }
}

// =============================================================================
// PRIVATE DATA CLASSES
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
  final String? lastRatedShipName;
  final String? lastRatedByPilot;
  final DateTime? lastRatedDate;

  DashboardData({
    required this.totalShips,
    required this.totalRatings,
    required this.userRatings,
    required this.recentRatings,
    this.lastRatedShipName,
    this.lastRatedByPilot,
    this.lastRatedDate,
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
