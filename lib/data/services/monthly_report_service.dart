import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/nav_safety_controller.dart';
import '../../core/constants.dart';
import '../../core/subscription_constants.dart';

/// Loads the data behind the Plus monthly report.
///
/// The report summarises what the signed-in pilot contributed during a single
/// month: ship ratings, depth records and crossings, plus the pilot position
/// in each ranking.
///
/// Rankings are not recomputed here: [DashboardController] already owns that
/// logic (dev accounts excluded, depth adjustments applied) and caches it, so
/// this service simply reads the numbers it produces.
class MonthlyReportService {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DashboardController _dashboardController = DashboardController();
  final NavSafetyController _navSafetyController = NavSafetyController();

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const Duration _queryTimeout = Duration(seconds: 15);

  /// Brasilia is UTC-3 all year round; crossings are stored as absolute UTC
  /// and displayed as Brasilia wall-clock time, so the report groups them the
  /// same way the crossing module does.
  static const Duration _brasiliaOffset = Duration(hours: 3);

  /// Month the range falls back to when the account creation date is unknown.
  static final DateTime fallbackFirstMonth = DateTime(2025, 12);

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Builds the report for [month] (any day of the month is accepted).
  ///
  /// Returns [MonthlyReportData.empty] when there is no signed-in user. A
  /// section that fails to load comes back empty instead of failing the whole
  /// report.
  Future<MonthlyReportData> generateReport(DateTime month) async {
    final monthStart = DateTime(month.year, month.month);

    final user = _auth.currentUser;
    if (user == null) return MonthlyReportData.empty(monthStart);

    final monthEnd = DateTime(month.year, month.month + 1);
    final userId = user.uid;

    final profile = await _fetchPilotProfile(userId);

    final results = await Future.wait([
      _fetchMonthRatings(
        userId: userId,
        callSign: profile.callSign,
        monthStart: monthStart,
        monthEnd: monthEnd,
      ),
      _fetchMonthDepthRecords(
        userId: userId,
        monthStart: monthStart,
        monthEnd: monthEnd,
      ),
      _fetchMonthCrossings(userId: userId, monthStart: monthStart),
      _fetchRankings(),
    ]);

    final rankings = results[3] as _ReportRankings;
    final ratings = results[0] as List<MonthlyRating>;
    final depthRecords = results[1] as List<MonthlyDepthRecord>;
    final crossings = results[2] as List<MonthlyCrossing>;

    debugPrint(
      '[MonthlyReport] ${monthStart.year}-${monthStart.month}: '
      '${ratings.length} ratings, ${depthRecords.length} depths, '
      '${crossings.length} crossings',
    );

    return MonthlyReportData(
      month: monthStart,
      pilotName: profile.callSign ?? '',
      pilotEmail: profile.email,
      subscriptionPlan: profile.subscriptionPlan,
      ratings: ratings,
      depthRecords: depthRecords,
      crossings: crossings,
      ratingRanking: rankings.ratingRanking,
      depthRanking: rankings.depthRanking,
      crossingRanking: rankings.crossingRanking,
      totalPilots: rankings.totalPilots,
    );
  }

  /// Months the report can be generated for, most recent first.
  ///
  /// Every pilot starts on a different month: the range goes from the month the
  /// account was created up to the current month. Never returns an empty list,
  /// the current month is always offered.
  Future<List<DateTime>> getAvailableMonths() async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    final firstMonth = await _fetchAccountCreationMonth();
    // A creation date in the future would hide every month, so it is clamped.
    var cursor = firstMonth.isAfter(currentMonth) ? currentMonth : firstMonth;

    final months = <DateTime>[];
    while (!cursor.isAfter(currentMonth)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return months.reversed.toList();
  }

  // ===========================================================================
  // PRIVATE METHODS - PILOT PROFILE
  // ===========================================================================

  /// Month the pilot created the account, [fallbackFirstMonth] when unknown.
  ///
  /// `usuarios/{uid}.createdAt` is written on sign up; accounts created before
  /// that field existed fall back to the Firebase Auth metadata, which keeps
  /// the same date.
  Future<DateTime> _fetchAccountCreationMonth() async {
    final user = _auth.currentUser;
    if (user == null) return fallbackFirstMonth;

    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get()
          .timeout(_queryTimeout);

      final createdAt = snapshot.data()?['createdAt'];
      if (createdAt is Timestamp) return _monthOf(createdAt.toDate());
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching account creation date: $e');
    }

    final creationTime = user.metadata.creationTime;
    if (creationTime != null) return _monthOf(creationTime);

