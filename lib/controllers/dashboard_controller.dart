import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/module_access.dart';

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

  static const int _recentRatingsLimit = 3;
  static const Duration _queryTimeout = Duration(seconds: 15);

  // ===========================================================================
  // STATIC CACHE
  // ===========================================================================

  static DashboardData? _cachedData;
  static DashboardData? _cachedCrossingData;
  static DashboardData? _cachedDepthData;
  static DateTime? _cacheTimestamp;
  static DateTime? _crossingCacheTimestamp;
  static DateTime? _depthCacheTimestamp;
  static const Duration _cacheDuration = Duration(seconds: 60);
  static const _emptyDepthStats = _DepthDashboardStats(
    totalDepthRecords: 0,
    userDepthRecordCount: 0,
    topDepthContributorCount: 0,
    userDepthRanking: 0,
    totalDepthPilots: 0,
  );

  static DashboardData? get cachedData => _cachedData;
  static DashboardData? get cachedCrossingData => _cachedCrossingData;
  static DashboardData? get cachedDepthData => _cachedDepthData;

  static bool get isCacheFresh =>
      _cachedData != null &&
      _cacheTimestamp != null &&
      DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;

  static bool get isCrossingCacheFresh =>
      _cachedCrossingData != null &&
      _crossingCacheTimestamp != null &&
      DateTime.now().difference(_crossingCacheTimestamp!) < _cacheDuration;

  static bool get isDepthCacheFresh =>
      _cachedDepthData != null &&
      _depthCacheTimestamp != null &&
      DateTime.now().difference(_depthCacheTimestamp!) < _cacheDuration;

  static void invalidateCache() {
    _cachedData = null;
    _cachedCrossingData = null;
    _cachedDepthData = null;
    _cacheTimestamp = null;
    _crossingCacheTimestamp = null;
    _depthCacheTimestamp = null;
  }

  // ===========================================================================
  // SHARED PREFERENCES PERSISTENCE
  // ===========================================================================

  static Future<void> _persistStats({
    required int ships,
    required int ratings,
    required int crossings,
    required int pilots,
    required int topRaterCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('cached_ships', ships);
    prefs.setInt('cached_ratings', ratings);
    prefs.setInt('cached_crossings', crossings);
    prefs.setInt('cached_pilots', pilots);
    prefs.setInt('cached_topRaterCount', topRaterCount);
  }

  static Future<Map<String, int>> loadCachedStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'ships': prefs.getInt('cached_ships') ?? 0,
      'ratings': prefs.getInt('cached_ratings') ?? 0,
      'crossings': prefs.getInt('cached_crossings') ?? 0,
      'pilots': prefs.getInt('cached_pilots') ?? 0,
      'topRaterCount': prefs.getInt('cached_topRaterCount') ?? 0,
    };
  }

  static Future<DashboardData?> loadCachedCrossingDashboardData() async {
    if (_cachedCrossingData != null) return _cachedCrossingData;

    final prefs = await SharedPreferences.getInstance();
    final timestampMs = prefs.getInt('cached_crossing_stats_timestamp');
    if (timestampMs == null) return null;

    final data = DashboardData(
      totalShips: 0,
      totalRatings: 0,
      totalCrossings: prefs.getInt('cached_crossing_total') ?? 0,
      totalUsers: prefs.getInt('cached_crossing_total_users') ?? 0,
      userRatings: 0,
      topRaterCount: 0,
      userRankingPosition: 0,
      totalPilotsWhoRated: 0,
      userCrossingCount: prefs.getInt('cached_crossing_user_count') ?? 0,
      topCrosserCount: prefs.getInt('cached_crossing_top_count') ?? 0,
      userCrossingRanking: prefs.getInt('cached_crossing_user_ranking') ?? 0,
      totalCrossingPilots: prefs.getInt('cached_crossing_total_pilots') ?? 0,
      totalDepthRecords: 0,
      userDepthRecordCount: 0,
      topDepthContributorCount: 0,
      userDepthRanking: 0,
      totalDepthPilots: 0,
      recentRatings: const [],
    );

    _cachedCrossingData = data;
    _crossingCacheTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return data;
  }

  static Future<DashboardData?> loadCachedDepthDashboardData() async {
    if (_cachedDepthData != null) return _cachedDepthData;

    final prefs = await SharedPreferences.getInstance();
    final timestampMs = prefs.getInt('cached_depth_stats_timestamp');
    if (timestampMs == null) return null;

    final data = DashboardData(
      totalShips: 0,
      totalRatings: 0,
      totalCrossings: 0,
      totalUsers: prefs.getInt('cached_depth_total_users') ?? 0,
      userRatings: 0,
      topRaterCount: 0,
      userRankingPosition: 0,
      totalPilotsWhoRated: 0,
      userCrossingCount: 0,
      topCrosserCount: 0,
      userCrossingRanking: 0,
      totalCrossingPilots: 0,
      totalDepthRecords: prefs.getInt('cached_depth_total') ?? 0,
      userDepthRecordCount: prefs.getInt('cached_depth_user_count') ?? 0,
      topDepthContributorCount: prefs.getInt('cached_depth_top_count') ?? 0,
      userDepthRanking: prefs.getInt('cached_depth_user_ranking') ?? 0,
      totalDepthPilots: prefs.getInt('cached_depth_total_pilots') ?? 0,
      recentRatings: const [],
    );

    _cachedDepthData = data;
    _depthCacheTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return data;
  }

  static Future<void> _persistCrossingStats(DashboardData data) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('cached_crossing_total', data.totalCrossings),
      prefs.setInt('cached_crossing_total_users', data.totalUsers),
      prefs.setInt('cached_crossing_user_count', data.userCrossingCount),
      prefs.setInt('cached_crossing_top_count', data.topCrosserCount),
      prefs.setInt('cached_crossing_user_ranking', data.userCrossingRanking),
      prefs.setInt('cached_crossing_total_pilots', data.totalCrossingPilots),
      prefs.setInt(
        'cached_crossing_stats_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      ),
    ]);
  }

  static Future<void> _persistDepthStats(DashboardData data) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('cached_depth_total', data.totalDepthRecords),
      prefs.setInt('cached_depth_total_users', data.totalUsers),
      prefs.setInt('cached_depth_user_count', data.userDepthRecordCount),
      prefs.setInt('cached_depth_top_count', data.topDepthContributorCount),
      prefs.setInt('cached_depth_user_ranking', data.userDepthRanking),
      prefs.setInt('cached_depth_total_pilots', data.totalDepthPilots),
      prefs.setInt(
        'cached_depth_stats_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      ),
    ]);
  }

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Gets the current user's ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Loads only crossing statistics for the crossing module.
  ///
  /// This avoids the full dashboard pass over ships and ratings, keeping the
  /// crossing page responsive on web and mobile.
  Future<DashboardData> loadCrossingDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) return DashboardData.empty();

    if (isCrossingCacheFresh) return _cachedCrossingData!;

    final userId = user.uid;

    await user.getIdToken().timeout(_queryTimeout);

    final cachedGeneralStats = await loadCachedStats();
    final cachedUserCount = cachedGeneralStats['pilots'] ?? 0;
    final callSign = await _getUserCallSign(userId);
    final crossingStats = await _getCrossingStats(userId, callSign);

    final result = DashboardData(
      totalShips: 0,
      totalRatings: 0,
      totalCrossings: crossingStats.totalCrossings,
      totalUsers: cachedUserCount > 0
          ? cachedUserCount
          : crossingStats.totalCrossingPilots,
      userRatings: 0,
      topRaterCount: 0,
      userRankingPosition: 0,
      totalPilotsWhoRated: 0,
      userCrossingCount: crossingStats.userCrossingCount,
      topCrosserCount: crossingStats.topCrosserCount,
      userCrossingRanking: crossingStats.userCrossingRanking,
      totalCrossingPilots: crossingStats.totalCrossingPilots,
      totalDepthRecords: 0,
      userDepthRecordCount: 0,
      topDepthContributorCount: 0,
      userDepthRanking: 0,
      totalDepthPilots: 0,
      recentRatings: const [],
    );

    _cachedCrossingData = result;
    _crossingCacheTimestamp = DateTime.now();
    unawaited(_persistCrossingStats(result));

    return result;
  }

  /// Loads only depth statistics for the navigation-safety module.
  Future<DashboardData> loadDepthDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) return DashboardData.empty();
    if (!ModuleAccess.canAccessRestrictedModules) return DashboardData.empty();

    if (isDepthCacheFresh) return _cachedDepthData!;

    final userId = user.uid;

    await user.getIdToken().timeout(_queryTimeout);

    final cachedGeneralStats = await loadCachedStats();
    final cachedUserCount = cachedGeneralStats['pilots'] ?? 0;
    final depthStats = await _getDepthRecordStats(userId);

    final result = DashboardData(
      totalShips: 0,
      totalRatings: 0,
      totalCrossings: 0,
      totalUsers:
          cachedUserCount > 0 ? cachedUserCount : depthStats.totalDepthPilots,
      userRatings: 0,
      topRaterCount: 0,
      userRankingPosition: 0,
      totalPilotsWhoRated: 0,
      userCrossingCount: 0,
      topCrosserCount: 0,
      userCrossingRanking: 0,
      totalCrossingPilots: 0,
      totalDepthRecords: depthStats.totalDepthRecords,
      userDepthRecordCount: depthStats.userDepthRecordCount,
      topDepthContributorCount: depthStats.topDepthContributorCount,
      userDepthRanking: depthStats.userDepthRanking,
      totalDepthPilots: depthStats.totalDepthPilots,
      recentRatings: const [],
    );

    _cachedDepthData = result;
    _depthCacheTimestamp = DateTime.now();
    unawaited(_persistDepthStats(result));

    return result;
  }

  /// Loads all dashboard data in a single pass over Firestore.
  ///
  /// Returns a [DashboardData] with totals and recent activity.
  /// Returns [DashboardData.empty] if user is not authenticated.
  Future<DashboardData> loadDashboardData() async {
    // Use currentUser directly — AuthGate's StreamBuilder guarantees
    // the user is authenticated before this widget is ever mounted.
    final user = _auth.currentUser;
    if (user == null) return DashboardData.empty();

    if (isCacheFresh) return _cachedData!;

    final userId = user.uid;

    try {
      // Force token validation before Firestore queries.
      // On Flutter Web, the Firestore JS SDK needs a valid auth token.
      await user.getIdToken().timeout(_queryTimeout);

      // Start independent dashboard queries in parallel.
      final callSignFuture = _getUserCallSign(userId);
      final shipsFuture = _firestore
          .collection(AppConstants.shipsCollection)
          .get()
          .timeout(_queryTimeout);
      final userCountFuture = _getUserCount();
      final depthStatsFuture = ModuleAccess.canAccessRestrictedModules
          ? _getDepthRecordStats(userId)
          : Future<_DepthDashboardStats>.value(_emptyDepthStats);

      final callSign = await callSignFuture;
      final crossingStatsFuture = _getCrossingStats(userId, callSign);
      final results = await Future.wait([
        shipsFuture,
        userCountFuture,
        crossingStatsFuture,
        depthStatsFuture,
      ]);

      final shipsSnapshot = results[0] as QuerySnapshot;
      final cloudUserCount = results[1] as int?;
      final crossingStats = results[2] as _CrossingDashboardStats;
      final depthStats = results[3] as _DepthDashboardStats;

      int totalRatings = 0;
      int userRatings = 0;
      final userRatingsList = <_RatingEntry>[];
      final ratingsPerPilot = <String, int>{};
      String? lastRatedShipName;
      String? lastRatedByPilot;
      DateTime? lastRatedDate;
      String? lastRatedShipId;
      String? lastRatedRatingId;

      // Fetch all ship ratings in parallel
      final ratingsFutures = shipsSnapshot.docs.map((ship) {
        return ship.reference
            .collection(AppConstants.ratingsSubcollection)
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
            lastRatedShipId = result.ship.id;
            lastRatedRatingId = rating.id;
          }

          final ratingUid = data['usuarioId'] as String?;
          final realPilotId = data['realPilotId'] as String?;
          final realPilotIds = data['realPilotIds'] as List<dynamic>?;

          if (realPilotId != null) {
            ratingsPerPilot[realPilotId] =
                (ratingsPerPilot[realPilotId] ?? 0) + 1;
          } else if (realPilotIds != null && realPilotIds.isNotEmpty) {
            for (final id in realPilotIds) {
              final key = id as String;
              ratingsPerPilot[key] = (ratingsPerPilot[key] ?? 0) + 1;
            }
          } else if (ratingUid != AppConstants.cspamUid) {
            final pilotKey = ratingUid ??
                (data['nomeGuerra'] as String?) ??
                '';
            if (pilotKey.isNotEmpty) {
              ratingsPerPilot[pilotKey] =
                  (ratingsPerPilot[pilotKey] ?? 0) + 1;
            }
          }

          if (_ratingBelongsToUser(data, userId, callSign)) {
            userRatings++;
            userRatingsList.add(_RatingEntry(
              shipName: shipName,
              shipId: result.ship.id,
              ratingId: rating.id,
              data: data,
            ));
          }
        }
      }

      // Calculate top rater and user ranking from accumulated counts
      ratingsPerPilot.remove(AppConstants.cspamUid);

      int topRaterCount = 0;
      int userRankingPosition = 0;
      final totalPilotsWhoRated = ratingsPerPilot.length;

      if (ratingsPerPilot.isNotEmpty) {
        final counts = ratingsPerPilot.values.toList()
          ..sort((a, b) => b.compareTo(a));
        topRaterCount = counts.first;

        final userKey = ratingsPerPilot.containsKey(userId)
            ? userId
            : (callSign != null && ratingsPerPilot.containsKey(callSign)
                ? callSign
                : null);

        if (userKey != null) {
          final userCount = ratingsPerPilot[userKey]!;
          userRankingPosition =
              counts.where((c) => c > userCount).length + 1;
        }
      }

      final totalUsers = cloudUserCount ?? totalPilotsWhoRated;

      _sortByDateDescending(userRatingsList);

      final recentRatings = userRatingsList
          .take(_recentRatingsLimit)
          .map((entry) => RecentRating(
                shipName: entry.shipName,
                shipId: entry.shipId,
                ratingId: entry.ratingId,
                date: _resolveRatingDate(entry.data),
                averageScore: _calculateAverage(entry.data),
              ))
          .toList();

      final result = DashboardData(
        totalShips: shipsSnapshot.docs.length,
        totalRatings: totalRatings,
        totalCrossings: crossingStats.totalCrossings,
        userCrossingCount: crossingStats.userCrossingCount,
        topCrosserCount: crossingStats.topCrosserCount,
        userCrossingRanking: crossingStats.userCrossingRanking,
        totalCrossingPilots: crossingStats.totalCrossingPilots,
        totalDepthRecords: depthStats.totalDepthRecords,
        userDepthRecordCount: depthStats.userDepthRecordCount,
        topDepthContributorCount: depthStats.topDepthContributorCount,
        userDepthRanking: depthStats.userDepthRanking,
        totalDepthPilots: depthStats.totalDepthPilots,
        totalUsers: totalUsers,
        userRatings: userRatings,
        topRaterCount: topRaterCount,
        userRankingPosition: userRankingPosition,
        totalPilotsWhoRated: totalUsers,
        recentRatings: recentRatings,
        lastRatedShipName: lastRatedShipName,
        lastRatedByPilot: lastRatedByPilot,
        lastRatedDate: lastRatedDate,
        lastRatedShipId: lastRatedShipId,
        lastRatedRatingId: lastRatedRatingId,
      );
      _cachedData = result;
      _cachedCrossingData = result;
      _cachedDepthData = result;
      _cacheTimestamp = DateTime.now();
      _crossingCacheTimestamp = _cacheTimestamp;
      _depthCacheTimestamp = _cacheTimestamp;

      unawaited(
        _persistStats(
          ships: result.totalShips,
          ratings: result.totalRatings,
          crossings: result.totalCrossings,
          pilots: result.totalUsers,
          topRaterCount: result.topRaterCount,
        ),
      );
      unawaited(_persistCrossingStats(result));
      unawaited(_persistDepthStats(result));

      return result;
    } catch (e) {
      debugPrint('[Dashboard] Error loading data: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Gets total registered users via Cloud Function. Returns null on failure.
  Future<int?> _getUserCount() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserCount')
          .call()
          .timeout(_queryTimeout);
      return result.data['count'] as int;
    } catch (e) {
      debugPrint('[Dashboard] Error fetching user count: $e');
      return null;
    }
  }

  Future<_CrossingDashboardStats> _getCrossingStats(
    String userId,
    String? callSign,
  ) async {
    int totalCrossings = 0;
    final crossingsPerPilot = <String, int>{};
    var hasPreAggregatedPilotStats = false;

    try {
      final statsDoc = await _firestore
          .collection('stats')
          .doc('crossings')
          .get()
          .timeout(_queryTimeout);
      if (statsDoc.exists) {
        totalCrossings = (statsDoc.data()?['totalCount'] as int?) ?? 0;
      }
    } catch (e) {
      debugPrint('[Dashboard] Error fetching crossing stats doc: $e');
    }

    try {
      final pilotStatsSnapshot = await _firestore
          .collection(AppConstants.pilotStatsCollection)
          .where('crossingCount', isGreaterThan: 0)
          .get()
          .timeout(_queryTimeout);

      for (final doc in pilotStatsSnapshot.docs) {
        if (doc.id == AppConstants.cspamUid) continue;
        final count = (doc.data()['crossingCount'] as int?) ?? 0;
        crossingsPerPilot[doc.id] = count;
      }
      hasPreAggregatedPilotStats = crossingsPerPilot.isNotEmpty;
    } catch (e) {
      debugPrint('[Dashboard] Error fetching pilot crossing counts: $e');
    }

    // Self-heal: if the current user's counter is 0, validate against real data
    final preAggregatedUserCount = crossingsPerPilot[userId] ?? 0;
    if (preAggregatedUserCount == 0) {
      try {
        final realCountSnapshot = await _firestore
            .collection(AppConstants.cruzamentosCollection)
            .where('pilotoId', isEqualTo: userId)
            .count()
            .get()
            .timeout(_queryTimeout);
        final realCount = realCountSnapshot.count ?? 0;

        if (realCount > 0) {
          crossingsPerPilot[userId] = realCount;
        }
      } catch (e) {
        debugPrint('[Dashboard] Error validating user crossing count: $e');
      }
    }

    final counterTotal = crossingsPerPilot.values.fold(0, (a, b) => a + b);
    if (counterTotal > totalCrossings) {
      totalCrossings = counterTotal;
    }

    if (!hasPreAggregatedPilotStats) {
      final recordStats = await _getCrossingStatsFromRecords(userId, callSign);
      if (recordStats != null) return recordStats;
    }

    final sortedCounts = crossingsPerPilot.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final userKey = crossingsPerPilot.containsKey(userId)
        ? userId
        : (callSign != null && crossingsPerPilot.containsKey(callSign)
            ? callSign
            : null);
    final userCount = userKey == null ? 0 : crossingsPerPilot[userKey] ?? 0;
    final userRanking = userCount > 0
        ? sortedCounts.where((c) => c > userCount).length + 1
        : 0;

    return _CrossingDashboardStats(
      totalCrossings: totalCrossings,
      userCrossingCount: userCount,
      topCrosserCount: sortedCounts.isEmpty ? 0 : sortedCounts.first,
      userCrossingRanking: userRanking,
      totalCrossingPilots: crossingsPerPilot.length,
    );
  }

  Future<_CrossingDashboardStats?> _getCrossingStatsFromRecords(
    String userId,
    String? callSign,
  ) async {
    try {
      final crossingsSnapshot = await _firestore
          .collection(AppConstants.cruzamentosCollection)
          .get()
          .timeout(_queryTimeout);
      if (crossingsSnapshot.docs.isEmpty) return null;

      final crossingsPerPilot = <String, int>{};
      for (final doc in crossingsSnapshot.docs) {
        final data = doc.data();
        final pilotKey = _resolveCrossingPilotKey(data);
        if (pilotKey == null || pilotKey == AppConstants.cspamUid) continue;
        crossingsPerPilot[pilotKey] =
            (crossingsPerPilot[pilotKey] ?? 0) + 1;
      }

      final sortedCounts = crossingsPerPilot.values.toList()
        ..sort((a, b) => b.compareTo(a));
      final userKey = crossingsPerPilot.containsKey(userId)
          ? userId
          : (callSign != null && crossingsPerPilot.containsKey(callSign)
              ? callSign
              : null);
      final userCount = userKey == null ? 0 : crossingsPerPilot[userKey] ?? 0;
      final userRanking = userCount > 0
          ? sortedCounts.where((c) => c > userCount).length + 1
          : 0;

      return _CrossingDashboardStats(
        totalCrossings: crossingsSnapshot.docs.length,
        userCrossingCount: userCount,
        topCrosserCount: sortedCounts.isEmpty ? 0 : sortedCounts.first,
        userCrossingRanking: userRanking,
        totalCrossingPilots: crossingsPerPilot.length,
      );
    } catch (e) {
      debugPrint('[Dashboard] Error grouping crossing records: $e');
      return null;
    }
  }

  String? _resolveCrossingPilotKey(Map<String, dynamic> data) {
    for (final field in ['pilotoId', 'pilotId', 'usuarioId', 'userId']) {
      final rawValue = data[field];
      final value = rawValue?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final rawCallSign = data['nomeGuerra'];
    final callSign = rawCallSign?.toString().trim();
    if (callSign != null && callSign.isNotEmpty) return callSign;
    return null;
  }

  Future<_DepthDashboardStats> _getDepthRecordStats(String userId) async {
    int totalDepthRecords = 0;
    int? expectedPilotRecordCount;
    final depthsPerPilot = <String, int>{};

    try {
      final statsDoc = await _firestore
          .collection('stats')
          .doc('depthRecords')
          .get()
          .timeout(_queryTimeout);
      if (statsDoc.exists) {
        final statsData = statsDoc.data();
        totalDepthRecords = (statsData?['totalCount'] as int?) ?? 0;
        expectedPilotRecordCount = statsData?['pilotRecordCount'] as int?;
      }
    } catch (e) {
      debugPrint('[Dashboard] Error fetching depth record stats doc: $e');
    }

    try {
      final pilotStatsSnapshot = await _firestore
          .collection(AppConstants.pilotStatsCollection)
          .where('depthRecordCount', isGreaterThan: 0)
          .get()
          .timeout(_queryTimeout);

      for (final doc in pilotStatsSnapshot.docs) {
        if (doc.id == AppConstants.cspamUid) continue;
        final count = (doc.data()['depthRecordCount'] as int?) ?? 0;
        depthsPerPilot[doc.id] = count;
      }
    } catch (e) {
      debugPrint('[Dashboard] Error fetching pilot depth record counts: $e');
    }

    final counterTotal = depthsPerPilot.values.fold(0, (a, b) => a + b);
    if (counterTotal > totalDepthRecords) {
      totalDepthRecords = counterTotal;
    }

    final countersNeedBackfill = expectedPilotRecordCount != null &&
        counterTotal < expectedPilotRecordCount;
    if (countersNeedBackfill) {
      debugPrint(
        '[Dashboard] depth pilot stats need backfill: '
        '$counterTotal/$expectedPilotRecordCount',
      );
    }

    final userCount = depthsPerPilot[userId] ?? 0;

    final sortedCounts = depthsPerPilot.values.toList()
      ..sort((a, b) => b.compareTo(a));
    final userRanking = userCount > 0
        ? sortedCounts.where((c) => c > userCount).length + 1
        : 0;

    return _DepthDashboardStats(
      totalDepthRecords: totalDepthRecords,
      userDepthRecordCount: userCount,
      topDepthContributorCount: sortedCounts.isEmpty ? 0 : sortedCounts.first,
      userDepthRanking: userRanking,
      totalDepthPilots: depthsPerPilot.length,
    );
  }

  /// Gets user callSign. Returns null on failure so dashboard can still load.
  Future<String?> _getUserCallSign(String userId) async {
    try {
      final userSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
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

class _CrossingDashboardStats {
  final int totalCrossings;
  final int userCrossingCount;
  final int topCrosserCount;
  final int userCrossingRanking;
  final int totalCrossingPilots;

  const _CrossingDashboardStats({
    required this.totalCrossings,
    required this.userCrossingCount,
    required this.topCrosserCount,
    required this.userCrossingRanking,
    required this.totalCrossingPilots,
  });
}

class _DepthDashboardStats {
  final int totalDepthRecords;
  final int userDepthRecordCount;
  final int topDepthContributorCount;
  final int userDepthRanking;
  final int totalDepthPilots;

  const _DepthDashboardStats({
    required this.totalDepthRecords,
    required this.userDepthRecordCount,
    required this.topDepthContributorCount,
    required this.userDepthRanking,
    required this.totalDepthPilots,
  });
}

/// Internal helper to hold the result of a parallel ship ratings query.
class _ShipRatingsResult {
  final QueryDocumentSnapshot ship;
  final QuerySnapshot? ratings;

  _ShipRatingsResult({required this.ship, required this.ratings});
}

/// Internal helper to hold raw rating data before mapping to [RecentRating].
class _RatingEntry {
  final String shipName;
  final String shipId;
  final String ratingId;
  final Map<String, dynamic> data;

  _RatingEntry({
    required this.shipName,
    required this.shipId,
    required this.ratingId,
    required this.data,
  });
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Holds all dashboard statistics and recent activity.
class DashboardData {
  final int totalShips;
  final int totalRatings;
  final int totalCrossings;
  final int totalUsers;
  final int userRatings;
  final int topRaterCount;
  final int userRankingPosition;
  final int totalPilotsWhoRated;
  final int userCrossingCount;
  final int topCrosserCount;
  final int userCrossingRanking;
  final int totalCrossingPilots;
  final int totalDepthRecords;
  final int userDepthRecordCount;
  final int topDepthContributorCount;
  final int userDepthRanking;
  final int totalDepthPilots;
  final List<RecentRating> recentRatings;
  final String? lastRatedShipName;
  final String? lastRatedByPilot;
  final DateTime? lastRatedDate;
  final String? lastRatedShipId;
  final String? lastRatedRatingId;

  DashboardData({
    required this.totalShips,
    required this.totalRatings,
    required this.totalCrossings,
    required this.totalUsers,
    required this.userRatings,
    required this.topRaterCount,
    required this.userRankingPosition,
    required this.totalPilotsWhoRated,
    required this.userCrossingCount,
    required this.topCrosserCount,
    required this.userCrossingRanking,
    required this.totalCrossingPilots,
    required this.totalDepthRecords,
    required this.userDepthRecordCount,
    required this.topDepthContributorCount,
    required this.userDepthRanking,
    required this.totalDepthPilots,
    required this.recentRatings,
    this.lastRatedShipName,
    this.lastRatedByPilot,
    this.lastRatedDate,
    this.lastRatedShipId,
    this.lastRatedRatingId,
  });

  factory DashboardData.empty() => DashboardData(
        totalShips: 0,
        totalRatings: 0,
        totalCrossings: 0,
        totalUsers: 0,
        userRatings: 0,
        topRaterCount: 0,
        userRankingPosition: 0,
        totalPilotsWhoRated: 0,
        userCrossingCount: 0,
        topCrosserCount: 0,
        userCrossingRanking: 0,
        totalCrossingPilots: 0,
        totalDepthRecords: 0,
        userDepthRecordCount: 0,
        topDepthContributorCount: 0,
        userDepthRanking: 0,
        totalDepthPilots: 0,
        recentRatings: [],
      );
}

/// Summary of a single recent rating for dashboard display.
class RecentRating {
  final String shipName;
  final String shipId;
  final String ratingId;
  final DateTime date;
  final double averageScore;

  RecentRating({
    required this.shipName,
    required this.shipId,
    required this.ratingId,
    required this.date,
    required this.averageScore,
  });
}
