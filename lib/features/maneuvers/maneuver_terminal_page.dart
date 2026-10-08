import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../core/subscription_constants.dart';
import '../../data/models/maneuver_catalog.dart';
import '../../core/theme/module_visuals.dart';
import '../../data/services/subscription_service.dart';
import '../subscription/subscription_page.dart';
import 'maneuver_history_page.dart';
import 'maneuver_initial_info_page.dart';
import 'maneuver_report_page.dart';

/// Maneuver entry points for a single terminal.
class ManeuverTerminalPage extends StatefulWidget {
  const ManeuverTerminalPage({
    super.key,
    required this.port,
    required this.terminal,
  });

  final ManeuverPortDefinition port;
  final ManeuverTerminalDefinition terminal;

  @override
  State<ManeuverTerminalPage> createState() => _ManeuverTerminalPageState();
}

class _ManeuverTerminalPageState extends State<ManeuverTerminalPage> {
  ManeuverPortDefinition get port => widget.port;
  ManeuverTerminalDefinition get terminal => widget.terminal;

  static const _amber = Color(0xFFFFB74D);
  static const _blue = Color(0xFF64B5F6);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _textMuted = Color(0x80FFFFFF);

  StreamSubscription<CustomerInfo>? _customerInfoSubscription;
  bool? _hasPlusAccess;

  bool get _hasDevBypass {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && AppConstants.devBypassUids.contains(uid);
  }

  @override
  void initState() {
    super.initState();

    if (_hasDevBypass) {
      _hasPlusAccess = true;
      return;
    }

    final cachedInfo = SubscriptionService.lastCustomerInfo;
    if (cachedInfo != null) {
      _hasPlusAccess = _grantsPlusAccess(cachedInfo);
    }

    _customerInfoSubscription = SubscriptionService.customerInfoStream.listen((
      customerInfo,
    ) {
      final granted = _grantsPlusAccess(customerInfo);
      if (!mounted || granted == _hasPlusAccess) return;
      setState(() => _hasPlusAccess = granted);
    });
    unawaited(_refreshSubscriptionAccess());
  }

  @override
  void dispose() {
    _customerInfoSubscription?.cancel();
    super.dispose();
  }

  bool _grantsPlusAccess(CustomerInfo customerInfo) {
    return SubscriptionService.activePlan(customerInfo) !=
        SubscriptionConstants.planNone;
  }

  Future<void> _refreshSubscriptionAccess() async {
    final granted = await SubscriptionService.isAnySubscriber();
    if (!mounted || granted == _hasPlusAccess) return;
    setState(() => _hasPlusAccess = granted);
  }

  Future<void> _openSubscriptionPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SubscriptionPage()));
    if (!mounted) return;
    await _refreshSubscriptionAccess();
  }

  void _openPreparation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManeuverInitialInfoPage(port: port, terminal: terminal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPreparation = terminal.hasPreparationInfo;
    final isCheckingSubscription = _hasPlusAccess == null;
    final hasPlusAccess = _hasPlusAccess == true;
    final hasPreparationAccess =
        !terminal.preparationRequiresPlus || hasPlusAccess;
    final preparationUnavailable = hasPreparationAccess && !hasPreparation;
    final canOpenPreparation = hasPreparationAccess && hasPreparation;

    return Scaffold(
      appBar: _buildSectionAppBar(context, terminal.name),
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
                  icon: ModuleVisuals.maneuverIcon,
                  title: l10n.initialManeuverInfo,
                  description: l10n.initialManeuverInfoDesc,
                  unavailableDescription:
                      preparationUnavailable
                          ? l10n.maneuverInitialInfoComingSoon
                          : null,
                  color: ModuleVisuals.maneuverColor,
                  badge:
                      terminal.preparationRequiresPlus &&
                              !isCheckingSubscription &&
                              !hasPlusAccess
                          ? l10n.plusPlan.toUpperCase()
                          : null,
                  enabled:
                      canOpenPreparation ||
                      (!isCheckingSubscription && !hasPreparationAccess),
                  onTap:
                      canOpenPreparation
                          ? _openPreparation
                          : isCheckingSubscription
                          ? null
                          : _openSubscriptionPage,
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.history,
                  title: l10n.maneuverHistory,
                  description: l10n.maneuverHistoryDesc,
                  color: _blue,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ManeuverHistoryPage(
                                portName: port.name,
                                portCode: port.code,
                                terminalId: terminal.id,
                                terminalName: terminal.name,
                              ),
                        ),
                      ),
                ),
                const SizedBox(height: 10),
                _buildActionCard(
                  icon: Icons.add_circle_outline,
                  title: l10n.reportManeuver,
                  description: l10n.reportManeuverDesc,
                  color: _amber,
                  emphasized: true,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ManeuverReportPage(
                                portName: port.name,
                                portCode: port.code,
                                terminalId: terminal.id,
                                terminalName: terminal.name,
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
        color: ModuleVisuals.maneuverSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModuleVisuals.maneuverCardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ModuleVisuals.maneuverBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              ModuleVisuals.maneuverIcon,
              color: ModuleVisuals.maneuverColor,
              size: 24,
            ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${port.name} (${port.code})',
                  style: const TextStyle(
                    color: ModuleVisuals.maneuverColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
    String? unavailableDescription,
    required Color color,
    required VoidCallback? onTap,
    bool emphasized = false,
    String? badge,
    bool enabled = true,
  }) {
    final effectiveColor = enabled ? color : _textMuted;

    return Material(
      color:
          emphasized && enabled
              ? color.withValues(alpha: 0.10)
              : const Color(0x0DFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  emphasized && enabled
                      ? color.withValues(alpha: 0.45)
                      : effectiveColor.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: effectiveColor, size: 21),
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
                              color:
                                  enabled
                                      ? (emphasized ? color : Colors.white)
                                      : _textMuted,
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
                      unavailableDescription ?? description,
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
              Icon(
                enabled ? Icons.chevron_right : Icons.lock_outline,
                color: effectiveColor.withValues(alpha: 0.65),
              ),
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
