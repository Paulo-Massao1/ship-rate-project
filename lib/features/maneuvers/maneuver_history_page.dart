import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../data/models/maneuver_report.dart';
import '../../data/models/maneuver_tug.dart';
import '../../data/services/maneuver_report_service.dart';

class ManeuverHistoryPage extends StatefulWidget {
  const ManeuverHistoryPage({
    super.key,
    required this.portName,
    required this.portCode,
    required this.terminalName,
  });

  final String portName;
  final String portCode;
  final String terminalName;

  @override
  State<ManeuverHistoryPage> createState() => _ManeuverHistoryPageState();
}

class _ManeuverHistoryPageState extends State<ManeuverHistoryPage> {
  static const _blue = Color(0xFF64B5F6);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _muted = Color(0x99FFFFFF);

  late final ManeuverReportService _service;
  late final Stream<List<ManeuverReportRecord>> _reportsStream;

  @override
  void initState() {
    super.initState();
    _service = ManeuverReportService();
    _reportsStream = _service.watchReports(
      portCode: widget.portCode,
      terminalName: widget.terminalName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.maneuverHistory,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: _bgDark,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: StreamBuilder<List<ManeuverReportRecord>>(
          stream: _reportsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _buildError(l10n);
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _blue),
              );
            }

            final reports = snapshot.data!;
            if (reports.isEmpty) return _buildEmpty(l10n);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: reports.length + 1,
                  separatorBuilder: (_, index) => SizedBox(
                    height: index == 0 ? 16 : 10,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader(l10n);
                    return _buildReportCard(l10n, reports[index - 1]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _blue.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: _blue, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.terminalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.portName} (${widget.portCode})',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.maneuverHistoryIntro,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    AppLocalizations l10n,
    ManeuverReportRecord report,
  ) {
    final summary = <String>[
      if (report.maximumDraftMeters != null)
        '${l10n.maneuverMaximumDraft}: ${_number(report.maximumDraftMeters!)} m',
      if (report.forwardTug != null)
        '${l10n.maneuverForwardShort}: ${report.forwardTug!.name}',
      if (report.aftTug != null)
        '${l10n.maneuverAftShort}: ${report.aftTug!.name}',
    ];

    return Material(
      color: const Color(0x0DFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _openReport(report),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.directions_boat_outlined,
                  color: _blue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.shipName ?? l10n.maneuverUnknownShip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.pilotName ?? l10n.maneuverUnknownPilot} · ${_date(report.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        summary.join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xB3FFB74D),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return _centeredState(
      icon: Icons.history_toggle_off,
      title: l10n.maneuverHistoryEmpty,
      description: l10n.maneuverHistoryEmptyDescription,
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return _centeredState(
      icon: Icons.cloud_off_outlined,
      title: l10n.maneuverHistoryLoadError,
      description: l10n.maneuverHistoryLoadErrorDescription,
    );
  }

  Widget _centeredState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _blue, size: 42),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReport(ManeuverReportRecord report) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ManeuverReportDetailsPage(
          report: report,
          service: _service,
        ),
      ),
    );
    if (!mounted || deleted != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.maneuverReportDeleted),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }

  String _date(DateTime? date) {
    return date == null ? '—' : DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _number(double value) {
    final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    final normalized = text.replaceFirst(RegExp(r'\.$'), '');
    return Localizations.localeOf(context).languageCode == 'pt'
        ? normalized.replaceAll('.', ',')
        : normalized;
  }
}

class _ManeuverReportDetailsPage extends StatefulWidget {
  const _ManeuverReportDetailsPage({
    required this.report,
    required this.service,
  });

  final ManeuverReportRecord report;
  final ManeuverReportService service;

  @override
  State<_ManeuverReportDetailsPage> createState() =>
      _ManeuverReportDetailsPageState();
}

