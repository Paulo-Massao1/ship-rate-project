import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/pdf_labels_factory.dart';

/// Screen for viewing detailed information of a ship rating.
///
/// Features:
/// - Displays all rating data (read-only)
/// - Shows ship information (name, IMO)
/// - Displays dates (evaluation and disembarkation)
/// - Lists cabin information
/// - Shows ratings by category with scores
/// - Displays general observations
/// - Exports rating to PDF (mobile + web)
///
/// Characteristics:
/// - READ-ONLY page (no edits allowed)
/// - Fetches ship data from parent document
/// - Groups criteria by category (Cabin, Bridge, Other)
/// - Clean, professional layout with Cards
/// - PDF export button in AppBar and FAB
class RatingDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot rating;

  const RatingDetailPage({super.key, required this.rating});

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _primaryColor = Colors.indigo;

  /// Criteria organized by section for display order.
  static const List<String> _cabinCriteria = [
    'Temperatura da Cabine',
    'Limpeza da Cabine',
  ];

  static const List<String> _bridgeCriteria = [
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
  ];

  static const List<String> _otherCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Maps Firestore criteria keys to translated display names.
  String _criteriaLabel(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Temperatura da Cabine': return l10n.criteriaCabinTemp;
      case 'Limpeza da Cabine': return l10n.criteriaCabinCleanliness;
      case 'Passadiço – Equipamentos': return l10n.criteriaBridgeEquipment;
      case 'Passadiço – Temperatura': return l10n.criteriaBridgeTemp;
      case 'Dispositivo de Embarque/Desembarque': return l10n.criteriaDevice;
      case 'Comida': return l10n.criteriaFood;
      case 'Relacionamento com comandante/tripulação': return l10n.criteriaRelationship;
      default: return key;
    }
  }

  /// Converts boolean to translated "Yes"/"No".
  String _boolToYesNo(BuildContext context, bool? value) {
    final l10n = AppLocalizations.of(context)!;
    return value == true ? l10n.yes : l10n.no;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = rating.data() as Map<String, dynamic>;
    final shipRef = rating.reference.parent.parent!;

    return FutureBuilder<DocumentSnapshot>(
      future: shipRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text(l10n.errorLoadingShipData)),
          );
        }

        final shipData = snapshot.data?.data() as Map<String, dynamic>?;
        final shipName = shipData?['nome'] ?? l10n.defaultShipName;
        final shipImo = shipData?['imo'];

        return Scaffold(
          appBar: _buildAppBar(context, shipName, shipImo),
          body: _buildBody(context, data, shipName, shipImo),
          floatingActionButton: _buildFab(context, shipName, shipImo),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String shipName,
    String? shipImo,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      title: Text(l10n.ratingDetailTitle),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: l10n.exportPdf,
          onPressed: () => _exportToPdf(context, shipName, shipImo),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Map<String, dynamic> data,
    String shipName,
    String? shipImo,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final callSign = data['nomeGuerra'] ?? l10n.pilot;
    final ratingDate = data['data'] as Timestamp?;
    final disembarkationDate = data['dataDesembarque'] as Timestamp?;
    final cabinType = data['tipoCabine'] ?? '';
    final generalObservations = (data['observacaoGeral'] ?? '').toString();
    final ratingItems = Map<String, dynamic>.from(data['itens'] ?? {});
    final shipInfo = Map<String, dynamic>.from(data['infoNavio'] ?? {});
    final bridgeInfo = Map<String, dynamic>.from(data['infoPassadico'] ?? {});

    // Merge amenities: use shipInfo first, fallback to bridgeInfo (legacy data)
    final amenities = _mergeAmenities(shipInfo, bridgeInfo);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          context,
          shipName: shipName,
          shipImo: shipImo,
          ratingDate: ratingDate,
          disembarkationDate: disembarkationDate,
          cabinType: cabinType,
          callSign: callSign,
        ),
        if (_hasShipInfo(shipInfo, amenities)) ...[
          const SizedBox(height: 16),
          _buildShipInfoCard(context, shipInfo, amenities),
        ],
        if (generalObservations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGeneralObservationsCard(context, generalObservations),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle(context, l10n.cabinSection),
        ..._buildRatingCards(context, ratingItems, _cabinCriteria),
        _buildSectionTitle(context, l10n.bridgeSection),
        ..._buildRatingCards(context, ratingItems, _bridgeCriteria),
        _buildSectionTitle(context, l10n.otherSection),
        ..._buildRatingCards(context, ratingItems, _otherCriteria),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFab(BuildContext context, String shipName, String? shipImo) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.extended(
      onPressed: () => _exportToPdf(context, shipName, shipImo),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.picture_as_pdf),
      label: Text(l10n.exportPdf),
    );
  }

  // ===========================================================================
  // BUILD - CARDS
  // ===========================================================================

  Widget _buildHeaderCard(
    BuildContext context, {
    required String shipName,
    String? shipImo,
    Timestamp? ratingDate,
    Timestamp? disembarkationDate,
    required String cabinType,
    required String callSign,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shipName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (shipImo?.isNotEmpty == true) Text(l10n.imoValue(shipImo!)),
            if (ratingDate != null)
              Text(
                l10n.ratedOn(_formatTimestamp(ratingDate)),
                style: const TextStyle(color: Colors.black54),
              ),
            if (disembarkationDate != null)
              Text(
                l10n.disembarkationDateValue(_formatTimestamp(disembarkationDate)),
                style: const TextStyle(color: Colors.black54),
              ),
            if (cabinType.isNotEmpty) Text(l10n.cabinTypeValue(cabinType)),
            const SizedBox(height: 6),
            Text(
              l10n.pilotCallSign(callSign),
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipInfoCard(
    BuildContext context,
    Map<String, dynamic> shipInfo,
    Map<String, bool?> amenities,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shipInfo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (shipInfo['nacionalidadeTripulacao'] != null)
              _buildInfoRow(l10n.crew, shipInfo['nacionalidadeTripulacao']),
            if (shipInfo['numeroCabines'] != null &&
                shipInfo['numeroCabines'] > 0)
              _buildInfoRow(l10n.cabins, shipInfo['numeroCabines'].toString()),
            if (amenities['frigobar'] != null)
              _buildInfoRow(l10n.minibar, _boolToYesNo(context, amenities['frigobar'])),
            if (amenities['pia'] != null)
              _buildInfoRow(l10n.sink, _boolToYesNo(context, amenities['pia'])),
            if (amenities['microondas'] != null)
              _buildInfoRow(l10n.microwave, _boolToYesNo(context, amenities['microondas'])),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralObservationsCard(BuildContext context, String observations) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.generalObservations,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(observations),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
    );
  }

  List<Widget> _buildRatingCards(
    BuildContext context,
    Map<String, dynamic> items,
    List<String> criteriaOrder,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return criteriaOrder.where(items.containsKey).map((name) {
      final item = Map<String, dynamic>.from(items[name]);
      final score = item['nota'];
      final observation = (item['observacao'] ?? '').toString();

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _criteriaLabel(context, name),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.scoreLabel(score?.toString() ?? '-'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              if (observation.isNotEmpty) ...[
                const Divider(height: 24),
                Text(observation),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ===========================================================================
  // PDF EXPORT
  // ===========================================================================

  /// Exports the rating to PDF.
  ///
  /// Works on mobile (share) and web (automatic download).
  Future<void> _exportToPdf(
    BuildContext context,
    String shipName,
    String? shipImo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _showLoadingDialog(context);

      final data = rating.data() as Map<String, dynamic>;
      final pdf = await _generatePdf(data, shipName, shipImo, l10n);

      if (context.mounted) {
        Navigator.pop(context);
      }

      final fileName = _generateFileName(shipName);
      await PdfService.saveAndSharePdf(pdf, fileName);

      if (context.mounted) {
        _showSuccessSnackBar(context, l10n.pdfGeneratedSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(context, l10n.errorGeneratingPdf(e.toString()));
      }
    }
  }

  Future<dynamic> _generatePdf(
    Map<String, dynamic> data,
    String shipName,
    String? shipImo,
    AppLocalizations l10n,
  ) async {
    final evaluatorName = data['nomeGuerra'] ?? l10n.anonymous;
    final evaluationDate = _resolveEvaluationDate(data);
    final cabinType = data['tipoCabine'] ?? l10n.notAvailable;
    final disembarkationDate = (data['dataDesembarque'] as Timestamp).toDate();
    final ratings = _extractRatings(data);
    final generalObservation = data['observacaoGeral'];
    final shipInfo = data['infoNavio'] as Map<String, dynamic>?;

    return PdfService.generateRatingPdf(
      shipName: shipName,
      shipImo: shipImo,
      evaluatorName: evaluatorName,
      evaluationDate: evaluationDate,
      cabinType: cabinType,
      disembarkationDate: disembarkationDate,
      ratings: ratings,
      generalObservation: generalObservation,
      shipInfo: shipInfo,
      labels: buildPdfLabels(l10n),
    );
  }

  DateTime _resolveEvaluationDate(Map<String, dynamic> data) {
    return (data['createdAt'] as Timestamp?)?.toDate() ??
        (data['data'] as Timestamp?)?.toDate() ??
        DateTime.now();
  }

  Map<String, Map<String, dynamic>> _extractRatings(Map<String, dynamic> data) {
    final itensData = data['itens'] as Map<String, dynamic>? ?? {};
    final ratings = <String, Map<String, dynamic>>{};

    itensData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        ratings[key] = {
          'nota': (value['nota'] as num?)?.toDouble() ?? 0.0,
          'observacao': value['observacao'] ?? '',
        };
      }
    });

    return ratings;
  }

  String _generateFileName(String shipName) {
    final firstName = shipName.split(' ').first.replaceAll(RegExp(r'[^\w]'), '');
    return 'ShipRate_$firstName';
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Formats Timestamp for display (dd/MM/yyyy).
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Merges amenities from shipInfo and bridgeInfo (legacy support).
  Map<String, bool?> _mergeAmenities(
    Map<String, dynamic> shipInfo,
    Map<String, dynamic> bridgeInfo,
  ) {
    return {
      'frigobar': shipInfo['frigobar'] ?? bridgeInfo['frigobar'],
      'pia': shipInfo['pia'] ?? bridgeInfo['pia'],
      'microondas': shipInfo['microondas'] ?? bridgeInfo['microondas'],
    };
  }

  /// Checks if there's any ship info to display.
  bool _hasShipInfo(
    Map<String, dynamic> shipInfo,
    Map<String, bool?> amenities,
  ) {
    return shipInfo.isNotEmpty ||
        amenities['frigobar'] != null ||
        amenities['pia'] != null ||
        amenities['microondas'] != null;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
