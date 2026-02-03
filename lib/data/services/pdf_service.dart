import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

/// Service responsible for generating and exporting ship rating PDFs.
///
/// Supports both mobile (native share dialog) and web (automatic download).
/// Generates professional reports with ShipRate branding.
class PdfService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _primaryColor = '#3F51B5';
  static const _lightPrimaryColor = '#E8EAF6';
  static const _borderColor = '#E0E0E0';
  static const _backgroundGray = '#F5F5F7';
  static const _warningBackground = '#FFF9E6';
  static const _warningBorder = '#FFD700';
  static const _warningText = '#FF9800';

  // Rating color thresholds
  static const _excellentRating = 4.5;
  static const _goodRating = 3.5;
  static const _averageRating = 2.5;
  static const _belowAverageRating = 1.5;

  // Rating colors
  static const _colorExcellent = '#4CAF50';
  static const _colorGood = '#8BC34A';
  static const _colorAverage = '#FF9800';
  static const _colorBelowAverage = '#FF5722';
  static const _colorPoor = '#F44336';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Generates a complete PDF document for a ship rating.
  ///
  /// Parameters:
  /// - [shipName]: Name of the ship being rated
  /// - [shipImo]: Optional IMO number
  /// - [evaluatorName]: Name of the maritime pilot
  /// - [evaluationDate]: Date when evaluation was created
  /// - [cabinType]: Type of cabin occupied
  /// - [disembarkationDate]: Date of disembarkation
  /// - [ratings]: Map of criteria with scores and observations
  /// - [generalObservation]: Optional general comments
  /// - [shipInfo]: Optional additional ship information
  ///
  /// Returns a [pw.Document] ready for saving or sharing.
  static Future<pw.Document> generateRatingPdf({
    required String shipName,
    String? shipImo,
    required String evaluatorName,
    required DateTime evaluationDate,
    required String cabinType,
    required DateTime disembarkationDate,
    required Map<String, Map<String, dynamic>> ratings,
    String? generalObservation,
    Map<String, dynamic>? shipInfo,
  }) async {
    final pdf = pw.Document();
    final averageRating = _calculateAverageRating(ratings);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(shipName, shipImo),
          pw.SizedBox(height: 20),
          _buildInfoSection(
            evaluatorName: evaluatorName,
            evaluationDate: evaluationDate,
            cabinType: cabinType,
            disembarkationDate: disembarkationDate,
            averageRating: averageRating,
          ),
          pw.SizedBox(height: 20),
          if (shipInfo != null) ...[
            _buildShipInfoSection(shipInfo),
            pw.SizedBox(height: 20),
          ],
          _buildRatingsSection(ratings),
          pw.SizedBox(height: 20),
          if (generalObservation?.isNotEmpty == true) ...[
            _buildGeneralObservationSection(generalObservation!),
            pw.SizedBox(height: 20),
          ],
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    return pdf;
  }

  /// Saves and shares the PDF document.
  ///
  /// Behavior by platform:
  /// - Mobile: Opens native share dialog (WhatsApp, Email, etc.)
  /// - Web: Downloads file directly to browser
  ///
  /// Parameters:
  /// - [pdf]: Generated PDF document
  /// - [fileName]: Filename without extension
  static Future<void> saveAndSharePdf(pw.Document pdf, String fileName) async {
    final bytes = await pdf.save();

    if (kIsWeb) {
      await _downloadPdfWeb(bytes, fileName);
    } else {
      await _sharePdfMobile(bytes, fileName);
    }
  }

  /// Opens PDF preview before saving.
  ///
  /// Behavior by platform:
  /// - Mobile: Opens native preview with print/share options
  /// - Web: Opens PDF in new browser tab
  static Future<void> previewPdf(pw.Document pdf) async {
    final bytes = await pdf.save();

    if (kIsWeb) {
      _previewPdfWeb(bytes);
    } else {
      await _previewPdfMobile(bytes);
    }
  }

  // ===========================================================================
  // PRIVATE METHODS - PDF SECTIONS
  // ===========================================================================

  /// Builds the header section with branding and ship info.
  static pw.Widget _buildHeader(String shipName, String? shipImo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(_primaryColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ShipRate',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Relatório de Avaliação de Navio',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 14),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.white),
          pw.SizedBox(height: 8),
          pw.Text(
            shipName,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (shipImo?.isNotEmpty == true) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'IMO: $shipImo',
              style: pw.TextStyle(
                color: PdfColor.fromHex(_lightPrimaryColor),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the evaluation info section.
  static pw.Widget _buildInfoSection({
    required String evaluatorName,
    required DateTime evaluationDate,
    required String cabinType,
    required DateTime disembarkationDate,
    required double averageRating,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex(_borderColor)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informações da Avaliação',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(_primaryColor),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildInfoItem('Prático Avaliador', evaluatorName),
              ),
              pw.Expanded(
                child: _buildInfoItem(
                  'Data da Avaliação',
                  dateFormat.format(evaluationDate),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildInfoItem('Tipo de Cabine', cabinType)),
              pw.Expanded(
                child: _buildInfoItem(
                  'Data de Desembarque',
                  dateFormat.format(disembarkationDate),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildInfoItem('Nota Média Geral', averageRating.toStringAsFixed(1)),
        ],
      ),
    );
  }

  /// Builds a single info item with label and value.
  static pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Builds the ship information section.
  static pw.Widget _buildShipInfoSection(Map<String, dynamic> shipInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(_backgroundGray),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informações do Navio',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(_primaryColor),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Nacionalidade da Tripulação: ${shipInfo['nacionalidadeTripulacao'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Quantidade de Cabines: ${shipInfo['numeroCabines'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'Frigobar: ${_boolToYesNo(shipInfo['frigobar'])}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(width: 20),
              pw.Text(
                'Pia: ${_boolToYesNo(shipInfo['pia'])}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the ratings section with all criteria.
  static pw.Widget _buildRatingsSection(
    Map<String, Map<String, dynamic>> ratings,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Avaliações por Critério',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex(_primaryColor),
          ),
        ),
        pw.SizedBox(height: 12),
        ...ratings.entries.map(_buildRatingCard),
      ],
    );
  }

  /// Builds a single rating card.
  static pw.Widget _buildRatingCard(
    MapEntry<String, Map<String, dynamic>> entry,
  ) {
    final criteriaName = entry.key;
    final score = entry.value['nota'] as double;
    final observation = entry.value['observacao'] as String;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex(_borderColor)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  criteriaName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _getRatingColor(score),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  score.toStringAsFixed(1),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          if (observation.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              observation,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the general observation section.
  static pw.Widget _buildGeneralObservationSection(String observation) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(_warningBackground),
        border: pw.Border.all(color: PdfColor.fromHex(_warningBorder)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Observação Geral',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex(_warningText),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(observation, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  /// Builds the footer with generation timestamp.
  static pw.Widget _buildFooter() {
    final timestamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado por ShipRate',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Data: $timestamp',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIVATE METHODS - PLATFORM SPECIFIC
  // ===========================================================================

  /// Downloads PDF in web browser.
  static Future<void> _downloadPdfWeb(List<int> bytes, String fileName) async {
    try {
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '$fileName.pdf';

      html.document.body?.children.add(anchor);
      await Future.delayed(const Duration(milliseconds: 100));

      anchor.click();

      await Future.delayed(const Duration(milliseconds: 100));
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Failed to download PDF in browser: $e');
    }
  }

  /// Shares PDF on mobile devices.
  static Future<void> _sharePdfMobile(List<int> bytes, String fileName) async {
    try {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: '$fileName.pdf',
      );
    } catch (e) {
      throw Exception('Failed to share PDF on device: $e');
    }
  }

  /// Previews PDF in web browser.
  static void _previewPdfWeb(List<int> bytes) {
    try {
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');

      Future.delayed(const Duration(seconds: 1), () {
        html.Url.revokeObjectUrl(url);
      });
    } catch (e) {
      throw Exception('Failed to preview PDF in browser: $e');
    }
  }

  /// Previews PDF on mobile devices.
  static Future<void> _previewPdfMobile(List<int> bytes) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => Uint8List.fromList(bytes),
      );
    } catch (e) {
      throw Exception('Failed to preview PDF on device: $e');
    }
  }

  // ===========================================================================
  // PRIVATE METHODS - HELPERS
  // ===========================================================================

  /// Calculates average rating from all criteria.
  static double _calculateAverageRating(
    Map<String, Map<String, dynamic>> ratings,
  ) {
    if (ratings.isEmpty) return 0.0;

    double total = 0;
    for (final entry in ratings.values) {
      total += entry['nota'] as double;
    }

    return total / ratings.length;
  }

  /// Returns color based on rating score (traffic light system).
  static PdfColor _getRatingColor(double rating) {
    if (rating >= _excellentRating) return PdfColor.fromHex(_colorExcellent);
    if (rating >= _goodRating) return PdfColor.fromHex(_colorGood);
    if (rating >= _averageRating) return PdfColor.fromHex(_colorAverage);
    if (rating >= _belowAverageRating) {
      return PdfColor.fromHex(_colorBelowAverage);
    }
    return PdfColor.fromHex(_colorPoor);
  }

  /// Converts boolean to "Sim"/"Não" string.
  static String _boolToYesNo(dynamic value) {
    return value == true ? 'Sim' : 'Não';
  }
}