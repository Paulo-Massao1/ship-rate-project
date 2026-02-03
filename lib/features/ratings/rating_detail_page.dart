import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/services/pdf_service.dart';

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
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
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
          return const Scaffold(
            body: Center(child: Text('Erro ao carregar dados do navio')),
          );
        }

        final shipData = snapshot.data?.data() as Map<String, dynamic>?;
        final shipName = shipData?['nome'] ?? 'Navio';
        final shipImo = shipData?['imo'];

        return Scaffold(
          appBar: _buildAppBar(context, shipName, shipImo),
          body: _buildBody(data, shipName, shipImo),
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
    return AppBar(
      title: const Text('Detalhes da Avaliação'),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'Exportar PDF',
          onPressed: () => _exportToPdf(context, shipName, shipImo),
        ),
      ],
    );
  }

  Widget _buildBody(
    Map<String, dynamic> data,
    String shipName,
    String? shipImo,
  ) {
    final callSign = data['nomeGuerra'] ?? 'Prático';
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
          shipName: shipName,
          shipImo: shipImo,
          ratingDate: ratingDate,
          disembarkationDate: disembarkationDate,
          cabinType: cabinType,
          callSign: callSign,
        ),
        if (_hasShipInfo(shipInfo, amenities)) ...[
          const SizedBox(height: 16),
          _buildShipInfoCard(shipInfo, amenities),
        ],
        if (generalObservations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGeneralObservationsCard(generalObservations),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle('Cabine'),
        ..._buildRatingCards(ratingItems, _cabinCriteria),
        _buildSectionTitle('Passadiço'),
        ..._buildRatingCards(ratingItems, _bridgeCriteria),
        _buildSectionTitle('Outros'),
        ..._buildRatingCards(ratingItems, _otherCriteria),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFab(BuildContext context, String shipName, String? shipImo) {
    return FloatingActionButton.extended(
      onPressed: () => _exportToPdf(context, shipName, shipImo),
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Exportar PDF'),
    );
  }

  // ===========================================================================
  // BUILD - CARDS
  // ===========================================================================

  Widget _buildHeaderCard({
    required String shipName,
    String? shipImo,
    Timestamp? ratingDate,
    Timestamp? disembarkationDate,
    required String cabinType,
    required String callSign,
  }) {
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
            if (shipImo?.isNotEmpty == true) Text('IMO: $shipImo'),
            if (ratingDate != null)
              Text(
                'Avaliado em: ${_formatTimestamp(ratingDate)}',
                style: const TextStyle(color: Colors.black54),
              ),
            if (disembarkationDate != null)
              Text(
                'Data de desembarque: ${_formatTimestamp(disembarkationDate)}',
                style: const TextStyle(color: Colors.black54),
              ),
            if (cabinType.isNotEmpty) Text('Tipo da cabine: $cabinType'),
            const SizedBox(height: 6),
            Text(
              'Prático: $callSign',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipInfoCard(
    Map<String, dynamic> shipInfo,
    Map<String, bool?> amenities,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações do Navio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (shipInfo['nacionalidadeTripulacao'] != null)
              _buildInfoRow('Tripulação', shipInfo['nacionalidadeTripulacao']),
            if (shipInfo['numeroCabines'] != null &&
                shipInfo['numeroCabines'] > 0)
              _buildInfoRow('Cabines', shipInfo['numeroCabines'].toString()),
            if (amenities['frigobar'] != null)
              _buildInfoRow('Frigobar', _boolToYesNo(amenities['frigobar'])),
            if (amenities['pia'] != null)
              _buildInfoRow('Pia', _boolToYesNo(amenities['pia'])),
            if (amenities['microondas'] != null)
              _buildInfoRow('Micro-ondas', _boolToYesNo(amenities['microondas'])),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralObservationsCard(String observations) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Observações Gerais',
              style: TextStyle(
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

  Widget _buildSectionTitle(String title) {
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
    Map<String, dynamic> items,
    List<String> criteriaOrder,
  ) {
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
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                'Nota: ${score ?? '-'}',
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
    try {
      _showLoadingDialog(context);

      final data = rating.data() as Map<String, dynamic>;
      final pdf = await _generatePdf(data, shipName, shipImo);

      if (context.mounted) {
        Navigator.pop(context);
      }

      final fileName = _generateFileName(shipName);
      await PdfService.saveAndSharePdf(pdf, fileName);

      if (context.mounted) {
        _showSuccessSnackBar(context, 'PDF gerado com sucesso!');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(context, 'Erro ao gerar PDF: $e');
      }
    }
  }

  Future<dynamic> _generatePdf(
    Map<String, dynamic> data,
    String shipName,
    String? shipImo,
  ) async {
    final evaluatorName = data['nomeGuerra'] ?? 'Anônimo';
    final evaluationDate = _resolveEvaluationDate(data);
    final cabinType = data['tipoCabine'] ?? 'N/A';
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

  /// Converts boolean to "Sim"/"Não".
  String _boolToYesNo(bool? value) => value == true ? 'Sim' : 'Não';

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