// lib/features/subscription/monthly_report_pdf.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/services/monthly_report_service.dart';

/// Builds the printable version of the Plus monthly report.
///
/// The document is a white A4 page with a dark navy header, three coloured
/// summary cards, one table per module and a ranking card. Long months paginate
/// on their own because everything is laid out inside a [pw.MultiPage].
///
/// PDF widgets have no access to [AppLocalizations], so every user facing
/// string - including the month name and the direction of a crossing - is
/// passed in through [MonthlyReportPdfLabels].
class MonthlyReportPdf {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// Header background, same navy the app uses.
  static final _darkNavy = PdfColor.fromHex('#0A1628');
  static final _brandBlue = PdfColor.fromHex('#64B5F6');

  /// White blended over [_darkNavy] at 70% and 55%. Solid colours are used
  /// instead of translucent white so the text renders the same on every viewer.
  static final _headerText = PdfColor.fromHex('#B6B9BE');
  static final _headerMutedText = PdfColor.fromHex('#909AA4');
  static final _headerDivider = PdfColor.fromHex('#2A3846');

  // Summary cards and table headers: one tint per module.
  static final _ratingsTint = PdfColor.fromHex('#F0F7FF');
  static final _depthsTint = PdfColor.fromHex('#E8F5E9');
  static final _crossingsTint = PdfColor.fromHex('#FFF8E1');

  static final _ratingsAccent = PdfColor.fromHex('#1976D2');
  static final _depthsAccent = PdfColor.fromHex('#00796B');
  static final _crossingsAccent = PdfColor.fromHex('#B26A00');

  /// Average score colour inside the ratings table.
  static final _averageGreen = PdfColor.fromHex('#1B8A5A');

  static final _rankingsBackground = PdfColor.fromHex('#F8F9FA');
  static final _cardBorder = PdfColor.fromHex('#E9ECEF');
  static final _bodyText = PdfColor.fromHex('#2C3E50');
  static final _mutedText = PdfColor.fromHex('#78889A');
  static final _stripeBackground = PdfColor.fromHex('#FAFBFC');
  static final _footerText = PdfColor.fromHex('#9E9E9E');

  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final MonthlyReportPdfLabels labels;

  const MonthlyReportPdf(this.labels);

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Renders [data] and returns the bytes of the finished document.
  Future<Uint8List> generatePdf(MonthlyReportData data) async {
    final document = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final documentTheme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    document.addPage(
      pw.MultiPage(
        theme: documentTheme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        footer: (_) => _buildFooter(),
        build: (_) => [
          _buildHeader(data, dateFormat),
          pw.SizedBox(height: 18),
          _buildSummaryCards(data),
          if (data.ratings.isNotEmpty)
            ..._buildRatingsSection(data, dateFormat),
          if (data.depthRecords.isNotEmpty)
            ..._buildDepthsSection(data, dateFormat),
          if (data.crossings.isNotEmpty)
            ..._buildCrossingsSection(data, dateFormat),
          if (data.isEmpty) ...[
            pw.SizedBox(height: 20),
            _buildEmptyNotice(),
          ],
          pw.SizedBox(height: 20),
          _buildRankingsCard(data),
        ],
      ),
    );

    return document.save();
  }

  // ===========================================================================
  // PRIVATE METHODS - HEADER
  // ===========================================================================

