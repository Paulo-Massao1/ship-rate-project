import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../data/services/image_upload_service.dart';
import '../../data/services/url_launcher_service.dart';

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
  static const _thumbnailSize = 80.0;

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
    final depthReference = _formatDepthReference(
      record['depthReference'],
      l10n,
    );
    final speed = _formatSpeed(record['velocidade']);
    final observations = (record['observacoes'] ?? '').toString().trim();
    final technicalRows = _buildTechnicalRows(l10n);

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                      const SizedBox(height: 6),
                      // Ship and date stay on the same line when they fit, and the
                      // date drops to the next line when the ship name is long.
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (shipName.isNotEmpty)
                            _buildPassageField(
                              'Navio',
                              shipName,
                              valueColor: _blueAccent,
                            ),
                          _buildPassageField('Data', date),
                        ],
                      ),
                      if (pilotName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildPassageField(l10n.pilot, pilotName),
                      ],
                      const SizedBox(height: 6),
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
                const SizedBox(height: 8),
                _buildCard(
                  title: l10n.totalDepthLabel,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0x1426A69A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x3326A69A)),
                        ),
                        child: Text(
                          depth,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (depthReference.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          depthReference,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  _buildCard(
                    title: l10n.technicalData,
                    padding: const EdgeInsets.all(8),
                    child: Column(children: technicalRows),
                  ),
                ],
                if (observations.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  _buildPhotosCard(context, l10n),
                ],
                if (record['fileAttachments'] is List &&
                    (record['fileAttachments'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildFilesCard(context, l10n),
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
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
    double titleSpacing = 8,
  }) {
    return Container(
      padding: padding,
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
          SizedBox(height: titleSpacing),
          child,
        ],
      ),
    );
  }

  /// Compact label/value line used by the passage info card.
  Widget _buildPassageField(String label, String value, {Color? valueColor}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: valueColor ?? _textSecondary, fontSize: 14),
          ),
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
            style: const TextStyle(color: _textMuted, fontSize: 10),
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

    // Sonar position and squat share a single row to save vertical space.
    final compactTiles = <Widget>[];

    if (record['posicaoSonda'] != null) {
      compactTiles.add(
        _buildCompactTile(
          l10n.sonarPosition,
          record['posicaoSonda'] == 'proa' ? l10n.bow : l10n.stern,
        ),
      );
    }

    if (record['squat'] != null) {
      compactTiles.add(
        _buildCompactTile(l10n.squatInput, _formatMeters(record['squat'])),
      );
    } else if (record['squatConsiderado'] != null) {
      compactTiles.add(
        _buildCompactTile(
          l10n.squatConsidered,
          record['squatConsiderado'] == true ? l10n.yes : l10n.no,
        ),
      );
    }

    if (compactTiles.isNotEmpty) {
      rows.add(_buildTileRow(compactTiles));
    }

    // Coordinates live in this card too, so they cost no extra card header.
    rows.addAll(_buildPositionRows());

    if (record['ponto'] != null) {
      rows.add(_buildInfoRow(l10n.anchoragePoint, record['ponto'].toString()));
    }

    return _withSpacing(rows);
  }

  String _formatDepthReference(dynamic value, AppLocalizations l10n) {
    if (value is! Map) return '';

    final name = (value['name'] ?? '').toString().trim();
    final code = (value['code'] ?? '').toString().trim();
    if (name.isEmpty) return '';

    final displayName = code.isEmpty ? name : '$name ($code)';
    final rulerValue = value['value'];
    if (rulerValue is num) {
      return '$displayName · ${_formatMeters(rulerValue)}';
    }

    final tideEvents = <String>[];
    final previousRaw = value['previousTide'] ?? value['previousLowTide'];
    final nextRaw = value['nextTide'] ?? value['nextHighTide'];
    final previous = _formatTideEvent(previousRaw);
    final next = _formatTideEvent(nextRaw);
    if (previous.isNotEmpty) {
      tideEvents.add(
        '${_storedTideEventLabel(previousRaw, l10n, isPrevious: true, legacyIsHighTide: false)}: $previous',
      );
    }
    if (next.isNotEmpty) {
      tideEvents.add(
        '${_storedTideEventLabel(nextRaw, l10n, isPrevious: false, legacyIsHighTide: true)}: $next',
      );
    }

    return tideEvents.isEmpty
        ? displayName
        : '$displayName\n${tideEvents.join(' · ')}';
  }

  String _storedTideEventLabel(
    dynamic value,
    AppLocalizations l10n, {
    required bool isPrevious,
    required bool legacyIsHighTide,
  }) {
    final type = value is Map ? value['type'] : null;
    final isHighTide = switch (type) {
      'preamar' => true,
      'baixamar' => false,
      _ => legacyIsHighTide,
    };

    if (isPrevious) {
      return isHighTide ? l10n.previousHighTide : l10n.previousLowTide;
    }
    return isHighTide ? l10n.nextHighTide : l10n.nextLowTide;
  }

  String _formatTideEvent(dynamic value) {
    if (value is! Map || value['height'] is! num) return '';

    final height = _formatMeters(value['height']);
    final rawDate = value['dateTime'];
    if (rawDate is! Timestamp) return height;

    final date = rawDate.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$height ($day/$month $hour:$minute)';
  }

  List<Widget> _buildPositionRows() {
    final latitude = _formatCoordinate(record['latitude'], isLatitude: true);
    final longitude = _formatCoordinate(record['longitude'], isLatitude: false);

    // LAT and LONG share a single row to save vertical space.
    final tiles = <Widget>[];

    if (latitude != null) {
      tiles.add(_buildCompactTile('LAT', latitude));
    }
    if (longitude != null) {
      tiles.add(_buildCompactTile('LONG', longitude));
    }

    if (tiles.isEmpty) return const [];

    return [_buildTileRow(tiles)];
  }

  /// Lays out compact tiles side by side with equal widths and heights.
  Widget _buildTileRow(List<Widget> tiles) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const SizedBox(height: 4));
      spaced.add(children[i]);
    }
    return spaced;
  }

  Widget _buildCompactTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _tealBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _tealBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              style: const TextStyle(color: _textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 14,
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
    final hemisphere = raw['hemisferio']?.toString();

    if (degrees == null ||
        hemisphere == null ||
        degrees.isEmpty ||
        hemisphere.isEmpty) {
      return null;
    }

    final minutesRaw = raw['minutos'];
    final secondsRaw = raw['segundos'];

    double decimalMin = 0.0;
    if (minutesRaw is num) {
      decimalMin = minutesRaw.toDouble();
    } else if (minutesRaw != null) {
      decimalMin = double.tryParse(minutesRaw.toString()) ?? 0.0;
    }

    // Backward compatibility: convert old seconds to decimal minutes
    if (secondsRaw != null && secondsRaw.toString().isNotEmpty) {
      final sec = double.tryParse(secondsRaw.toString()) ?? 0.0;
      if (sec > 0) {
        decimalMin += sec / 60.0;
      }
    }

    if (decimalMin == 0.0 &&
        (minutesRaw == null || minutesRaw.toString().isEmpty)) {
      return null;
    }

    final degreeWidth = isLatitude ? 2 : 3;
    final formattedMin =
        decimalMin == decimalMin.truncateToDouble()
            ? '${decimalMin.toInt()}'
            : decimalMin.toStringAsFixed(1);

    return '${degrees.padLeft(degreeWidth, '0')}\u00B0 $formattedMin\' $hemisphere';
  }

  Widget _buildPhotosCard(BuildContext context, AppLocalizations l10n) {
    final imageUrls = List<String>.from(record['imageUrls'] as List);

    // Compact square thumbnails keep the card short; tapping one opens the
    // photo full screen.
    return _buildCard(
      title: l10n.photos,
      child: SizedBox(
        height: _thumbnailSize,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final url = imageUrls[index];
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilesCard(BuildContext context, AppLocalizations l10n) {
    final attachments =
        (record['fileAttachments'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => (m['url'] ?? '').toString().trim().isNotEmpty)
            .toList();

    if (attachments.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      title: l10n.files,
      child: Column(
        children:
            attachments.asMap().entries.map((entry) {
              final attachment = entry.value;
              final url = attachment['url'].toString();
              final name = (attachment['name'] ?? '').toString().trim();
              final displayName = name.isNotEmpty ? name : l10n.file;
              final contentType =
                  (attachment['contentType'] ?? '').toString().trim().isNotEmpty
                      ? attachment['contentType'].toString()
                      : ImageUploadService.contentTypeFromFileName(displayName);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < attachments.length - 1 ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: () => UrlLauncherService.openExternalUrl(url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _tealBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _tealBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _fileIconForContentType(contentType),
                          color: _teal,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.open_in_new,
                          color: _blueAccent,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  IconData _fileIconForContentType(String contentType) {
    final normalized = contentType.trim().toLowerCase();
    if (normalized == 'application/pdf') return Icons.picture_as_pdf;
    if (ImageUploadService.isImageContentType(normalized)) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black87,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Center(child: InteractiveViewer(child: Image.network(url))),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
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