    return fallbackFirstMonth;
  }

  /// Reads call sign, email and subscription plan from `usuarios/{uid}`.
  ///
  /// The plan is the one SubscriptionService mirrors to Firestore, so no
  /// RevenueCat round-trip is needed here.
  Future<_PilotProfile> _fetchPilotProfile(String userId) async {
    final authEmail = _auth.currentUser?.email ?? '';

    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get()
          .timeout(_queryTimeout);

      final data = snapshot.data();
      if (data == null) {
        return _PilotProfile(
          callSign: null,
          email: authEmail,
          subscriptionPlan: SubscriptionConstants.planNone,
        );
      }

      final callSign = (data['nomeGuerra'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();
      final subscription = data['subscription'] as Map<String, dynamic>?;
      final plan = (subscription?['plan'] ?? '').toString().trim();

      return _PilotProfile(
        callSign: callSign.isEmpty ? null : callSign,
        email: email.isEmpty ? authEmail : email,
        subscriptionPlan: plan.isEmpty ? SubscriptionConstants.planNone : plan,
      );
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching pilot profile: $e');
      return _PilotProfile(
        callSign: null,
        email: authEmail,
        subscriptionPlan: SubscriptionConstants.planNone,
      );
    }
  }

  // ===========================================================================
  // PRIVATE METHODS - RATINGS
  // ===========================================================================

  /// Ratings the pilot made during the month, oldest first.
  ///
  /// Ratings live in one subcollection per ship. A collection-group query
  /// limits the read to this pilot before the month is filtered locally,
  /// avoiding one request for every ship in the database.
  Future<List<MonthlyRating>> _fetchMonthRatings({
    required String userId,
    required String? callSign,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    try {
      final queryFutures = <Future<QuerySnapshot<Map<String, dynamic>>>>[
        _firestore
            .collectionGroup(AppConstants.ratingsSubcollection)
            .where('usuarioId', isEqualTo: userId)
            .get()
            .timeout(_queryTimeout),
        if (callSign != null)
          _firestore
              .collectionGroup(AppConstants.ratingsSubcollection)
              .where('nomeGuerra', isEqualTo: callSign)
              .get()
              .timeout(_queryTimeout),
      ];
      final snapshots = await Future.wait(queryFutures);

      // A current rating matches both queries. Its full path is stable across
      // both snapshots and lets us remove duplicates without relying on ids,
      // which only need to be unique inside each ship.
      final documentsByPath =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final snapshot in snapshots) {
        for (final document in snapshot.docs) {
          documentsByPath[document.reference.path] = document;
        }
      }

      final records = <_MonthlyRatingRecord>[];
      for (final document in documentsByPath.values) {
        final data = document.data();
        if (!_ratingBelongsToUser(data, userId, callSign)) continue;

        final date = _resolveRatingDate(data);
        if (date == null || !_isInRange(date, monthStart, monthEnd)) continue;

        final shipReference = document.reference.parent.parent;
        if (shipReference == null) continue;
        records.add(
          _MonthlyRatingRecord(
            shipReference: shipReference,
            date: date,
            averageScore: _calculateAverage(data),
          ),
        );
      }

      final shipNames = await _resolveShipNames(
        records.map((record) => record.shipReference).toSet(),
      );
      final ratings = records
          .map(
            (record) => MonthlyRating(
              shipName: shipNames[record.shipReference.path] ?? '',
              date: record.date,
              averageScore: record.averageScore,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return ratings;
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching ratings: $e');
      return const [];
    }
  }

  Future<Map<String, String>> _resolveShipNames(
    Set<DocumentReference<Map<String, dynamic>>> shipReferences,
  ) async {
    final entries = await Future.wait(
      shipReferences.map((reference) async {
        try {
          final snapshot = await reference.get().timeout(_queryTimeout);
          return MapEntry(
            reference.path,
            (snapshot.data()?['nome'] ?? '').toString(),
          );
        } catch (e) {
          debugPrint('[MonthlyReport] Error reading ship ${reference.id}: $e');
          return MapEntry(reference.path, '');
        }
      }),
    );
    return Map.fromEntries(entries);
  }

  /// Same ownership rule the dashboard uses: uid match, call sign as fallback
  /// for legacy ratings saved without a uid.
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

  DateTime? _resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  /// Average of the `nota` values stored in the rating `itens` map.
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

  // ===========================================================================
  // PRIVATE METHODS - DEPTH RECORDS
  // ===========================================================================

  /// Depth records the pilot saved during the month, oldest first.
  ///
  /// Uses the `registros` collection group index (pilotId + data), the same
  /// one [NavSafetyController.fetchMyRecords] relies on.
  Future<List<MonthlyDepthRecord>> _fetchMonthDepthRecords({
    required String userId,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    try {
      final recordsSnapshot = await _firestore
          .collectionGroup(AppConstants.recordsSubcollection)
          .where('pilotId', isEqualTo: userId)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('data', isLessThan: Timestamp.fromDate(monthEnd))
          .orderBy('data', descending: true)
          .get()
          .timeout(_queryTimeout);

      if (recordsSnapshot.docs.isEmpty) return const [];

      final locationIds = recordsSnapshot.docs
          .map((doc) => doc.reference.parent.parent?.id)
          .whereType<String>()
          .toSet();
      final locationNames = await _resolveLocationNames(locationIds);

      final records = <MonthlyDepthRecord>[];
      for (final doc in recordsSnapshot.docs) {
        // Path: locais/{locationId}/registros/{recordId}
        final locationId = doc.reference.parent.parent?.id;
        final data = doc.data();
        final date = data['data'];
        if (date is! Timestamp) continue;

        records.add(
          MonthlyDepthRecord(
            locationName: locationNames[locationId] ?? '',
            date: date.toDate(),
            totalDepth: (data['profundidadeTotal'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      records.sort((a, b) => a.date.compareTo(b.date));
      return records;
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching depth records: $e');
      return const [];
    }
  }

  /// Maps location ids to names, reusing the navigation-safety cache and
  /// reading only the locations it does not know about.
  Future<Map<String, String>> _resolveLocationNames(
    Set<String> locationIds,
  ) async {
    final names = <String, String>{};

    try {
      final cachedLocations = await _navSafetyController.getCachedLocations();
      for (final location in cachedLocations) {
        if (locationIds.contains(location.id)) {
          names[location.id] = location.name;
        }
      }
    } catch (e) {
      debugPrint('[MonthlyReport] Error reading cached locations: $e');
    }

    final missingIds = locationIds.where((id) => !names.containsKey(id));
    final missing = await Future.wait(
      missingIds.map((id) async {
        try {
          final snapshot = await _firestore
              .collection(AppConstants.locationsCollection)
              .doc(id)
              .get()
              .timeout(_queryTimeout);
          return MapEntry(id, (snapshot.data()?['nome'] ?? '').toString());
        } catch (e) {
          debugPrint('[MonthlyReport] Error reading location $id: $e');
          return MapEntry(id, '');
        }
      }),
    );

    names.addEntries(missing);
    return names;
  }

  // ===========================================================================
  // PRIVATE METHODS - CROSSINGS
  // ===========================================================================

  /// Crossings the pilot registered during the month, oldest first.
  ///
  /// There is no composite index for (pilotoId, dataHora), so the month filter
  /// runs client side over the crossings of the pilot - the same query
  /// CrossingController.fetchMyCrossings makes.
  Future<List<MonthlyCrossing>> _fetchMonthCrossings({
    required String userId,
    required DateTime monthStart,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.cruzamentosCollection)
          .where('pilotoId', isEqualTo: userId)
          .get()
          .timeout(_queryTimeout);

      final crossings = <MonthlyCrossing>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = _resolveBrasiliaDateTime(data['dataHora']);
        if (date == null) continue;
        if (date.year != monthStart.year || date.month != monthStart.month) {
          continue;
        }

        crossings.add(
          MonthlyCrossing(
            shipName: (data['nomeNavio'] ?? '').toString(),
            locationName: (data['local'] ?? '').toString(),
            date: date,
            direction: (data['direcao'] ?? '').toString(),
          ),
        );
      }

      crossings.sort((a, b) => a.date.compareTo(b.date));
      return crossings;
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching crossings: $e');
      return const [];
    }
  }

  /// Converts a stored crossing timestamp to Brasilia wall-clock time.
  DateTime? _resolveBrasiliaDateTime(dynamic value) {
    if (value is! Timestamp) return null;
    final brasilia = value.toDate().toUtc().subtract(_brasiliaOffset);
    return DateTime(
      brasilia.year,
      brasilia.month,
      brasilia.day,
      brasilia.hour,
      brasilia.minute,
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - RANKINGS
  // ===========================================================================

  /// Reads the three rankings from [DashboardController].
  ///
  /// The controller already drops dev accounts from every ranking and applies
  /// the depth-count adjustments, and caches the result for 60s, so this is
  /// usually free right after the dashboard has loaded. A position of 0 means
  /// the pilot is not ranked (no contributions, or a dev account).
  Future<_ReportRankings> _fetchRankings() async {
    try {
      final data = await _dashboardController.loadDashboardData().timeout(
            _queryTimeout,
          );
      return _ReportRankings(
        ratingRanking: data.userRankingPosition,
        depthRanking: data.userDepthRanking,
        crossingRanking: data.userCrossingRanking,
        totalPilots: data.totalUsers,
      );
    } catch (e) {
      debugPrint('[MonthlyReport] Error fetching rankings: $e');
      return const _ReportRankings.empty();
    }
  }

  // ===========================================================================
  // PRIVATE METHODS - HELPERS
  // ===========================================================================

  bool _isInRange(DateTime date, DateTime start, DateTime end) =>
      !date.isBefore(start) && date.isBefore(end);

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);
}

// =============================================================================
// PRIVATE DATA CLASSES
// =============================================================================

class _PilotProfile {
  final String? callSign;
  final String email;
  final String subscriptionPlan;

  const _PilotProfile({
    required this.callSign,
    required this.email,
    required this.subscriptionPlan,
  });
}

class _MonthlyRatingRecord {
  final DocumentReference<Map<String, dynamic>> shipReference;
  final DateTime date;
  final double averageScore;

  const _MonthlyRatingRecord({
    required this.shipReference,
    required this.date,
    required this.averageScore,
  });
}

class _ReportRankings {
  final int ratingRanking;
  final int depthRanking;
  final int crossingRanking;
  final int totalPilots;

  const _ReportRankings({
    required this.ratingRanking,
    required this.depthRanking,
    required this.crossingRanking,
    required this.totalPilots,
  });

  const _ReportRankings.empty()
      : ratingRanking = 0,
        depthRanking = 0,
        crossingRanking = 0,
        totalPilots = 0;
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Everything the monthly report shows for a single month.
class MonthlyReportData {
  /// First day of the month covered by the report.
  final DateTime month;

  /// Call sign of the pilot (`nomeGuerra`).
  final String pilotName;
  final String pilotEmail;

  /// Plan mirrored in `usuarios/{uid}.subscription.plan`: `plus`, `premium`
  /// or `none`.
  final String subscriptionPlan;

  final List<MonthlyRating> ratings;
  final List<MonthlyDepthRecord> depthRecords;
  final List<MonthlyCrossing> crossings;

  /// Ranking positions across all months. 0 means the pilot is not ranked.
  final int ratingRanking;
  final int depthRanking;
  final int crossingRanking;

  /// Number of pilots each ranking is measured against.
  final int totalPilots;

  const MonthlyReportData({
    required this.month,
    required this.pilotName,
    required this.pilotEmail,
    required this.subscriptionPlan,
    required this.ratings,
    required this.depthRecords,
    required this.crossings,
    required this.ratingRanking,
    required this.depthRanking,
    required this.crossingRanking,
    required this.totalPilots,
  });

  factory MonthlyReportData.empty(DateTime month) => MonthlyReportData(
        month: DateTime(month.year, month.month),
        pilotName: '',
        pilotEmail: '',
        subscriptionPlan: SubscriptionConstants.planNone,
        ratings: const [],
        depthRecords: const [],
        crossings: const [],
        ratingRanking: 0,
        depthRanking: 0,
        crossingRanking: 0,
        totalPilots: 0,
      );

  /// True when the pilot contributed nothing in the month.
  bool get isEmpty =>
      ratings.isEmpty && depthRecords.isEmpty && crossings.isEmpty;
}

/// A ship rating made during the report month.
class MonthlyRating {
  final String shipName;
  final DateTime date;
  final double averageScore;

  const MonthlyRating({
    required this.shipName,
    required this.date,
    required this.averageScore,
  });
}

/// A depth record saved during the report month.
class MonthlyDepthRecord {
  final String locationName;
  final DateTime date;

  /// `profundidadeTotal`, in meters.
  final double totalDepth;

  const MonthlyDepthRecord({
    required this.locationName,
    required this.date,
    required this.totalDepth,
  });
}

/// A crossing registered during the report month.
class MonthlyCrossing {
  final String shipName;
  final String locationName;

  /// Brasilia wall-clock time of the crossing.
  final DateTime date;

  /// Stored `direcao` value: `subindo` or `baixando`.
  final String direction;

  const MonthlyCrossing({
    required this.shipName,
    required this.locationName,
    required this.date,
    required this.direction,
  });
}
