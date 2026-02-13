import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller for loading dashboard statistics and recent activity.
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

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  String? get currentUserId => _auth.currentUser?.uid;

  /// Loads all dashboard data in a single pass over Firestore.
  Future<DashboardData> loadDashboardData() async {
    final userId = currentUserId;
    if (userId == null) {
      return DashboardData.empty();
    }

    final callSign = await _getUserCallSign(userId);

    final shipsSnapshot = await _firestore.collection(_shipsCollection).get();
    final totalShips = shipsSnapshot.docs.length;

    int totalRatings = 0;
    int userRatings = 0;
    final userRatingsList = <_RatingEntry>[];

    for (final ship in shipsSnapshot.docs) {
      final shipData = ship.data();
      final shipName = shipData['nome'] ?? 'Navio';

      final ratingsSnapshot =
          await ship.reference.collection(_ratingsSubcollection).get();

      totalRatings += ratingsSnapshot.docs.length;

      for (final rating in ratingsSnapshot.docs) {
        final data = rating.data();

        if (_ratingBelongsToUser(data, userId, callSign)) {
          userRatings++;
          userRatingsList.add(_RatingEntry(
            shipName: shipName,
            data: data,
          ));
        }
      }
    }

    // Sort by date descending and take top 3
    userRatingsList.sort((a, b) {
      final aDate = _resolveDate(a.data);
      final bDate = _resolveDate(b.data);
      return bDate.compareTo(aDate);
    });

    final recentRatings = userRatingsList.take(3).map((entry) {
      final date = _resolveDate(entry.data);
      final avgScore = _calculateAverage(entry.data);
      return RecentRating(
        shipName: entry.shipName,
        date: date,
        averageScore: avgScore,
      );
    }).toList();

    return DashboardData(
      totalShips: totalShips,
      totalRatings: totalRatings,
      userRatings: userRatings,
      recentRatings: recentRatings,
    );
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  Future<String?> _getUserCallSign(String userId) async {
    final userSnapshot =
        await _firestore.collection(_usersCollection).doc(userId).get();
    return userSnapshot.data()?['nomeGuerra'];
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

  DateTime _resolveDate(Map<String, dynamic> data) {
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
}

// =============================================================================
// PRIVATE DATA CLASS
// =============================================================================

class _RatingEntry {
  final String shipName;
  final Map<String, dynamic> data;

  _RatingEntry({required this.shipName, required this.data});
}

// =============================================================================
// DATA CLASSES
// =============================================================================

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
