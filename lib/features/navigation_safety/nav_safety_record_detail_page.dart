import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

class NavSafetyRecordDetailPage extends StatelessWidget {
  const NavSafetyRecordDetailPage({
    super.key,
    required this.locationName,
    required this.record,
  });

  final String locationName;
  final Map<String, dynamic> record;

  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _cardBg = Color(0x0DFFFFFF);
  static const _cardBorder = Color(0x1A64B5F6);
  static const _teal = Color(0xFF26A69A);
  static const _tealBg = Color(0x1426A69A);
  static const _tealBorder = Color(0x3326A69A);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xD9FFFFFF);
  static const _textMuted = Color(0x66FFFFFF);
  static const _blueAccent = Color(0xFF64B5F6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shipName = (record['nomeNavio'] ?? '').toString();
    final pilotName = (record['nomeGuerra'] ?? '').toString();
    final date = _formatDate(record['data']);
    final direction = _directionLabel(record['direcao']?.toString(), l10n);
    final depth = _formatMeters(record['profundidadeTotal']);
    final maxDraft = _formatMeters(record['caladoMax']);
    final ukc = _formatMeters(record['ukc']);
    final speed = _formatSpeed(record['velocidade']);
    final observations = (record['observacoes'] ?? '').toString().trim();
    final technicalRows = _buildTechnicalRows(l10n);
    final positionRows = _buildPositionRows();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.recordDetails,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        elevation: 4,
        shadowColor: Colors.black54,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_bgDark, Color(0xFF1A3A5C), _bgMid],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildCard(
              title: l10n.passageInfo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationName,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (shipName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Navio: $shipName',
                      style: const TextStyle(
                        color: _blueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Data: $date',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  if (pilotName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${l10n.pilot}: $pilotName',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(direction.icon, color: _teal, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        direction.label,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: l10n.totalDepthLabel,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1426A69A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x3326A69A)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.totalDepthLabel,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          depth,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMetricColumn(l10n.maxDraft, maxDraft),
                      _buildMetricColumn(l10n.ukc, ukc),
                      if (speed != null)
                        _buildMetricColumn(l10n.speedOptional, speed),
                    ],
                  ),
                ],
              ),
            ),
            if (technicalRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.technicalData,
                child: Column(children: technicalRows),
              ),
            ],
            if (positionRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.position,
                child: Column(children: positionRows),
              ),
            ],
            if (observations.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: l10n.observations,
                child: Text(
                  observations,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (record['imageUrls'] is List &&
                (record['imageUrls'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPhotosCard(context, l10n),
            ],
            ],
          ),
        ),
          ),
        ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTechnicalRows(AppLocalizations l10n) {
    final rows = <Widget>[];

    if (record['squatConsiderado'] != null) {
      rows.add(
        _buildInfoRow(
          l10n.squatConsidered,
          record['squatConsiderado'] == true ? l10n.yes : l10n.no,
        ),
      );
    }

    if (record['posicaoSonda'] != null) {
      rows.add(
        _buildInfoRow(
          l10n.sonarPosition,
          record['posicaoSonda'] == 'proa' ? l10n.bow : l10n.stern,
        ),
      );
    }

    if (record['ponto'] != null) {
      rows.add(_buildInfoRow(l10n.anchoragePoint, record['ponto'].toString()));
    }

    return _withSpacing(rows);
  }

  List<Widget> _buildPositionRows() {
    final latitude = _formatCoordinate(record['latitude'], isLatitude: true);
    final longitude = _formatCoordinate(record['longitude'], isLatitude: false);
    final rows = <Widget>[];

    if (latitude != null) {
      rows.add(_buildInfoRow('LAT', latitude));
    }
    if (longitude != null) {
      rows.add(_buildInfoRow('LONG', longitude));
    }

    return _withSpacing(rows);
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 10));
      spaced.add(children[i]);
    }
    return spaced;
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _tealBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tealBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic data) {
    if (data is Timestamp) {
      final date = data.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return '—';
  }

  String _formatMeters(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '—';
    return text.endsWith('m') ? text : '${text}m';
  }

  String? _formatSpeed(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  String? _formatCoordinate(dynamic raw, {required bool isLatitude}) {
    if (raw is! Map) return null;

    final degrees = raw['graus']?.toString();
    final minutes = raw['minutos']?.toString();
    final seconds = raw['segundos']?.toString();
    final hemisphere = raw['hemisferio']?.toString();

    if (degrees == null ||
        minutes == null ||
        seconds == null ||
        hemisphere == null ||
        degrees.isEmpty ||
        minutes.isEmpty ||
        seconds.isEmpty ||
        hemisphere.isEmpty) {
      return null;
    }

    final degreeWidth = isLatitude ? 2 : 3;
    final secondValue = double.tryParse(seconds);
    final formattedSeconds = secondValue != null
        ? secondValue.toStringAsFixed(2).padLeft(5, '0')
        : seconds;

    return '${degrees.padLeft(degreeWidth, '0')}\u00B0 ${minutes.padLeft(2, '0')}\' $formattedSeconds" $hemisphere';
  }

  Widget _buildPhotosCard(BuildContext context, AppLocalizations l10n) {
    final imageUrls = List<String>.from(record['imageUrls'] as List);

    return _buildCard(
      title: l10n.photos,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: imageUrls.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(right: entry.key < imageUrls.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, entry.value),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    entry.value,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DirectionData _directionLabel(String? value, AppLocalizations l10n) {
    switch (value?.toLowerCase()) {
      case 'subindo':
        return _DirectionData(Icons.arrow_upward, l10n.goingUp);
      case 'baixando':
        return _DirectionData(Icons.arrow_downward, l10n.goingDown);
      default:
        return const _DirectionData(Icons.swap_vert, '—');
    }
  }
}

class _DirectionData {
  const _DirectionData(this.icon, this.label);

  final IconData icon;
  final String label;
}

