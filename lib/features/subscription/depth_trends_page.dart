// lib/features/subscription/depth_trends_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/services/depth_trend_service.dart';
import '../../shared/widgets/subscription_gate.dart';

/// Premium screen plotting how the depth of one location changed over time.
///
/// The dropdown lists every location that has depth records; picking one
/// reloads its history through [DepthTrendService]. The card on top shows the
/// latest depth, the six-month average and the line chart, and the list below
/// repeats every record with its exact date and the pilot who saved it.
class DepthTrendsPage extends StatefulWidget {
  const DepthTrendsPage({super.key});

  @override
  State<DepthTrendsPage> createState() => _DepthTrendsPageState();
}

class _DepthTrendsPageState extends State<DepthTrendsPage> {
  // Palette of the dark navy screens.
  static const _darkNavy = Color(0xFF0A1628);
  static const _deepNavy = Color(0xFF0D2137);
  static const _premiumColor = Color(0xFF64B5F6);
  static const _depthColor = Color(0xFF26A69A);

  static const _white04 = Color(0x0AFFFFFF);
  static const _white10 = Color(0x1AFFFFFF);
  static const _white30 = Color(0x4DFFFFFF);
  static const _white40 = Color(0x66FFFFFF);
  static const _white60 = Color(0x99FFFFFF);

  // Chart and card tints derived from [_premiumColor].
  static const _cardBackground = Color(0x0F64B5F6);
  static const _cardBorder = Color(0x2664B5F6);
  static const _chartAreaColor = Color(0x1464B5F6);
  static const _averageLineColor = Color(0x4D64B5F6);
  static const _gridLineColor = Color(0x0AFFFFFF);

  /// Height reserved for the line chart inside the card.
  static const double _chartHeight = 180;

  /// Number of labels the X axis aims for, whatever the record count.
  static const int _bottomLabelCount = 5;

  final DepthTrendService _service = DepthTrendService();

  List<String> _locations = const [];
  String? _selectedLocation;

  DepthTrendData? _data;

  bool _loadingLocations = true;
  bool _loadingTrend = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  /// Loads the dropdown options and opens the first location.
  Future<void> _loadLocations() async {
    final locations = await _service.getLocationsWithRecords();
    if (!mounted) return;

    setState(() {
      _locations = locations;
      _selectedLocation = locations.isEmpty ? null : locations.first;
      _loadingLocations = false;
    });

    if (_selectedLocation != null) await _loadTrend();
  }

  Future<void> _loadTrend() async {
    final location = _selectedLocation;
    if (location == null) return;

    setState(() => _loadingTrend = true);

    final data = await _service.getTrendData(location);
    if (!mounted) return;

    setState(() {
      _data = data;
      _loadingTrend = false;
    });
  }

  void _onLocationSelected(String? location) {
    if (location == null || location == _selectedLocation || _loadingTrend) {
      return;
    }

    setState(() => _selectedLocation = location);
    _loadTrend();
  }

  // ===========================================================================
  // FORMATTING
  // ===========================================================================

