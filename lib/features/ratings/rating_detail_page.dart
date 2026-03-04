import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
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

  // Deep Ocean theme colors
  static const _bgTop = Color(0xFF0A1628);
  static const _bgBottom = Color(0xFF0D2137);
  static const _accentBlue = Color(0xFF64B5F6);
  static const _cardBg = Color(0x0DFFFFFF);
  static const _cardBorder = Color(0x1A64B5F6);
  static const _secondaryText = Color(0x66FFFFFF);
  static const _bodyText = Color(0xD9FFFFFF);
  static const _fabGradientStart = Color(0xFF1565C0);
  static const _fabGradientEnd = Color(0xFF1976D2);

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

  /// Maps a nationality key to its localized label.
  String _nationalityLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Filipino': return l10n.nationalityFilipino;
      case 'Russian': return l10n.nationalityRussian;
      case 'Ukrainian': return l10n.nationalityUkrainian;
      case 'Indian': return l10n.nationalityIndian;
      case 'Chinese': return l10n.nationalityChinese;
      case 'Brazilian': return l10n.nationalityBrazilian;
      default: return key;
    }
  }

  /// Formats nationality value for display with i18n (backward compatible).
  String _formatNationality(BuildContext context, dynamic value) {
    final l10n = AppLocalizations.of(context)!;
    if (value is List) {
      return value.map((e) => _nationalityLabel(l10n, e.toString())).join(', ');
    }
    return _nationalityLabel(l10n, value.toString());
  }

  /// Converts boolean to translated "Yes"/"No".
  String _boolToYesNo(BuildContext context, bool? value) {
    final l10n = AppLocalizations.of(context)!;
    return value == true ? l10n.yes : l10n.no;
  }

  /// Converts cabin count value to localized display label.
  String? _formatCabinCount(dynamic value, AppLocalizations l10n) {
    if (value == null) return null;
    String key;
    if (value is int) {
      if (value <= 0) return null;
      key = value >= 3 ? '3+' : value.toString();
    } else {
      key = value.toString();
    }
    switch (key) {
      case '1': return l10n.cabinCountOne;
      case '2': return l10n.cabinCountTwo;
      case '3+': return l10n.cabinCountMoreThanTwo;
      default: return null;
    }
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
          return Scaffold(
            backgroundColor: _bgTop,
            body: const Center(child: CircularProgressIndicator(color: _accentBlue)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _bgTop,
            body: Center(child: Text(l10n.errorLoadingShipData, style: const TextStyle(color: Colors.white))),
          );
        }

        final shipData = snapshot.data?.data() as Map<String, dynamic>?;
        final shipName = (shipData?['nome'] ?? l10n.defaultShipName).toString().toUpperCase();
        final shipImo = shipData?['imo'];

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context, shipName, shipImo),
            body: _buildBody(context, data, shipName, shipImo),
            floatingActionButton: _buildFab(context, shipName, shipImo),
          ),
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
      backgroundColor: _bgTop,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
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
    final cabinDeck = data['deckCabine'] as String?;
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
          cabinDeck: cabinDeck,
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [_fabGradientStart, _fabGradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x661565C0),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _exportToPdf(context, shipName, shipImo),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.picture_as_pdf),
        label: Text(l10n.exportPdf),
      ),
    );
  }

  // ===========================================================================
  // BUILD - CARDS
  // ===========================================================================

  /// Returns localized label for a deck key.
  String _deckLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'bridge': return l10n.deckBridge;
      case '1_below': return l10n.deck1Below;
      case '2_below': return l10n.deck2Below;
      case '3_below': return l10n.deck3Below;
      case '4+_below': return l10n.deck4PlusBelow;
      default: return l10n.deckLabel(key);
    }
  }

  /// Reusable Deep Ocean themed card wrapper.
  Widget _themedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required String shipName,
    String? shipImo,
    Timestamp? ratingDate,
    Timestamp? disembarkationDate,
    required String cabinType,
    String? cabinDeck,
    required String callSign,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return _themedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (shipImo?.isNotEmpty == true)
            Text(l10n.imoValue(shipImo!), style: const TextStyle(color: _secondaryText)),
          if (ratingDate != null)
            Text(
              l10n.ratedOn(_formatTimestamp(ratingDate)),
              style: const TextStyle(color: _secondaryText),
            ),
          if (disembarkationDate != null)
            Text(
              l10n.disembarkationDateValue(_formatTimestamp(disembarkationDate)),
              style: const TextStyle(color: _secondaryText),
            ),
          if (cabinType.isNotEmpty)
            Text(l10n.cabinTypeValue(cabinType), style: const TextStyle(color: _secondaryText)),
          if (cabinDeck != null)
            Text(
              l10n.cabinDeckValue(_deckLabel(l10n, cabinDeck)),
              style: const TextStyle(color: _secondaryText),
            ),
          const SizedBox(height: 6),
          Text(
            l10n.pilotCallSign(callSign),
            style: const TextStyle(fontSize: 13, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildShipInfoCard(
    BuildContext context,
    Map<String, dynamic> shipInfo,
    Map<String, bool?> amenities,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return _themedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shipInfo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 12),
          if (shipInfo['nacionalidadeTripulacao'] != null)
            _buildInfoRow(l10n.crew, _formatNationality(context, shipInfo['nacionalidadeTripulacao'])),
          if (_formatCabinCount(shipInfo['numeroCabines'], l10n) != null)
            _buildInfoRow(l10n.cabins, _formatCabinCount(shipInfo['numeroCabines'], l10n)!),
          if (amenities['frigobar'] != null)
            _buildInfoRow(l10n.minibar, _boolToYesNo(context, amenities['frigobar'])),
          if (amenities['pia'] != null)
            _buildInfoRow(l10n.sink, _boolToYesNo(context, amenities['pia'])),
          if (amenities['microondas'] != null)
            _buildInfoRow(l10n.microwave, _boolToYesNo(context, amenities['microondas'])),
        ],
      ),
    );
  }

  Widget _buildGeneralObservationsCard(BuildContext context, String observations) {
    final l10n = AppLocalizations.of(context)!;
    return _themedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.generalObservations,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(observations, style: const TextStyle(color: _bodyText)),
        ],
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
          color: _accentBlue,
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

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(color: _cardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _criteriaLabel(context, name),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.scoreLabel(score?.toString() ?? '-'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _accentBlue,
              ),
            ),
            if (observation.isNotEmpty) ...[
              const Divider(height: 24, color: Color(0x1AFFFFFF)),
              Text(observation, style: const TextStyle(color: _bodyText)),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          Expanded(child: Text(value, style: const TextStyle(color: _bodyText))),
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
    final cabinDeckKey = data['deckCabine'] as String?;
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
      cabinDeck: cabinDeckKey != null ? _deckLabel(l10n, cabinDeckKey) : null,
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
        child: CircularProgressIndicator(color: _accentBlue),
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
