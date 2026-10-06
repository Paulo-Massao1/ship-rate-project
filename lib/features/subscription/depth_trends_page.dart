// lib/features/subscription/depth_trends_page.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/services/depth_trend_service.dart';
import '../../shared/widgets/subscription_gate.dart';
import '../navigation_safety/nav_safety_record_detail_page.dart';

/// Premium screen plotting how the depth of one location changed over time.
///
/// The selector lists every location that has depth records; picking one
/// reloads its history through [DepthTrendService]. The card on top shows the
/// latest depth and a horizontally scrollable line chart with every record in
/// the selected period. The list below repeats those records with their exact
/// date and the pilot who saved them.
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
  static const _white20 = Color(0x33FFFFFF);
  static const _white30 = Color(0x4DFFFFFF);
  static const _white40 = Color(0x66FFFFFF);
  static const _white50 = Color(0x80FFFFFF);
  static const _white60 = Color(0x99FFFFFF);

  // Chart and card tints derived from [_premiumColor].
  static const _cardBackground = Color(0x0F64B5F6);
  static const _cardBorder = Color(0x2664B5F6);
  static const _chartAreaColor = Color(0x1464B5F6);
  static const _gridLineColor = Color(0x0AFFFFFF);

  /// Height reserved for the line chart inside the card, value labels included.
  static const double _chartHeight = 190;

  /// Band kept free above the plot area for the value of the highest point.
  static const double _valueLabelBand = 18;

  /// Distance between a dot and the value printed above it.
  static const double _valueLabelGap = 7;

  /// Most labels the Y axis takes before its one-meter step is widened.
  static const int _maxYLabels = 8;

  /// Horizontal room reserved for every recorded depth in the trend.
  static const double _pointSpacing = 62;

  /// Space, measured in X-axis units, before the first and after the last dot.
  /// It keeps edge labels centered instead of forcing them into the plot area.
  static const double _horizontalAxisPadding = 0.55;

  final DepthTrendService _service = DepthTrendService();
  final ScrollController _chartScrollController = ScrollController();

  List<String> _locations = const [];
  String? _selectedLocation;
  DepthTrendPeriod _selectedPeriod = DepthTrendPeriod.sixMonths;

  DepthTrendData? _data;

  bool _loadingLocations = true;
  bool _loadingTrend = false;

  /// Locale used to format depth values, e.g. `pt-BR`.
  String? _locale;

  /// Depth with one decimal in the current locale, e.g. `17,2`.
  late NumberFormat _depthFormat;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _locale = Localizations.localeOf(context).toLanguageTag();
    _depthFormat = NumberFormat.decimalPatternDigits(
      locale: _locale,
      decimalDigits: 1,
    );
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  /// Loads the selector options and opens the first location.
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

    final data = await _service.getTrendData(
      location,
      period: _selectedPeriod,
    );
    if (!mounted) return;

    setState(() {
      _data = data;
      _loadingTrend = false;
    });
    _scrollChartToLatest();
  }

  void _scrollChartToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chartScrollController.hasClients) return;
      _chartScrollController.jumpTo(
        _chartScrollController.position.maxScrollExtent,
      );
    });
  }

  void _onLocationSelected(String? location) {
    if (location == null || location == _selectedLocation || _loadingTrend) {
      return;
    }

    setState(() => _selectedLocation = location);
    _loadTrend();
  }

  void _onPeriodSelected(DepthTrendPeriod period) {
    if (period == _selectedPeriod || _loadingTrend) return;

    setState(() => _selectedPeriod = period);
    _loadTrend();
  }

  void _openRecord(DepthDataPoint point) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavSafetyRecordDetailPage(
          locationName: point.locationName,
          record: point.record,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FORMATTING
  // ===========================================================================

  /// Depth without its unit, e.g. `17,2`.
  String _depthValue(double depth) => _depthFormat.format(depth);

  /// Depth with its unit, e.g. `17,2 m`.
  String _depthLabel(double depth) => '${_depthValue(depth)} m';

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
      return const Center(
        child: CircularProgressIndicator(color: _premiumColor),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            _buildLocationSelector(l10n),
            _buildPeriodSelector(l10n),
            Expanded(child: _buildTrend(l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrend(AppLocalizations l10n) {
    if (_loadingTrend) {
      return const Center(
        child: CircularProgressIndicator(color: _premiumColor),
      );
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
        // [DepthTrendData.dataPoints] already comes most recent first.
        for (final point in data.dataPoints) _buildRecordCard(l10n, point),
      ],
    );
  }

  // ===========================================================================
  // LOCATION SELECTOR
  // ===========================================================================

  Widget _buildLocationSelector(AppLocalizations l10n) {
    final selected = _selectedLocation;
    final enabled = _locations.isNotEmpty && !_loadingTrend;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Material(
        color: _white04,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? () => _openLocationSheet(l10n) : null,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _white10, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: _premiumColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected ?? l10n.selectLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected == null ? _white60 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: _white60,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton(
              label: l10n.sixMonths,
              period: DepthTrendPeriod.sixMonths,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton(
              label: l10n.twelveMonths,
              period: DepthTrendPeriod.twelveMonths,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodButton(
              label: l10n.twoYears,
              period: DepthTrendPeriod.twoYears,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required DepthTrendPeriod period,
  }) {
    final selected = period == _selectedPeriod;

    return Material(
      color: selected ? _cardBackground : _white04,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _loadingTrend ? null : () => _onPeriodSelected(period),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _premiumColor : _white10,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _premiumColor : _white60,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the location list as a bottom sheet.
  ///
  /// A sheet always slides up from the bottom of the screen, while a dropdown
  /// menu opens over the selector and hides what was picked.
  Future<void> _openLocationSheet(AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _white20,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionHeader(l10n.selectLocation),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final location in _locations)
                      _buildLocationTile(sheetContext, location),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) _onLocationSelected(picked);
  }

  Widget _buildLocationTile(BuildContext sheetContext, String location) {
    final isSelected = location == _selectedLocation;

    return ListTile(
      dense: true,
      tileColor: isSelected ? _cardBackground : null,
      leading: Icon(
        Icons.place_outlined,
        size: 18,
        color: isSelected ? _premiumColor : _white60,
      ),
      title: Text(
        location,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isSelected ? _premiumColor : Colors.white,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: _premiumColor, size: 18)
          : null,
      onTap: () => Navigator.pop(sheetContext, location),
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
          _buildSummaryValue(
            label: l10n.lastDepth,
            value: _depthLabel(data.lastDepth),
            valueColor: Colors.white,
            alignment: CrossAxisAlignment.start,
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

  /// Line chart with every depth record in the period, oldest first.
  ///
  /// Each record receives enough horizontal space for its value and date. The
  /// chart scrolls instead of dropping points or aggregating them by month.
  Widget _buildChart(DepthTrendData data) {
    final points = data.dataPoints.reversed.toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = points.length <= 1
            ? constraints.maxWidth
            : (points.length * _pointSpacing) + 34;
        final chartWidth = contentWidth < constraints.maxWidth
            ? constraints.maxWidth
            : contentWidth;
        final canScroll = chartWidth > constraints.maxWidth + 1;

        return Scrollbar(
          controller: _chartScrollController,
          thumbVisibility: canScroll,
          interactive: true,
          thickness: 4,
          radius: const Radius.circular(999),
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: canScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: constraints.maxHeight,
              child: _buildLineChart(points),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLineChart(List<DepthDataPoint> points) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].depth),
    ];

    final bounds = _yAxisBounds(points);
    final lastIndex = spots.length - 1;

    // A single record has no range on the X axis, so it is centered by hand.
    final minX = points.length == 1 ? -1.0 : -_horizontalAxisPadding;
    final maxX = points.length == 1
        ? 1.0
        : lastIndex + _horizontalAxisPadding;

    // Held in a variable because [showingTooltipIndicators] points back at it.
    final bar = LineChartBarData(
      spots: spots,
      color: _premiumColor,
      barWidth: 2,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: true, color: _chartAreaColor),
      dotData: FlDotData(
        // The most recent record is highlighted with a bigger dot.
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: index == lastIndex ? 5 : 4,
          color: _premiumColor,
          strokeColor: _deepNavy,
          strokeWidth: 2,
        ),
      ),
    );

    return Padding(
      // Leaves room for the value printed above the highest dot.
      padding: const EdgeInsets.only(top: _valueLabelBand),
      child: Stack(
        children: [
          Positioned.fill(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: bounds.min,
                maxY: bounds.max,
                backgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                // Tap targets are overlaid separately so horizontal dragging
                // always belongs to the scroll view.
                lineTouchData: LineTouchData(
                  enabled: false,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    tooltipMargin: _valueLabelGap,
                    tooltipRoundedRadius: 3,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => _deepNavy,
                    getTooltipItems: (touchedSpots) => [
                      for (final spot in touchedSpots)
                        _buildValueLabel(spot, lastIndex),
                    ],
                  ),
                ),
                showingTooltipIndicators: [
                  for (var i = 0; i < spots.length; i++)
                    ShowingTooltipIndicators([
                      LineBarSpot(bar, 0, spots[i]),
                    ]),
                ],
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
                      interval: 1,
                      getTitlesWidget: (value, meta) => _buildBottomTitle(
                        value,
                        meta,
                        points,
                      ),
                    ),
                  ),
                ),
                lineBarsData: [bar],
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 0,
            right: 0,
            bottom: 24,
            child: LayoutBuilder(
              builder: (context, constraints) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    final width = constraints.maxWidth;
                    if (width <= 0) return;

                    final chartX = minX +
                        ((details.localPosition.dx / width) * (maxX - minX));
                    final index = chartX
                        .round()
                        .clamp(0, points.length - 1);
                    _openRecord(points[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Depth printed above a dot. The most recent record stands out.
  LineTooltipItem _buildValueLabel(LineBarSpot spot, int lastIndex) {
    final isLast = spot.spotIndex == lastIndex;

    return LineTooltipItem(
      _depthValue(spot.y),
      TextStyle(
        color: isLast ? _premiumColor : _white50,
        fontSize: 9,
        fontWeight: isLast ? FontWeight.bold : FontWeight.w400,
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
    // Only whole positions carry a record, never the padded edges of a chart
    // holding a single record.
    if ((value - index).abs() > 0.01) return const SizedBox.shrink();

    final point = points[index];
    final day = point.date.day.toString().padLeft(2, '0');
    final month = point.date.month.toString().padLeft(2, '0');
    final year = (point.date.year % 100).toString().padLeft(2, '0');
    final label = _selectedPeriod == DepthTrendPeriod.twoYears
        ? '$day/$month/$year'
        : '$day/$month';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(
        label,
        style: const TextStyle(color: _white30, fontSize: 10),
      ),
    );
  }

  /// Y range in whole meters: from the floor of the shallowest record to the
  /// ceiling of the deepest one, one gridline every meter.
  ///
  /// The step only grows past one meter when a single meter would crowd the
  /// axis with more than [_maxYLabels] labels.
  _AxisBounds _yAxisBounds(List<DepthDataPoint> points) {
    var lowest = points.first.depth;
    var highest = points.first.depth;
    for (final point in points) {
      if (point.depth < lowest) lowest = point.depth;
      if (point.depth > highest) highest = point.depth;
    }

    final min = lowest.floorToDouble().clamp(0.0, double.infinity);
    // Extra headroom prevents a value sitting on an exact whole-meter maximum
    // from being clipped by the plot boundary.
    var max = (highest + 0.5).ceilToDouble();
    // Keeps the range positive when every record sits on the same whole meter.
    if (max <= min) max = min + 1;

    final interval = ((max - min) / _maxYLabels).ceilToDouble();
    final step = interval < 1 ? 1.0 : interval;
    // Lands the top of the axis on a label, so gridlines stay evenly spaced.
    final steps = ((max - min) / step).ceilToDouble();

    return _AxisBounds(min: min, max: min + (steps * step), interval: step);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _openRecord(point),
          borderRadius: BorderRadius.circular(8),
          child: Container(
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
                        _dateLabel(point.date),
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
                        l10n.pilotCallSign(pilotName),
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
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: _white40,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
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