  String _depthLabel(double depth) => '${depth.toStringAsFixed(1)}m';

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// Abbreviated month of [date] in the current locale, e.g. `Jan`.
  String _monthLabel(DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.MMM(locale).format(date).replaceAll('.', '');
    if (month.isEmpty) return month;
    return month[0].toUpperCase() + month.substring(1);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkNavy, _deepNavy],
          ),
        ),
        child: SubscriptionGate(
          requiredPlan: SubscriptionConstants.planPremium,
          featureDescription: l10n.premiumFeature2,
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      leadingWidth: 96,
      leading: _buildBackButton(l10n),
      title: Text(
        l10n.depthTrends,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black54,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_darkNavy, Color(0xFF1A3A5C), _deepNavy],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () => Navigator.maybePop(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.only(left: 8, right: 6),
        minimumSize: const Size(0, kToolbarHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: 15),
      label: Text(
        l10n.back,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadingLocations) {
      return const Center(child: CircularProgressIndicator(color: _premiumColor));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            _buildLocationSelector(l10n),
            Expanded(child: _buildTrend(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrend(AppLocalizations l10n) {
    if (_loadingTrend) {
      return const Center(child: CircularProgressIndicator(color: _premiumColor));
    }

    final data = _data;
    if (data == null || data.isEmpty) return _buildEmptyState(l10n);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _buildTrendCard(l10n, data),
        const SizedBox(height: 24),
        _buildSectionHeader(l10n.depthHistory),
        const SizedBox(height: 10),
        for (final point in data.dataPoints) _buildRecordCard(l10n, point),
      ],
    );
  }

  // ===========================================================================
  // LOCATION SELECTOR
  // ===========================================================================

  Widget _buildLocationSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _white04,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _white10, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: _premiumColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  dropdownColor: _deepNavy,
                  borderRadius: BorderRadius.circular(8),
                  icon: const Icon(Icons.keyboard_arrow_down, color: _white60),
                  hint: Text(
                    l10n.selectLocation,
                    style: const TextStyle(color: _white60, fontSize: 14),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  items: [
                    for (final location in _locations)
                      DropdownMenuItem<String>(
                        value: location,
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loadingTrend ? null : _onLocationSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TREND CARD
  // ===========================================================================

  Widget _buildTrendCard(AppLocalizations l10n, DepthTrendData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryValue(
                  label: l10n.lastDepth,
                  value: _depthLabel(data.lastDepth),
                  valueColor: Colors.white,
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              const SizedBox(width: 12),
              _buildSummaryValue(
                label: l10n.sixMonthAverage,
                value: _depthLabel(data.sixMonthAverage),
                valueColor: _premiumColor,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(height: _chartHeight, child: _buildChart(data)),
          const SizedBox(height: 14),
          _buildLegend(l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryValue({
    required String label,
    required String value,
    required Color valueColor,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // CHART
  // ===========================================================================

  Widget _buildChart(DepthTrendData data) {
    // Oldest record first, so the line reads left to right.
    final points = data.dataPoints.reversed.toList();
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].depth),
    ];

    final bounds = _yAxisBounds(points);
    final lastIndex = spots.length - 1;

    // A single record has no range on the X axis, so it is centered by hand.
    final minX = points.length == 1 ? -0.5 : 0.0;
    final maxX = points.length == 1 ? 0.5 : lastIndex.toDouble();

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: bounds.min,
        maxY: bounds.max,
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: bounds.interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: _gridLineColor,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: bounds.interval,
              getTitlesWidget: _buildLeftTitle,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _bottomLabelInterval(points.length),
              getTitlesWidget: (value, meta) =>
                  _buildBottomTitle(value, meta, points),
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: data.sixMonthAverage,
              color: _averageLineColor,
              strokeWidth: 1,
              dashArray: const [4, 3],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: _premiumColor,
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: true, color: _chartAreaColor),
            dotData: FlDotData(
              // The most recent record is highlighted with a bigger dot.
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: index == lastIndex ? 5 : 4,
                color: _premiumColor,
                strokeColor: _deepNavy,
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(
        '${value.toStringAsFixed(0)}m',
        style: const TextStyle(color: _white30, fontSize: 10),
      ),
    );
  }

  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<DepthDataPoint> points,
  ) {
    final index = value.round();
    if (index < 0 || index >= points.length) return const SizedBox.shrink();

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        _monthLabel(points[index].date),
        style: const TextStyle(color: _white30, fontSize: 10),
      ),
    );
  }

  /// Y range rounded to whole meters, with one meter of headroom on each side
  /// so the first and last dots are never clipped.
  _AxisBounds _yAxisBounds(List<DepthDataPoint> points) {
    var lowest = points.first.depth;
    var highest = points.first.depth;
    for (final point in points) {
      if (point.depth < lowest) lowest = point.depth;
      if (point.depth > highest) highest = point.depth;
    }

    final min = (lowest.floorToDouble() - 1).clamp(0.0, double.infinity);
    final max = highest.ceilToDouble() + 1;
    // Keeps the range positive even when every record sits on the minimum.
    final top = max > min ? max : min + 1;
    // Aims for four labels, never closer than one meter apart.
    final steps = ((top - min) / 3).ceilToDouble();

    return _AxisBounds(
      min: min,
      max: top,
      interval: steps < 1 ? 1 : steps,
    );
  }

  /// Number of records between two X labels.
  double _bottomLabelInterval(int pointCount) {
    if (pointCount <= _bottomLabelCount) return 1;
    return (pointCount / _bottomLabelCount).ceilToDouble();
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _premiumColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.depth,
          style: const TextStyle(color: _white60, fontSize: 11),
        ),
        const SizedBox(width: 16),
        const _DashedLineMark(color: _averageLineColor),
        const SizedBox(width: 6),
        Text(
          l10n.average,
          style: const TextStyle(color: _white60, fontSize: 11),
        ),
      ],
    );
  }

  // ===========================================================================
  // RECORD HISTORY
  // ===========================================================================

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: _white40,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildRecordCard(AppLocalizations l10n, DepthDataPoint point) {
    final pilotName =
        point.pilotName.isEmpty ? l10n.notAvailable : point.pilotName;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: BoxDecoration(
        color: _white04,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_dateLabel(point.date)} — ${l10n.pilotCallSign(pilotName)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _white60, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _depthLabel(point.depth),
            style: const TextStyle(
              color: _depthColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart, color: _white40, size: 42),
            const SizedBox(height: 14),
            Text(
              l10n.noRecords,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Y axis range of the chart and the distance between two labels.
class _AxisBounds {
  final double min;
  final double max;
  final double interval;

  const _AxisBounds({
    required this.min,
    required this.max,
    required this.interval,
  });
}

/// Dashed stroke standing for the average line in the legend.
class _DashedLineMark extends StatelessWidget {
  final Color color;

  const _DashedLineMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(width: 4, height: 2, color: color),
        ],
      ],
    );
  }
}
