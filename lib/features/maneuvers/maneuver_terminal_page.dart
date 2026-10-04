import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../shared/widgets/subscription_gate.dart';
import 'maneuver_history_page.dart';
import 'maneuver_report_page.dart';

/// Maneuver entry points for a single terminal.
class ManeuverTerminalPage extends StatelessWidget {
  const ManeuverTerminalPage({
    super.key,
    required this.portName,
    required this.portCode,
    required this.terminalName,
  });

  final String portName;
  final String portCode;
  final String terminalName;

  static const _amber = Color(0xFFFFB74D);
  static const _blue = Color(0xFF64B5F6);
  static const _teal = Color(0xFF26A69A);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _textMuted = Color(0x80FFFFFF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildSectionAppBar(context, terminalName),
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
                _buildTerminalHeader(),
                const SizedBox(height: 20),
                _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: l10n.reportManeuver,
                  description: l10n.reportManeuverDesc,
                  color: _amber,
                  emphasized: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManeuverReportPage(
                        portName: portName,
                        portCode: portCode,
                        terminalName: terminalName,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.history,
                  title: l10n.maneuverHistory,
                  description: l10n.maneuverHistoryDesc,
                  color: _blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManeuverHistoryPage(
                        portName: portName,
                        portCode: portCode,
                        terminalName: terminalName,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.info_outline,
                  title: l10n.initialManeuverInfo,
                  description: l10n.initialManeuverInfoDesc,
                  color: _teal,
                  badge: l10n.plusPlan.toUpperCase(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ManeuverInitialInfoPage(
                        portName: portName,
                        portCode: portCode,
                        terminalName: terminalName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0FFFB74D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFB74D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1FFFB74D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.anchor, color: _amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terminalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$portName ($portCode)',
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool emphasized = false,
    String? badge,
  }) {
    return Material(
      color: emphasized ? color.withValues(alpha: 0.10) : const Color(0x0DFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: emphasized
                  ? color.withValues(alpha: 0.45)
                  : color.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: emphasized ? color : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(badge, color),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

}

class _ManeuverInitialInfoPage extends StatelessWidget {
  const _ManeuverInitialInfoPage({
    required this.portName,
    required this.portCode,
    required this.terminalName,
  });

  final String portName;
  final String portCode;
  final String terminalName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildSectionAppBar(context, l10n.initialManeuverInfo),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: SubscriptionGate(
          requiredPlan: SubscriptionConstants.planPlus,
          featureDescription: l10n.plusFeature2,
          child: _ManeuverSectionEmptyState(
            title: terminalName,
            subtitle: '$portName ($portCode)',
            description: l10n.maneuverInitialInfoComingSoon,
            icon: Icons.info_outline,
            color: const Color(0xFF26A69A),
          ),
        ),
      ),
    );
  }
}

class _ManeuverSectionEmptyState extends StatelessWidget {
  const _ManeuverSectionEmptyState({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                l10n.comingSoon,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget _buildSectionAppBar(BuildContext context, String title) {
  final l10n = AppLocalizations.of(context)!;

  return AppBar(
    leadingWidth: 96,
    leading: TextButton.icon(
      onPressed: () => Navigator.maybePop(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.only(left: 8, right: 6),
        minimumSize: const Size(0, kToolbarHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: 15),
      label: Text(
        l10n.back,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: true,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black54,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    ),
  );
}