class _ManeuverReportDetailsPageState
    extends State<_ManeuverReportDetailsPage> {
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _muted = Color(0x99FFFFFF);

  bool _deleting = false;

  bool get _isOwner =>
      widget.service.currentUserId != null &&
      widget.service.currentUserId == widget.report.pilotId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final report = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.maneuverReportDetails,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: _bgDark,
        actions: [
          if (_isOwner)
            IconButton(
              tooltip: l10n.deleteLabel,
              onPressed: _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildSummary(l10n),
                if (report.hasShipData) ...[
                  const SizedBox(height: 14),
                  _buildShipSection(l10n),
                ],
                if (report.hasApproachData) ...[
                  const SizedBox(height: 14),
                  _buildApproachSection(l10n),
                ],
                if (report.hasMooringData) ...[
                  const SizedBox(height: 14),
                  _buildMooringSection(l10n),
                ],
                if (!report.hasShipData &&
                    !report.hasApproachData &&
                    !report.hasMooringData) ...[
                  const SizedBox(height: 32),
                  Text(
                    l10n.maneuverNoAdditionalInfo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(AppLocalizations l10n) {
    final report = widget.report;
    return _DetailSection(
      icon: Icons.receipt_long_outlined,
      title: report.shipName ?? l10n.maneuverUnknownShip,
      children: [
        _DetailRow(
          label: l10n.maneuverPilot,
          value: report.pilotName ?? l10n.maneuverUnknownPilot,
        ),
        _DetailRow(
          label: l10n.maneuverReportDate,
          value: _date(report.createdAt),
        ),
        _DetailRow(
          label: l10n.maneuverLocation,
          value:
              '${report.terminalName} · ${report.portName} (${report.portCode})',
        ),
      ],
    );
  }

  Widget _buildShipSection(AppLocalizations l10n) {
    final report = widget.report;
    return _DetailSection(
      icon: Icons.directions_boat_outlined,
      title: l10n.shipData,
      children: [
        if (report.shipName != null)
          _DetailRow(label: l10n.shipName, value: report.shipName!),
        if (report.lengthMeters != null)
          _DetailRow(
            label: l10n.maneuverShipLength,
            value: '${_number(report.lengthMeters!)} m',
          ),
        if (report.beamMeters != null)
          _DetailRow(
            label: l10n.maneuverShipBeam,
            value: '${_number(report.beamMeters!)} m',
          ),
        if (report.maximumDraftMeters != null)
          _DetailRow(
            label: l10n.maneuverMaximumDraft,
            value: '${_number(report.maximumDraftMeters!)} m',
          ),
        if (report.propellerDirection != null)
          _DetailRow(
            label: l10n.maneuverPropellerDirection,
            value: report.propellerDirection ==
                    ManeuverPropellerDirection.rightHanded
                ? l10n.maneuverRightHanded
                : l10n.maneuverLeftHanded,
          ),
        if (report.propellerPitch != null)
          _DetailRow(
            label: l10n.maneuverPropellerPitch,
            value: report.propellerPitch == ManeuverPropellerPitch.fixed
                ? l10n.maneuverPitchFixed
                : l10n.maneuverPitchControllable,
          ),
        if (report.officerNationality != null)
          _DetailRow(
            label: l10n.maneuverOfficerNationality,
            value: report.officerNationality!,
          ),
        if (report.crewNationality != null)
          _DetailRow(
            label: l10n.crewNationality,
            value: report.crewNationality!,
          ),
      ],
    );
  }

  Widget _buildApproachSection(AppLocalizations l10n) {
    final report = widget.report;
    return _DetailSection(
      icon: Icons.assistant_direction,
      title: l10n.maneuverApproach,
      children: [
        if (report.forwardTug != null)
          _DetailRow(
            label: l10n.maneuverTugForward,
            value: _tugDescription(report.forwardTug!, l10n),
          ),
        if (report.aftTug != null)
          _DetailRow(
            label: l10n.maneuverTugAft,
            value: _tugDescription(report.aftTug!, l10n),
          ),
        if (report.currentDirectionDegrees != null ||
            report.currentIntensityKnots != null)
          _DetailRow(
            label: l10n.maneuverCurrent,
            value: _conditions(
              report.currentDirectionDegrees,
              report.currentIntensityKnots,
              l10n,
            ),
          ),
        if (report.windDirectionDegrees != null ||
            report.windIntensityKnots != null)
          _DetailRow(
            label: l10n.maneuverWind,
            value: _conditions(
              report.windDirectionDegrees,
              report.windIntensityKnots,
              l10n,
            ),
          ),
        if (report.approachComments != null)
          _DetailRow(
            label: l10n.maneuverComments,
            value: report.approachComments!,
          ),
      ],
    );
  }

  Widget _buildMooringSection(AppLocalizations l10n) {
    final report = widget.report;
    return _DetailSection(
      icon: Icons.anchor,
      title: l10n.maneuverMooring,
      children: [
        if (report.forwardFirstLine != null)
          _DetailRow(
            label: l10n.maneuverForwardFirstLines,
            value: _firstLine(report.forwardFirstLine!, l10n),
          ),
        if (report.aftFirstLine != null)
          _DetailRow(
            label: l10n.maneuverAftFirstLines,
            value: _firstLine(report.aftFirstLine!, l10n),
          ),
        if (report.mooringComments != null)
          _DetailRow(
            label: l10n.maneuverComments,
            value: report.mooringComments!,
          ),
      ],
    );
  }

  String _tugDescription(
    ManeuverTugSnapshot tug,
    AppLocalizations l10n,
  ) {
    final details = <String>[
      tug.name,
      if (tug.bollardPull != null) 'BP ${_number(tug.bollardPull!)}',
      switch (tug.type) {
        ManeuverTugType.azimuthal => l10n.maneuverTugTypeAzimuthal,
        ManeuverTugType.conventional => l10n.maneuverTugTypeConventional,
        ManeuverTugType.unspecified => l10n.maneuverTugTypeUnspecified,
      },
      tug.source == 'operationalParameters'
          ? l10n.maneuverTugOfficialSource
          : l10n.maneuverTugCommunitySource,
    ];
    return details.join(' · ');
  }

  String _conditions(
    int? direction,
    double? intensity,
    AppLocalizations l10n,
  ) {
    final values = <String>[
      if (direction != null) '${direction.toString().padLeft(3, '0')}°',
      if (intensity != null) '${_number(intensity)} ${l10n.maneuverKnotsShort}',
    ];
    return values.join(' · ');
  }

  String _firstLine(ManeuverFirstLine value, AppLocalizations l10n) {
    return switch (value) {
      ManeuverFirstLine.headLine => l10n.maneuverHeadLine,
      ManeuverFirstLine.breastLine => l10n.maneuverBreastLine,
      ManeuverFirstLine.spring => l10n.maneuverSpring,
    };
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bgMid,
        title: Text(
          l10n.maneuverDeleteReportTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.maneuverDeleteReportConfirm,
          style: const TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade300),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.service.deleteReport(widget.report.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maneuverReportDeleteError),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  String _date(DateTime? date) {
    return date == null ? '—' : DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _number(double value) {
    final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    final normalized = text.replaceFirst(RegExp(r'\.$'), '');
    return Localizations.localeOf(context).languageCode == 'pt'
        ? normalized.replaceAll('.', ',')
        : normalized;
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFB74D), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
