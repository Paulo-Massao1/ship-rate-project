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
  static const _textMuted = Color(0x80FFFFFF);

  @override
  Widget build(BuildContext context) {
    if (!ModuleAccess.canAccessRestrictedModules) {
      return const MainScreen();
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
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
                  _buildPortGroup(context, port),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      leadingWidth: canPop ? 88 : null,
      leading:
          canPop
              ? TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  minimumSize: const Size(0, kToolbarHeight),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 15),
                label: Text(
                  l10n.back,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              : null,
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

  Widget _buildPortGroup(BuildContext context, ManeuverPortDefinition port) {
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
          _buildTerminalTile(context, port, terminal),
      ],
    );
  }

  Widget _buildTerminalTile(
    BuildContext context,
    ManeuverPortDefinition port,
    ManeuverTerminalDefinition terminal,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          ManeuverTerminalPage(port: port, terminal: terminal),
                ),
              ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ModuleVisuals.maneuverCardBorder),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    port.code,
                    style: const TextStyle(
                      color: _maneuverColor,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0x66FFFFFF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
