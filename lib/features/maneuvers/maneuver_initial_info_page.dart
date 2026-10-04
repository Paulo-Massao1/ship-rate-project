import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/models/maneuver_catalog.dart';
import '../../data/models/maneuver_tug.dart';
import '../../data/services/maneuver_tug_service.dart';
import '../../shared/widgets/subscription_gate.dart';

class ManeuverInitialInfoPage extends StatelessWidget {
  const ManeuverInitialInfoPage({
    super.key,
    required this.port,
    required this.terminal,
  }) : assert(terminal.operationalInfo != null);

  final ManeuverPortDefinition port;
  final ManeuverTerminalDefinition terminal;

  static const _amber = Color(0xFFFFB74D);
  static const _teal = Color(0xFF26A69A);
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 14),
            _InfoAccordion(
              icon: Icons.straighten,
              title: l10n.maneuverPortLimits,
              initiallyExpanded: true,
              children: [
                _InfoRow(
                  label: l10n.maneuverSchedule,
                  value: info.scheduleRestriction?.resolve(locale) ??
                      l10n.maneuverNoRestrictions,
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumLength,
                  value: '${_formatNumber(info.maximumLengthMeters, locale)} m',
                ),
                _InfoRow(
                  label: l10n.maneuverBeamRestriction,
                  value: info.beamRestriction?.resolve(locale) ??
                      l10n.maneuverNoRestriction,
                ),
                _InfoRow(
                  label: l10n.maneuverPierLength,
                  value: '${_formatNumber(info.pierLengthMeters, locale)} m',
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumDwt,
                  value: '${_formatInteger(info.maximumDwtTons, locale)} t',
                ),
                _InfoRow(
                  label: l10n.maneuverAirDraft,
                  value: '${_formatNumber(info.airDraftMeters, locale)} m',
                  detail: info.airDraftDetail.resolve(locale),
                ),
                _InfoRow(
                  label: l10n.maneuverMaximumWind,
                  value:
                      '${_formatNumber(info.maximumWindKnots, locale)} ${l10n.maneuverKnotsShort}',
                ),
                _InfoRow(
                  label: l10n.maneuverMinimumVisibility,
                  value: '${info.minimumVisibilityMeters} m',
                ),
                _InfoRow(
                  label: l10n.maneuverCrossing,
                  value: info.crossingRestriction?.resolve(locale) ??
                      l10n.maneuverNoRestriction,
                ),
                const SizedBox(height: 12),
                _buildDraftTables(context, l10n, info),
              ],
            ),
            const SizedBox(height: 12),
            _InfoAccordion(
              icon: Icons.info_outline,
              title: l10n.initialManeuverInfo,
              initiallyExpanded: true,
              children: [
                _InfoRow(
                  label: l10n.maneuverVhfChannel,
                  value: '${info.vhfChannel}',
                ),
                _InfoRow(
                  label: l10n.maneuverTugboats,
                  value: info.tugboatsMandatory
                      ? l10n.maneuverMandatory
                      : l10n.maneuverNoRestriction,
                  valueColor: _amber,
                  trailingIcon: Icons.info_outline,
                  onTap: () => _showTugInformation(context, l10n, info),
                ),
                _InfoRow(
                  label: l10n.maneuverNavigation,
                  value: info.navigation.resolve(locale),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoAccordion(
              icon: Icons.anchor,
              title: l10n.maneuverMooring,
              initiallyExpanded: true,
              children: [
                Text(
                  l10n.maneuverMooringReferenceNote,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                for (final mooring in info.mooring)
                  _InfoRow(
                    label: mooring.vesselClass,
                    value: _formatMooring(mooring, locale),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDisclaimer(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.anchor, color: _teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terminal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${port.name} (${port.code})',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.maneuverOperationalParametersSource,
                  style: const TextStyle(color: _teal, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftTables(
    BuildContext context,
    AppLocalizations l10n,
    ManeuverOperationalInfo info,
  ) {
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.maneuverMaximumDrafts,
          style: const TextStyle(
            color: _amber,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < info.draftTables.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _DraftTable(
            title: info.draftTables[index].cargoType ==
                    ManeuverCargoType.general
                ? l10n.maneuverGeneralCargo
                : l10n.maneuverDangerousCargo,
            dryFacultative:
                _formatDraftLimit(info.draftTables[index].dryOptional, locale),
            floodFacultative: _formatDraftLimit(
              info.draftTables[index].floodOptional,
              locale,
            ),
            dryMandatory:
                _formatDraftLimit(info.draftTables[index].dryMandatory, locale),
            floodMandatory: _formatDraftLimit(
              info.draftTables[index].floodMandatory,
              locale,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          info.draftFootnote.resolve(locale),
          style: const TextStyle(
            color: Color(0x80FFFFFF),
            fontSize: 10,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: _amber, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.maneuverOperationalDisclaimer,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.maneuverOfficialTugInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.tugRequirementDetail.resolve(locale),
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 16),
              ...tugs.map((tug) => _buildTugTile(context, tug, l10n)),
              const SizedBox(height: 10),
              Text(
                info.tugMinimumNote.resolve(locale),
                style: const TextStyle(
                  color: Color(0xB3FFB74D),
                  fontSize: 11,
                  height: 1.4,
                ),
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
    var bp = '—';
    if (rawBp != null) {
      bp = Localizations.localeOf(context).languageCode == 'pt'
          ? rawBp.replaceAll('.', ',')
          : rawBp;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_boat, color: _amber, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tug.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'BP $bp · $type',
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDraftLimit(ManeuverDraftLimit limit, Locale locale) {
    final minimum = limit.minimum;
    if (minimum == null) return '—';

    final first = _formatNumber(minimum, locale, fractionDigits: 2);
    final maximum = limit.maximum;
    if (maximum == null) return '$first m';

    final last = _formatNumber(maximum, locale, fractionDigits: 2);
    return '$first–$last m';
  }

  String _formatMooring(
    ManeuverMooringDefinition mooring,
    Locale locale,
  ) {
    final prefix = locale.languageCode == 'pt' ? 'normalmente' : 'normally';
    return '$prefix ${mooring.lineGroups.join(' × ')}';
  }

  String _formatNumber(
    double value,
    Locale locale, {
    int? fractionDigits,
  }) {
    final digits = fractionDigits ?? (value == value.roundToDouble() ? 0 : 2);
    final formatted = value.toStringAsFixed(digits);
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

class _InfoAccordion extends StatelessWidget {
  const _InfoAccordion({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x26FFB74D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: const Color(0xFFFFB74D),
          collapsedIconColor: const Color(0x99FFB74D),
          backgroundColor: const Color(0x08FFB74D),
          collapsedBackgroundColor: const Color(0x08FFB74D),
          leading: Icon(icon, color: const Color(0xFFFFB74D), size: 20),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFB74D),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.detail,
    this.valueColor,
    this.trailingIcon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? detail;
  final Color? valueColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: valueColor ?? const Color(0xE6FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 5),
                      Icon(
                        trailingIcon,
                        color: valueColor ?? const Color(0x99FFFFFF),
                        size: 15,
                      ),
                    ],
                  ],
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0x66FFFFFF),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x12FFFFFF))),
      ),
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class _DraftTable extends StatelessWidget {
  const _DraftTable({
    required this.title,
    required this.dryFacultative,
    required this.floodFacultative,
    required this.dryMandatory,
    required this.floodMandatory,
  });

  final String title;
  final String dryFacultative;
  final String floodFacultative;
  final String dryMandatory;
  final String floodMandatory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x1FFFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: const Color(0x12FFB74D),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _tableRow(
            ['', l10n.maneuverDrySeason, l10n.maneuverFloodSeason],
            header: true,
          ),
          _tableRow([
            l10n.maneuverPilotageOptional,
            dryFacultative,
            floodFacultative,
          ]),
          _tableRow([
            l10n.maneuverPilotageMandatory,
            dryMandatory,
            floodMandatory,
          ]),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> values, {bool header = false}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: values.map((value) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: header
                      ? const Color(0x99FFFFFF)
                      : const Color(0xD9FFFFFF),
                  fontSize: header ? 9 : 10,
                  fontWeight: header ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
