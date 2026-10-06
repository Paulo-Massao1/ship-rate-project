import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../controllers/nav_safety_controller.dart';
import '../../core/constants.dart';

/// Loads the data behind the Premium depth trend graphs.
///
/// A trend is the full depth history of a single location: every `registro`
/// saved for it and the most recent depth.
///
/// Location names come from [NavSafetyController.getCachedLocations], so the
/// selector reuses the list the navigation-safety module already cached.
class DepthTrendService {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NavSafetyController _navSafetyController = NavSafetyController();

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const Duration _queryTimeout = Duration(seconds: 15);

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Names of the locations that have at least one depth record, sorted
  /// alphabetically.
  ///
  /// Locations without records are dropped: there is nothing to plot for them.
  /// Two locations sharing a name are reported once, and
  /// [getTrendData] then merges their records.
  Future<List<String>> getLocationsWithRecords() async {
    try {
      final locations = await _navSafetyController.getCachedLocations();
      final hasRecords = await Future.wait(locations.map(_hasAnyRecord));

      final names = <String>{};
      for (var i = 0; i < locations.length; i++) {
        final name = locations[i].name.trim();
        if (hasRecords[i] && name.isNotEmpty) names.add(name);
      }

      final sorted = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sorted;
    } catch (e) {
      debugPrint('[DepthTrend] Error listing locations with records: $e');
      return const [];
    }
  }

  /// Every depth record of [locationName], most recent first.
  ///
  /// Returns [DepthTrendData.empty] when the location has no record, so the
  /// caller always gets a usable object.
  Future<DepthTrendData> getTrendData(
    String locationName, {
    DepthTrendPeriod period = DepthTrendPeriod.sixMonths,
  }) async {
    final points = <DepthDataPoint>[];
    final startDate = _periodStart(period, DateTime.now());

    try {
      final locations = await _navSafetyController.getCachedLocations();
      final matchingIds = locations
          .where((location) => location.name.trim() == locationName.trim())
          .map((location) => location.id);

      final perLocation = await Future.wait(
        matchingIds.map(
          (id) => _fetchRecords(id, locationName, startDate),
        ),
      );
      points.addAll(perLocation.expand((records) => records));
    } catch (e) {
      debugPrint('[DepthTrend] Error fetching records of $locationName: $e');
    }

    if (points.isEmpty) return DepthTrendData.empty(locationName);

    points.sort((a, b) => b.date.compareTo(a.date));

    return DepthTrendData(
      locationName: locationName,
      lastDepth: points.first.depth,
      dataPoints: points,
    );
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// True when the location owns at least one record. Reads a single doc.
  Future<bool> _hasAnyRecord(LocationWithLatestRecord location) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(location.id)
          .collection(AppConstants.recordsSubcollection)
          .limit(1)
          .get()
          .timeout(_queryTimeout);

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('[DepthTrend] Error checking records of ${location.id}: $e');
      return false;
    }
  }

  /// Depth records of one location, most recent first.
  ///
  /// Records without a date or without a depth are skipped: they cannot be
  /// plotted.
  Future<List<DepthDataPoint>> _fetchRecords(
    String locationId,
    String locationName,
    DateTime startDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .collection(AppConstants.recordsSubcollection)
          .where(
            'data',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .orderBy('data', descending: true)
          .get()
          .timeout(_queryTimeout);

      final records = <DepthDataPoint>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = data['data'];
        final depth = data['profundidadeTotal'];
        if (date is! Timestamp || depth is! num) continue;

        records.add(DepthDataPoint(
          date: date.toDate(),
          depth: depth.toDouble(),
          pilotName: (data['nomeGuerra'] ?? '').toString().trim(),
          locationName: locationName,
          record: {
            ...data,
            'recordId': doc.id,
          },
        ));
      }

      return records;
    } catch (e) {
      debugPrint('[DepthTrend] Error reading records of $locationId: $e');
      return const [];
    }
  }

  DateTime _periodStart(DepthTrendPeriod period, DateTime now) {
    return DateTime(now.year, now.month - period.months + 1);
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

enum DepthTrendPeriod {
  sixMonths(6),
  twelveMonths(12),
  twoYears(24);

  final int months;

  const DepthTrendPeriod(this.months);
}

/// Depth history of a single location.
class DepthTrendData {
  final String locationName;

  /// Depth of the most recent record, in meters.
  final double lastDepth;

  /// Every record of the location, most recent first.
  final List<DepthDataPoint> dataPoints;

  const DepthTrendData({
    required this.locationName,
    required this.lastDepth,
    required this.dataPoints,
  });

  factory DepthTrendData.empty(String locationName) => DepthTrendData(
        locationName: locationName,
        lastDepth: 0.0,
        dataPoints: const [],
      );

  /// True when the location has no record to plot.
  bool get isEmpty => dataPoints.isEmpty;
}

/// A single depth record of the trend.
class DepthDataPoint {
  final DateTime date;

  /// `profundidadeTotal`, in meters.
  final double depth;

  /// Call sign (`nomeGuerra`) of the pilot who saved the record.
  final String pilotName;

  final String locationName;
  final Map<String, dynamic> record;

  const DepthDataPoint({
    required this.date,
    required this.depth,
    required this.pilotName,
    required this.locationName,
    required this.record,
  });
}
