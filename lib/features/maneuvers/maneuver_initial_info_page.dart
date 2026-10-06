import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/models/maneuver_catalog.dart';
import '../../data/models/maneuver_report.dart';
import '../../data/models/maneuver_tug.dart';
import '../../data/services/maneuver_media_service.dart';
import '../../data/services/maneuver_report_service.dart';
import '../../data/services/maneuver_tug_service.dart';
import '../../data/services/url_launcher_service.dart';
import '../../shared/widgets/subscription_gate.dart';

class ManeuverInitialInfoPage extends StatelessWidget {
  const ManeuverInitialInfoPage({
    super.key,
    required this.port,
    required this.terminal,
  });

  final ManeuverPortDefinition port;
  final ManeuverTerminalDefinition terminal;

  static const _amber = Color(0xFFFFB74D);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _muted = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.initialManeuverInfo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: _bgDark,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: SubscriptionGate(
          requiredPlan: SubscriptionConstants.planPlus,
          featureDescription: l10n.plusFeature2,
          child: _buildContent(context, l10n),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final info = terminal.operationalInfo!;
    final locale = Localizations.localeOf(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 24),
          children: [
            _InfoAccordion(
              title: l10n.maneuverPortLimits,
              children: [
                _InfoRow(
                  label: l10n.maneuverSchedule,
                  value:
                      info.scheduleRestriction?.resolve(locale) ??
                      l10n.maneuverNoScheduleLimitation,
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumLengthShort,
                  value: '${_formatNumber(info.maximumLengthMeters, locale)} m',
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumWindShort,
                  value:
                      '${_formatNumber(info.maximumWindKnots, locale)} ${l10n.maneuverKnotsShort}',
                ),
                _InfoRow(
                  label: l10n.maneuverMinimumVisibilityShort,
                  value: '${info.minimumVisibilityMeters} m',
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumDwtShort,
                  value: '${_formatInteger(info.maximumDwtTons, locale)} t',
                ),
                _InfoRow(
                  label: l10n.maneuverBerthingSide,
                  value: info.berthingSide.resolve(locale),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoAccordion(
              title: l10n.maneuverInitialDetails,
              children: [
                _InfoRow(
                  label: l10n.maneuverChannel,
                  value: '${info.vhfChannel}',
                ),
                _InfoRow(
                  label: l10n.maneuverTugboats,
                  value:
                      info.tugboatsMandatory
                          ? l10n.maneuverMandatory
                          : l10n.maneuverNoRestriction,
                  valueColor: _amber,
                  trailingIcon: Icons.info_outline,
                  onTap: () => _showTugInformation(context, l10n, info),
                ),
                _InfoRow(
                  label: l10n.maneuverLaunch,
                  value: info.launchArrangement.resolve(locale),
                ),
                _InfoRow(
                  label: l10n.maneuverSimultaneousLines,
                  value: '${info.simultaneousLines}',
                ),
                _InfoRow(
                  label: l10n.maneuverQuayAlignment,
                  value: '${info.quayAlignmentDegrees}°',
                ),
                _InfoRow(
                  label: l10n.maneuverQuayLength,
                  value: '${_formatNumber(info.pierLengthMeters, locale)} m',
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoAccordion(
              title: l10n.maneuverMooring,
              children: [
                _InfoSubheading(l10n.maneuverLines),
                for (final mooring in info.mooring)
                  _InfoRow(
                    label: mooring.vesselClass,
                    value: mooring.lineGroups.join(' × '),
                  ),
                const SizedBox(height: 7),
                _InfoSubheading(l10n.maneuverFinalPosition),
                for (var index = 0; index < info.mooring.length; index++)
                  _InfoRow(
                    label: info.mooring[index].vesselClass,
                    value:
                        info.mooring[index].finalPosition?.resolve(locale) ??
                        l10n.maneuverToDefine,
                    valueColor: const Color(0x99FFFFFF),
                    showDivider: index < info.mooring.length - 1,
                  ),
                const SizedBox(height: 8),
                _InfoSubheading(l10n.maneuverMedia),
                const SizedBox(height: 7),
                _ManeuverTerminalMediaGallery(
                  portCode: port.code,
                  terminalId: terminal.id,
                  terminalName: terminal.name,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTugInformation(
    BuildContext context,
    AppLocalizations l10n,
    ManeuverOperationalInfo info,
  ) async {
    final locale = Localizations.localeOf(context);
    final tugs = ManeuverTugService().officialTugsForPort(port.code);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.maneuverOfficialTugInfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info.tugRequirementDetail.resolve(locale),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  ...tugs.map((tug) => _buildTugTile(context, tug, l10n)),
                  const SizedBox(height: 4),
                  Text(
                    info.tugMinimumNote.resolve(locale),
                    style: const TextStyle(color: _amber, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTugTile(
    BuildContext context,
    ManeuverTug tug,
    AppLocalizations l10n,
  ) {
    final type = switch (tug.type) {
      ManeuverTugType.azimuthal => l10n.maneuverTugTypeAzimuthal,
      ManeuverTugType.conventional => l10n.maneuverTugTypeConventional,
      ManeuverTugType.unspecified => l10n.maneuverTugTypeUnspecified,
    };
    final rawBp = tug.bollardPull?.toStringAsFixed(2);
    final bp =
        rawBp == null
            ? '—'
            : Localizations.localeOf(context).languageCode == 'pt'
            ? rawBp.replaceAll('.', ',')
            : rawBp;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tug.name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'BP $bp · ',
                  style: const TextStyle(color: _muted),
                ),
                TextSpan(
                  text: type,
                  style: const TextStyle(
                    color: _amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value, Locale locale) {
    final formatted =
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(2);
    return locale.languageCode == 'pt'
        ? formatted.replaceAll('.', ',')
        : formatted;
  }

  String _formatInteger(int value, Locale locale) {
    final separator = locale.languageCode == 'pt' ? '.' : ',';
    final digits = value.toString();
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        result.write(separator);
      }
      result.write(digits[index]);
    }
    return result.toString();
  }
}

class _InfoAccordion extends StatefulWidget {
  const _InfoAccordion({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  State<_InfoAccordion> createState() => _InfoAccordionState();
}

class _InfoAccordionState extends State<_InfoAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x08000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: const Color(0xFF1D2A35),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFFFFB74D),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child:
                _expanded
                    ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 3, 14, 11),
                      child: Column(children: widget.children),
                    )
                    : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _InfoSubheading extends StatelessWidget {
  const _InfoSubheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 7, bottom: 1),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFB74D),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailingIcon,
    this.onTap,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    trailingIcon,
                    color: valueColor ?? const Color(0xFFFFB74D),
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border:
            showDivider
                ? const Border(bottom: BorderSide(color: Color(0x12FFFFFF)))
                : null,
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class _ManeuverTerminalMediaGallery extends StatefulWidget {
  const _ManeuverTerminalMediaGallery({
    required this.portCode,
    required this.terminalId,
    required this.terminalName,
  });

  final String portCode;
  final String terminalId;
  final String terminalName;

  @override
  State<_ManeuverTerminalMediaGallery> createState() =>
      _ManeuverTerminalMediaGalleryState();
}

class _ManeuverTerminalMediaGalleryState
    extends State<_ManeuverTerminalMediaGallery> {
  static const _amber = Color(0xFFFFB74D);
  static const _muted = Color(0x99FFFFFF);

  final ManeuverMediaService _mediaService = const ManeuverMediaService();
  final Map<String, Future<String>> _downloadUrls = {};
  late final Stream<List<ManeuverReportRecord>> _reportsStream;
  String? _openingPath;

  @override
  void initState() {
    super.initState();
    _reportsStream = ManeuverReportService().watchReports(
      portCode: widget.portCode,
      terminalId: widget.terminalId,
      terminalName: widget.terminalName,
    );
  }

  Future<String> _downloadUrl(String path) {
    return _downloadUrls.putIfAbsent(
      path,
      () => _mediaService.getDownloadUrl(path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ManeuverReportRecord>>(
      stream: _reportsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: _amber, strokeWidth: 2),
              ),
            ),
          );
        }

        final items = <_TerminalMediaItem>[
          for (final report in snapshot.data ?? const <ManeuverReportRecord>[])
            for (final attachment in [
              ...report.approachMedia,
              ...report.mooringMedia,
            ])
              _TerminalMediaItem(report: report, attachment: attachment),
        ];

        if (snapshot.hasError || items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              l10n.maneuverMediaUnavailable,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.3),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 280 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.35,
              ),
              itemCount: items.length,
              itemBuilder:
                  (context, index) => _buildMediaTile(items[index], l10n),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaTile(_TerminalMediaItem item, AppLocalizations l10n) {
    final attachment = item.attachment;
    final opening = _openingPath == attachment.path;

    return FutureBuilder<String>(
      future: _downloadUrl(attachment.path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        return Material(
          color: const Color(0x12000000),
          borderRadius: BorderRadius.circular(9),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap:
                url == null || opening
                    ? null
                    : () => _openMedia(attachment.path, url, l10n),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (attachment.type == ManeuverMediaType.photo && url != null)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => _mediaPlaceholder(attachment.type),
                  )
                else
                  _mediaPlaceholder(attachment.type),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE60A1628)],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        attachment.originalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.report.shipName ??
                            item.report.pilotName ??
                            widget.terminalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                if (opening)
                  const Center(
                    child: CircularProgressIndicator(
                      color: _amber,
                      strokeWidth: 2,
                    ),
                  )
                else if (attachment.type == ManeuverMediaType.video)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaPlaceholder(ManeuverMediaType type) {
    return ColoredBox(
      color: const Color(0xFF15283B),
      child: Center(
        child: Icon(
          type == ManeuverMediaType.photo
              ? Icons.photo_outlined
              : Icons.videocam_outlined,
          color: _amber,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _openMedia(
    String path,
    String url,
    AppLocalizations l10n,
  ) async {
    setState(() => _openingPath = path);
    try {
      final opened = await UrlLauncherService.openExternalUrl(url);
      if (!opened) throw StateError('Could not open maneuver media.');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maneuverMediaOpenError),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingPath = null);
    }
  }
}

class _TerminalMediaItem {
  const _TerminalMediaItem({required this.report, required this.attachment});

  final ManeuverReportRecord report;
  final ManeuverMediaAttachment attachment;
}
