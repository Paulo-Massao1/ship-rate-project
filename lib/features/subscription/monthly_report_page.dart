// lib/features/subscription/monthly_report_page.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/services/monthly_report_service.dart';
import '../../shared/widgets/subscription_gate.dart';
import 'monthly_report_pdf.dart';

/// Plus screen showing what the pilot contributed during one month.
///
/// The month selector offers every month since the pilot created the account;
/// picking one reloads the data through [MonthlyReportService]. The two buttons
/// at the bottom render the same data as a PDF, either to save or to share, and
/// are disabled on a month with no contributions.
class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  // Palette of the dark navy screens.
  static const _darkNavy = Color(0xFF0A1628);
  static const _deepNavy = Color(0xFF0D2137);
  static const _plusColor = Color(0xFFFFB74D);
  static const _ratingsColor = Color(0xFF64B5F6);
  static const _depthsColor = Color(0xFF26A69A);

  static const _white04 = Color(0x0AFFFFFF);
  static const _white20 = Color(0x33FFFFFF);
  static const _white40 = Color(0x66FFFFFF);
  static const _white60 = Color(0x99FFFFFF);

  final MonthlyReportService _service = MonthlyReportService();

  /// Empty until [_loadMonths] resolves the first month of the pilot.
  List<DateTime> _availableMonths = const [];
  late DateTime _selectedMonth;

  /// Month the app is in: the only one still collecting contributions.
  late final DateTime _currentMonth;

  /// Contributions of each month, filled in as the reports are generated.
  ///
  /// A total is `ratings + depths + crossings` of the month, and is only known
  /// once the report of that month has been built: there is no cheap query for
  /// it, and building every month up front would rescan the ratings of every
  /// ship once per month. So the sheet shows the total of the months already
  /// opened and only the name of the others.
  final Map<DateTime, int> _monthTotals = {};

  MonthlyReportData? _data;
  bool _loading = true;

  /// True while a PDF is being rendered, so the buttons cannot be spammed.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedMonth = _currentMonth;
    _loadMonths();
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  /// Resolves the months the pilot can pick and opens the most recent one.
  Future<void> _loadMonths() async {
    final months = await _service.getAvailableMonths();
    if (!mounted) return;

    setState(() {
      _availableMonths = months;
      if (months.isNotEmpty) _selectedMonth = months.first;
    });
    await _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);

    final month = _selectedMonth;
    final data = await _service.generateReport(month);
    if (!mounted) return;

    setState(() {
      _data = data;
      // Remembered for the month sheet, which has no other way of knowing it.
      _monthTotals[month] = data.ratings.length +
          data.depthRecords.length +
          data.crossings.length;
      _loading = false;
    });
  }

  void _onMonthSelected(DateTime month) {
    if (month == _selectedMonth || _loading) return;

    setState(() => _selectedMonth = month);
    _loadReport();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Renders the report and opens the system print / save sheet.
  Future<void> _downloadPdf() async {
    await _exportPdf(
      (bytes, fileName) => Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: fileName,
      ),
    );
  }

  /// Renders the report and hands it to the system share sheet.
  Future<void> _sharePdf() async {
    await _exportPdf(
      (bytes, fileName) => Printing.sharePdf(bytes: bytes, filename: fileName),
    );
  }

  Future<void> _exportPdf(
    Future<void> Function(Uint8List bytes, String fileName) deliver,
  ) async {
    final data = _data;
    if (data == null || _exporting) return;

    final l10n = AppLocalizations.of(context)!;
    final labels = _buildPdfLabels(l10n, data);

    setState(() => _exporting = true);
    try {
      final bytes = await MonthlyReportPdf(labels).generatePdf(data);
      await deliver(bytes, _fileName(data.month));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingData(error.toString())),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _fileName(DateTime month) {
    final paddedMonth = month.month.toString().padLeft(2, '0');
    return 'shiprate_${month.year}_$paddedMonth.pdf';
  }

  MonthlyReportPdfLabels _buildPdfLabels(
    AppLocalizations l10n,
    MonthlyReportData data,
  ) {
    return MonthlyReportPdfLabels(
      monthTitle: _monthLabel(data.month),
      contributionReport: l10n.contributionReport,
      yourRankings: l10n.yourRankings,
      noContributions: l10n.noContributions,
      autoGenerated: l10n.reportAutoGenerated,
      ratingsOfMonth: l10n.ratingsOfMonth,
      depthsRecorded: l10n.depthsRecorded,
      crossingsReported: l10n.crossingsReported,
      ratings: l10n.ratings,
      depths: l10n.navSafetyModule,
      crossings: l10n.totalCrossingsLabel,
      shipColumn: l10n.reportShipColumn,
      dateColumn: l10n.pdfDateLabel,
      averageColumn: l10n.reportAverageColumn,
      locationColumn: l10n.crossingLocation,
      totalDepthColumn: l10n.totalDepth,
      generatedOn: l10n.reportGenerated,
      ofTotalPilots: l10n.ofTotalPilots,
    );
  }

  // ===========================================================================
  // FORMATTING
  // ===========================================================================

  /// Month and year in the current locale, capitalised, e.g. `Setembro 2026`.
  String _monthLabel(DateTime month) {
    final locale = Localizations.localeOf(context).toString();
    final label = DateFormat('MMMM yyyy', locale).format(month);
    if (label.isEmpty) return label;
    return label[0].toUpperCase() + label.substring(1);
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _directionLabel(String value, AppLocalizations l10n) {
    switch (value.toLowerCase()) {
      case 'subindo':
        return l10n.directionUp;
      case 'baixando':
        return l10n.directionDown;
      default:
        return l10n.notAvailable;
    }
  }

  /// `ShipRate Plus` or `ShipRate Premium`, matching the plan on the profile.
  String _planLabel(String plan, AppLocalizations l10n) {
    final name = plan == SubscriptionConstants.planPremium
        ? l10n.premiumPlan
        : l10n.plusPlan;
    return 'ShipRate $name';
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
        // Plus unlocks the report, Premium includes Plus.
        child: SubscriptionGate(
          requiredPlan: SubscriptionConstants.planPlus,
          featureDescription: l10n.plusFeature1,
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      leadingWidth: 96,
      leading: _buildBackButton(l10n),
      title: Column(
        children: [
          Text(
            l10n.monthlyReport,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _monthLabel(_selectedMonth),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _white60, fontSize: 11),
          ),
        ],
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            _buildMonthSelector(l10n),
            Expanded(
              child: _loading || _data == null
                  ? _buildLoading()
                  : _buildReport(l10n, _data!),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown while the report of a month is being built, so switching months
  /// never leaves the screen blank.
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _plusColor),
          const SizedBox(height: 14),
          Text(
            _monthLabel(_selectedMonth),
            style: const TextStyle(color: _white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MONTH SELECTOR
  // ===========================================================================

  /// Field that opens the month sheet, reading out the month in use.
  Widget _buildMonthSelector(AppLocalizations l10n) {
    final enabled = !_loading && _availableMonths.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Material(
        color: _white04,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? () => _openMonthSheet(l10n) : null,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _white20, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: _plusColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _monthLabel(_selectedMonth),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  /// Opens the month list as a bottom sheet, most recent month first.
  ///
  /// A sheet always slides up from the bottom of the screen, while a dropdown
  /// menu opens over the selector and hides the month it is offering to
  /// replace. Tapping outside it or dragging it down closes it unchanged.
  Future<void> _openMonthSheet(AppLocalizations l10n) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: _deepNavy,
      // A long list of months needs more than the default half of the screen.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag handle.
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _white20,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.selectMonth,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5, color: _white20),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    for (final month in _availableMonths)
                      _buildMonthTile(sheetContext, l10n, month),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) _onMonthSelected(picked);
  }

  /// One row of the month sheet: the month, how much it holds, and the note
  /// that the current month is not over yet.
  Widget _buildMonthTile(
    BuildContext sheetContext,
    AppLocalizations l10n,
    DateTime month,
  ) {
    final isSelected = month == _selectedMonth;
    final total = _monthTotals[month];

    return ListTile(
      dense: true,
      tileColor: isSelected ? _white04 : null,
      leading: Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: isSelected ? _depthsColor : _white60,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              _monthLabel(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? _depthsColor : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (month == _currentMonth) ...[
            const SizedBox(width: 6),
            Text(
              '(${l10n.inProgress})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _white40, fontSize: 11),
            ),
          ],
        ],
      ),
      // The total is only known for the months already opened. A month with no
      // contributions stays selectable, it just reads greyer.
      subtitle: total == null
          ? null
          : Text(
              l10n.monthRecords(total),
              style: TextStyle(
                color: total == 0 ? _white40 : _white60,
                fontSize: 11,
              ),
            ),
      trailing: isSelected
          ? const Icon(Icons.check, color: _depthsColor, size: 18)
          : null,
      onTap: () => Navigator.pop(sheetContext, month),
    );
  }

  // ===========================================================================
  // REPORT
  // ===========================================================================

  Widget _buildReport(AppLocalizations l10n, MonthlyReportData data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _buildPilotCard(l10n, data),
        const SizedBox(height: 16),
        _buildSummaryGrid(l10n, data),
        if (data.isEmpty) _buildEmptyState(l10n),
        // A section with nothing in it is dropped instead of showing a header
        // above an empty list.
        if (data.ratings.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.ratingsOfMonth),
          const SizedBox(height: 10),
          for (final rating in data.ratings) _buildRatingCard(rating),
        ],
        if (data.depthRecords.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.depthsRecorded),
          const SizedBox(height: 10),
          for (final record in data.depthRecords) _buildDepthCard(record),
        ],
        if (data.crossings.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.crossingsReported),
          const SizedBox(height: 10),
          for (final crossing in data.crossings)
            _buildCrossingCard(l10n, crossing),
        ],
        const SizedBox(height: 28),
        // Nothing to export on a month without contributions.
        _buildActionButtons(l10n, enabled: !data.isEmpty),
      ],
    );
  }

  Widget _buildPilotCard(AppLocalizations l10n, MonthlyReportData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFB74D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x26FFB74D), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1FFFB74D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: _plusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.pilotName.isEmpty ? l10n.notAvailable : data.pilotName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_monthLabel(data.month)} — '
                  '${_planLabel(data.subscriptionPlan, l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(AppLocalizations l10n, MonthlyReportData data) {
    // The three cards share the height of the tallest one. Stretching them
    // needs IntrinsicHeight here: the report list leaves the height unbounded,
    // and a stretch against an unbounded height fails to lay out, which used to
    // leave the whole report blank.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildSummaryCard(
              value: data.ratings.length,
              label: l10n.ratings,
              color: _ratingsColor,
              background: const Color(0x1464B5F6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              value: data.depthRecords.length,
              label: l10n.navSafetyModule,
              color: _depthsColor,
              background: const Color(0x1426A69A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              value: data.crossings.length,
              label: l10n.totalCrossingsLabel,
              color: _plusColor,
              background: const Color(0x14FFB74D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _white60, fontSize: 10),
          ),
        ],
      ),
    );
  }

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

  // ===========================================================================
  // LIST CARDS
  // ===========================================================================

  Widget _buildRatingCard(MonthlyRating rating) {
    return _buildListCard(
      title: rating.shipName,
      subtitle: _dateLabel(rating.date),
      trailing: rating.averageScore.toStringAsFixed(1),
    );
  }

  Widget _buildDepthCard(MonthlyDepthRecord record) {
    return _buildListCard(
      title: record.locationName,
      subtitle: _dateLabel(record.date),
      trailing: '${record.totalDepth.toStringAsFixed(1)}m',
    );
  }

  Widget _buildCrossingCard(AppLocalizations l10n, MonthlyCrossing crossing) {
    return _buildListCard(
      title: crossing.shipName,
      subtitle: '${_dateLabel(crossing.date)} — ${crossing.locationName}',
      trailing: _directionLabel(crossing.direction, l10n),
      trailingColor: _white60,
      trailingSize: 11,
    );
  }

  /// Shared row of the three lists: title and date on the left, value on the
  /// right.
  Widget _buildListCard({
    required String title,
    required String subtitle,
    required String trailing,
    Color trailingColor = _depthsColor,
    double trailingSize = 15,
  }) {
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
                  title,
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
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _white60, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: TextStyle(
              color: trailingColor,
              fontSize: trailingSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE AND ACTIONS
  // ===========================================================================

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.insert_chart_outlined, color: _white40, size: 42),
          const SizedBox(height: 14),
          Text(
            l10n.noContributions,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, {required bool enabled}) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: l10n.downloadPdf,
            icon: Icons.download,
            filled: true,
            enabled: enabled,
            onPressed: _downloadPdf,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: l10n.share,
            icon: Icons.share,
            filled: false,
            enabled: enabled,
            onPressed: _sharePdf,
          ),
        ),
      ],
    );
  }

  /// A disabled button keeps its place in the layout but loses the accent
  /// colour and the tap handler.
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final foreground = enabled ? (filled ? _darkNavy : Colors.white) : _white40;
    final background = filled && enabled ? _plusColor : Colors.transparent;

    return Opacity(
      opacity: _exporting ? 0.6 : 1.0,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled && !_exporting ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: filled && enabled ? null : Border.all(color: _white20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
