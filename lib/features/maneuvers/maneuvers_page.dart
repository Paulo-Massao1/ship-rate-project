import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/module_access.dart';
import '../../core/theme/module_visuals.dart';
import '../../data/models/maneuver_catalog.dart';
import '../../shared/widgets/app_drawer.dart';
import '../home/main_screen_page.dart';
import 'maneuver_terminal_page.dart';

/// Entry point for maneuver information, reports and history by terminal.
class ManeuversPage extends StatelessWidget {
  const ManeuversPage({super.key});

  static const _maneuverColor = ModuleVisuals.maneuverColor;
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _cardBg = Color(0x0DFFFFFF);
  static const _cardBorder = Color(0x1AFFFFFF);
  static const _textMuted = Color(0x80FFFFFF);

  @override
  Widget build(BuildContext context) {
    if (!ModuleAccess.canAccessRestrictedModules) {
      return const MainScreen();
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      drawer: const AppDrawer(
        currentScreen: AppScreen.maneuvers,
        showManeuvers: true,
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
                _buildIntroCard(l10n),
                const SizedBox(height: 20),
                for (final port in ManeuverCatalog.ports) ...[
                  _buildPortGroup(context, l10n, port),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.maneuvers,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
            colors: [_bgDark, Color(0xFF1A3A5C), _bgMid],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModuleVisuals.maneuverSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ModuleVisuals.maneuverCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ModuleVisuals.maneuverBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              ModuleVisuals.maneuverIcon,
              color: _maneuverColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.maneuversSelectTerminal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.maneuverAccessNotice,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortGroup(
    BuildContext context,
    AppLocalizations l10n,
    ManeuverPortDefinition port,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '${port.name} (${port.code})',
            style: const TextStyle(
              color: _maneuverColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final terminal in port.terminals)
          _buildTerminalTile(context, l10n, port, terminal),
      ],
    );
  }

  Widget _buildTerminalTile(
    BuildContext context,
    AppLocalizations l10n,
    ManeuverPortDefinition port,
    ManeuverTerminalDefinition terminal,
  ) {
    final available = terminal.isReleased;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: available ? _cardBg : const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: available
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManeuverTerminalPage(
                        port: port,
                        terminal: terminal,
                      ),
                    ),
                  )
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: available
                    ? ModuleVisuals.maneuverCardBorder
                    : _cardBorder,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    port.code,
                    style: TextStyle(
                      color: available
                          ? _maneuverColor
                          : const Color(0x4DFFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    terminal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: available ? Colors.white : _textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (available)
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0x66FFFFFF),
                    size: 20,
                  )
                else
                  _buildComingSoonBadge(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        l10n.comingSoonBadge,
        style: const TextStyle(
          color: Color(0x66FFFFFF),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