  pw.Widget _buildHeader(MonthlyReportData data, DateFormat dateFormat) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _darkNavy,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'SHIPRATE PRO',
                  style: pw.TextStyle(
                    color: _brandBlue,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              pw.Text(
                labels.generatedOn(dateFormat.format(DateTime.now())),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(color: _headerMutedText, fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            labels.monthTitle,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            labels.contributionReport,
            style: pw.TextStyle(color: _headerText, fontSize: 12),
          ),
          pw.SizedBox(height: 14),
          pw.Container(height: 0.8, color: _headerDivider),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildPersonGlyph(_brandBlue),
              pw.SizedBox(width: 8),
              pw.Text(
                data.pilotName,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Person silhouette drawn from two shapes.
  ///
  /// The default PDF theme ships no icon font, so downloading one just for this
  /// badge would make the report depend on the network.
  pw.Widget _buildPersonGlyph(PdfColor color) {
    return pw.SizedBox(
      width: 14,
      height: 14,
      child: pw.Stack(
        children: [
          pw.Positioned(
            left: 4.2,
            top: 1,
            child: pw.Container(
              width: 5.6,
              height: 5.6,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
          ),
          pw.Positioned(
            left: 1.4,
            top: 8,
            child: pw.Container(
              width: 11.2,
              height: 5.6,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(5.6),
                  topRight: pw.Radius.circular(5.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - SUMMARY
  // ===========================================================================

  pw.Widget _buildSummaryCards(MonthlyReportData data) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryCard(
            value: data.ratings.length,
            label: labels.ratings,
            background: _ratingsTint,
            accent: _ratingsAccent,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildSummaryCard(
            value: data.depthRecords.length,
            label: labels.depths,
            background: _depthsTint,
            accent: _depthsAccent,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildSummaryCard(
            value: data.crossings.length,
            label: labels.crossings,
            background: _crossingsTint,
            accent: _crossingsAccent,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryCard({
    required int value,
    required String label,
    required PdfColor background,
    required PdfColor accent,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '$value',
            style: pw.TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(color: _mutedText, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - TABLES
  // ===========================================================================

  List<pw.Widget> _buildRatingsSection(
    MonthlyReportData data,
    DateFormat dateFormat,
  ) {
    return _buildSection(
      title: labels.ratingsOfMonth,
      accent: _ratingsAccent,
      table: _buildTable(
        headerBackground: _ratingsTint,
        headerColor: _ratingsAccent,
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(1.4),
          2: pw.FlexColumnWidth(1),
        },
        headers: [labels.shipColumn, labels.dateColumn, labels.averageColumn],
        rows: [
          for (var i = 0; i < data.ratings.length; i++)
            _buildRow(
              index: i,
              cells: [
                _cell(data.ratings[i].shipName),
                _cell(dateFormat.format(data.ratings[i].date)),
                _cell(
                  data.ratings[i].averageScore.toStringAsFixed(1),
                  color: _averageGreen,
                  bold: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildDepthsSection(
    MonthlyReportData data,
    DateFormat dateFormat,
  ) {
    return _buildSection(
      title: labels.depthsRecorded,
      accent: _depthsAccent,
      table: _buildTable(
        headerBackground: _depthsTint,
        headerColor: _depthsAccent,
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(1.4),
          2: pw.FlexColumnWidth(1.2),
        },
        headers: [
          labels.locationColumn,
          labels.dateColumn,
          labels.totalDepthColumn,
        ],
        rows: [
          for (var i = 0; i < data.depthRecords.length; i++)
            _buildRow(
              index: i,
              cells: [
                _cell(data.depthRecords[i].locationName),
                _cell(dateFormat.format(data.depthRecords[i].date)),
                _cell(
                  // Depth values carry the same bare `m` suffix as the app.
                  '${data.depthRecords[i].totalDepth.toStringAsFixed(1)}m',
                  color: _depthsAccent,
                  bold: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildCrossingsSection(
    MonthlyReportData data,
    DateFormat dateFormat,
  ) {
    return _buildSection(
      title: labels.crossingsReported,
      accent: _crossingsAccent,
      table: _buildTable(
        headerBackground: _crossingsTint,
        headerColor: _crossingsAccent,
        // The crossings table ends on a date, not on a value.
        lastColumnIsValue: false,
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(1.4),
        },
        headers: [
          labels.shipColumn,
          labels.locationColumn,
          labels.dateColumn,
        ],
        rows: [
          for (var i = 0; i < data.crossings.length; i++)
            _buildRow(
              index: i,
              cells: [
                _cell(data.crossings[i].shipName),
                _cell(data.crossings[i].locationName),
                _cell(dateFormat.format(data.crossings[i].date)),
              ],
            ),
        ],
      ),
    );
  }

  /// Title and table as separate children of the [pw.MultiPage].
  ///
  /// Wrapping them in a column would stop the table from spanning pages, which
  /// pushes a whole long table to the next page and leaves the title alone.
  List<pw.Widget> _buildSection({
    required String title,
    required PdfColor accent,
    required pw.Widget table,
  }) {
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        title,
        style: pw.TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 8),
      table,
    ];
  }

  pw.Widget _buildTable({
    required PdfColor headerBackground,
    required PdfColor headerColor,
    required Map<int, pw.TableColumnWidth> columnWidths,
    required List<String> headers,
    required List<pw.TableRow> rows,
    bool lastColumnIsValue = true,
  }) {
    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: _cardBorder, width: 0.5),
      children: [
        pw.TableRow(
          // Repeated at the top of every page the table spans.
          repeat: true,
          decoration: pw.BoxDecoration(color: headerBackground),
          children: [
            for (var i = 0; i < headers.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 8,
                ),
                child: pw.Text(
                  headers[i],
                  // Value columns are right aligned, like a total.
                  textAlign: lastColumnIsValue && i == headers.length - 1
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                  style: pw.TextStyle(
                    color: headerColor,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        ...rows,
      ],
    );
  }

  /// Table row with the zebra striping the mockup asks for.
  pw.TableRow _buildRow({required int index, required List<pw.Widget> cells}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: index.isEven ? PdfColors.white : _stripeBackground,
      ),
      children: cells,
    );
  }

  pw.Widget _cell(
    String value, {
    PdfColor? color,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          color: color ?? _bodyText,
          fontSize: 9.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - RANKINGS
  // ===========================================================================

  pw.Widget _buildRankingsCard(MonthlyReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _rankingsBackground,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _cardBorder, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            labels.yourRankings,
            style: pw.TextStyle(
              color: _bodyText,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildRankingColumn(
                  position: data.ratingRanking,
                  module: labels.ratings,
                  totalPilots: data.totalPilots,
                  accent: _ratingsAccent,
                ),
              ),
              pw.Expanded(
                child: _buildRankingColumn(
                  position: data.depthRanking,
                  module: labels.depths,
                  totalPilots: data.totalPilots,
                  accent: _depthsAccent,
                ),
              ),
              pw.Expanded(
                child: _buildRankingColumn(
                  position: data.crossingRanking,
                  module: labels.crossings,
                  totalPilots: data.totalPilots,
                  accent: _crossingsAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRankingColumn({
    required int position,
    required String module,
    required int totalPilots,
    required PdfColor accent,
  }) {
    // A position of 0 means the pilot is not ranked in that module.
    final isRanked = position > 0;

    return pw.Column(
      children: [
        pw.Text(
          isRanked ? '#$position' : '-',
          style: pw.TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          module,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: _bodyText,
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          labels.ofTotalPilots(totalPilots),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(color: _mutedText, fontSize: 8.5),
        ),
      ],
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - EMPTY STATE AND FOOTER
  // ===========================================================================

  pw.Widget _buildEmptyNotice() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: _rankingsBackground,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _cardBorder, width: 0.5),
      ),
      child: pw.Center(
        child: pw.Text(
          labels.noContributions,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(color: _mutedText, fontSize: 10),
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14),
      child: pw.Center(
        child: pw.Text(
          'ShipRate Pro - ${labels.autoGenerated}',
          style: pw.TextStyle(color: _footerText, fontSize: 8.5),
        ),
      ),
    );
  }
}

// =============================================================================
// LABELS
// =============================================================================

/// Translated strings the monthly report PDF renders.
///
/// Built on the screen, where [AppLocalizations] is reachable, and handed to
/// [MonthlyReportPdf] so the document itself never touches a [BuildContext].
class MonthlyReportPdfLabels {
  /// Month and year of the report, already localised (e.g. `setembro de 2026`).
  final String monthTitle;

  final String contributionReport;
  final String yourRankings;
  final String noContributions;
  final String autoGenerated;

  // Section titles.
  final String ratingsOfMonth;
  final String depthsRecorded;
  final String crossingsReported;

  // Summary card and ranking column labels.
  final String ratings;
  final String depths;
  final String crossings;

  // Table column headers.
  final String shipColumn;
  final String dateColumn;
  final String averageColumn;
  final String locationColumn;
  final String totalDepthColumn;

  /// `Gerado em {date}` for the header.
  final String Function(String date) generatedOn;

  /// `de {total} práticos` under each ranking position.
  final String Function(int total) ofTotalPilots;

  const MonthlyReportPdfLabels({
    required this.monthTitle,
    required this.contributionReport,
    required this.yourRankings,
    required this.noContributions,
    required this.autoGenerated,
    required this.ratingsOfMonth,
    required this.depthsRecorded,
    required this.crossingsReported,
    required this.ratings,
    required this.depths,
    required this.crossings,
    required this.shipColumn,
    required this.dateColumn,
    required this.averageColumn,
    required this.locationColumn,
    required this.totalDepthColumn,
    required this.generatedOn,
    required this.ofTotalPilots,
  });
}
