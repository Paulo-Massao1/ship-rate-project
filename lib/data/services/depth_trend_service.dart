import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../controllers/nav_safety_controller.dart';
import '../../core/constants.dart';

/// Loads the data behind the Premium depth trend graphs.
///
/// A trend is the full depth history of a single location: every `registro`
/// saved for it, the most recent depth, one plottable point per month and the
/// average of those points.
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

  /// Months plotted by the chart, and the window of
  /// [DepthTrendData.sixMonthAverage].
  static const int _monthWindow = 6;

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

  /// Every depth record of [locationName], most recent first, plus the monthly
  /// points the chart plots.
  ///
  /// [locale] names the language of [DepthMonthPoint.monthLabel], e.g. `pt`.
  /// Returns [DepthTrendData.empty] when the location has no record, so the
  /// caller always gets a usable object.
  Future<DepthTrendData> getTrendData(
    String locationName, {
    String? locale,
  }) async {
    final points = <DepthDataPoint>[];

    try {
      final locations = await _navSafetyController.getCachedLocations();
      final matchingIds = locations
          .where((location) => location.name.trim() == locationName.trim())
          .map((location) => location.id);

      final perLocation = await Future.wait(
        matchingIds.map((id) => _fetchRecords(id, locationName)),
      );
      points.addAll(perLocation.expand((records) => records));
    } catch (e) {
      debugPrint('[DepthTrend] Error fetching records of $locationName: $e');
    }

    if (points.isEmpty) return DepthTrendData.empty(locationName);

    points.sort((a, b) => b.date.compareTo(a.date));
    final monthlyPoints = _aggregateByMonth(points, locale);

    return DepthTrendData(
      locationName: locationName,
      lastDepth: points.first.depth,
      sixMonthAverage: _averageOf(monthlyPoints),
      dataPoints: points,
      monthlyPoints: monthlyPoints,
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
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.locationsCollection)
          .doc(locationId)
          .collection(AppConstants.recordsSubcollection)
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
        ));
      }

      return records;
    } catch (e) {
      debugPrint('[DepthTrend] Error reading records of $locationId: $e');
      return const [];
    }
  }

  /// One point per month — the most recent record of that month — for the last
  /// [_monthWindow] months that hold a record, oldest first.
  ///
  /// Months without a record are skipped instead of drawn as a gap, so the
  /// chart always plots a continuous line.
  List<DepthMonthPoint> _aggregateByMonth(
    List<DepthDataPoint> points,
    String? locale,
  ) {
    // [points] comes most recent first, so the first record met in a month is
    // that month's most recent one.
    final latestOfMonth = <DateTime, DepthDataPoint>{};
    for (final point in points) {
      final month = DateTime(point.date.year, point.date.month);
      latestOfMonth.putIfAbsent(month, () => point);
    }

    final months = latestOfMonth.keys.toList()..sort();
    final visible = months.length <= _monthWindow
        ? months
        : months.sublist(months.length - _monthWindow);

    return [
      for (final month in visible)
        DepthMonthPoint(
          month: month,
          monthLabel: _monthAbbreviation(month, locale),
          record: latestOfMonth[month]!,
        ),
    ];
  }

  /// Abbreviated month name of [month] in [locale], e.g. `Jan`.
  String _monthAbbreviation(DateTime month, String? locale) {
    final text = DateFormat.MMM(locale).format(month).replaceAll('.', '');
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Average depth of the monthly points the chart plots.
  double _averageOf(List<DepthMonthPoint> points) {
    if (points.isEmpty) return 0.0;

    final total =
        points.fold<double>(0.0, (value, point) => value + point.depth);
    return total / points.length;
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Depth history of a single location.
class DepthTrendData {
  final String locationName;

  /// Depth of the most recent record, in meters.
  final double lastDepth;

  /// Average depth of [monthlyPoints], in meters.
  final double sixMonthAverage;

  /// Every record of the location, most recent first.
  final List<DepthDataPoint> dataPoints;

  /// The plotted points: one per month, at most six, oldest first.
  final List<DepthMonthPoint> monthlyPoints;

  const DepthTrendData({
    required this.locationName,
    required this.lastDepth,
    required this.sixMonthAverage,
    required this.dataPoints,
    required this.monthlyPoints,
  });

  factory DepthTrendData.empty(String locationName) => DepthTrendData(
        locationName: locationName,
        lastDepth: 0.0,
        sixMonthAverage: 0.0,
        dataPoints: const [],
        monthlyPoints: const [],
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

  const DepthDataPoint({
    required this.date,
    required this.depth,
    required this.pilotName,
    required this.locationName,
  });
}

/// One month of the trend, standing for its most recent record.
class DepthMonthPoint {
  /// First day of the month this point stands for.
  final DateTime month;

  /// Abbreviated month name shown on the X axis, e.g. `Jan`.
  final String monthLabel;

  /// Most recent record saved in [month].
  final DepthDataPoint record;

  const DepthMonthPoint({
    required this.month,
    required this.monthLabel,
    required this.record,
  });

  /// Depth plotted for the month, in meters.
  double get depth => record.depth;
}
