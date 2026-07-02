import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../core/module_access.dart';
import '../../data/services/url_launcher_service.dart';
import '../../main.dart';
import '../../shared/widgets/app_drawer.dart';
import '../home/main_screen_page.dart';
import '../suggestions/suggestion_page.dart';
import 'barra_norte_page.dart';
import 'operational_restrictions_page.dart';
import 'tide_table_page.dart';

class NavInfoPage extends StatefulWidget {
  const NavInfoPage({super.key});

  @override
  State<NavInfoPage> createState() => _NavInfoPageState();
}

class _NavInfoPageState extends State<NavInfoPage> {
  static const _purple = Color(0xFFB388FF);

  bool get _showRestrictedModules => ModuleAccess.canAccessRestrictedModules;

  void _navigateToSuggestions() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SuggestionPage()),
    );
  }

  void _shareApp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NavInfoShareBottomSheet(
        onWhatsAppTap: _shareAppViaWhatsApp,
        onCopyLinkTap: _copyLinkToClipboard,
      ),
    );
  }

  Future<void> _shareAppViaWhatsApp() async {
    Navigator.pop(context);
    final l10n = AppLocalizations.of(context)!;
    await UrlLauncherService.openWhatsAppShare(l10n.shareText);
  }

  Future<void> _copyLinkToClipboard() async {
    Navigator.pop(context);
    await Clipboard.setData(const ClipboardData(text: AppConstants.appUrl));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.linkCopied),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleLocale() {
    Navigator.pop(context);
    final next = localeController.locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    localeController.changeLocale(next);
  }

  void _onTideTableTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TideTablePage()),
    );
  }

  void _onBarraNorteTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarraNortePage()),
    );
  }

  void _onOperationalRestrictionsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperationalRestrictionsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_showRestrictedModules) {
      return const MainScreen();
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      drawer: AppDrawer(
        currentScreen: AppScreen.navInfo,
        showNavSafety: _showRestrictedModules,
        showNavInfo: _showRestrictedModules,
        bottomItems: [
          DrawerItem(
            icon: Icons.lightbulb_outline,
            label: l10n.drawerSendSuggestion,
            onTap: _navigateToSuggestions,
          ),
          DrawerItem(
            icon: Icons.share,
            label: l10n.drawerShareApp,
            onTap: () {
              Navigator.pop(context);
              _shareApp();
            },
          ),
          DrawerItem(
            icon: Icons.language,
            label: localeController.locale.languageCode == 'pt'
                ? 'English'
                : 'Português',
            onTap: _toggleLocale,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(
                    20, Navigator.canPop(context) ? 68 : 24, 20, 32,
                  ),
                  children: [
                    _buildSubItemCard(
                      icon: Icons.waves,
                      iconColor: const Color(0xFF26A69A),
                      iconBgColor: const Color(0x1F26A69A),
                      iconBorderColor: const Color(0x4026A69A),
                      borderColor: const Color(0x3326A69A),
                      title: l10n.tideTableTitle,
                      subtitle: l10n.tideTableSubtitle,
                      onTap: _onTideTableTap,
                    ),
                    const SizedBox(height: 16),
                    _buildBarraNorteCard(l10n),
                    const SizedBox(height: 16),
                    _buildSubItemCard(
                      icon: Icons.description,
                      iconColor: const Color(0xFFFFB74D),
                      iconBgColor: const Color(0x1FFFB74D),
                      iconBorderColor: const Color(0x40FFB74D),
                      borderColor: const Color(0x33FFB74D),
                      title: l10n.operationalRestrictionsTitle,
                      subtitle: l10n.operationalRestrictionsSubtitle,
                      onTap: _onOperationalRestrictionsTap,
                    ),
                  ],
                ),
                if (Navigator.canPop(context)) _buildPageBackButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageBackButton(AppLocalizations l10n) {
    return Positioned(
      top: 8,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xCC0A1628),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 13,
                  color: Color(0xCCFFFFFF),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.back,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore,
            color: _purple.withValues(alpha: 0.85),
            size: 24,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              l10n.navInfoModule.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _buildSubItemCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color iconBorderColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: borderColor,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconBorderColor),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        if (badge != null) badge,
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0x66FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraNorteCard(AppLocalizations l10n) {
    return _buildSubItemCard(
      icon: Icons.lock,
      iconColor: const Color(0xFFEF5350),
      iconBgColor: const Color(0x1FEF5350),
      iconBorderColor: const Color(0x40EF5350),
      borderColor: const Color(0x33EF5350),
      title: l10n.barraNorteTitle,
      subtitle: l10n.barraNorteSubtitle,
      onTap: _onBarraNorteTap,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x33EF5350),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x66EF5350)),
        ),
        child: Text(
          l10n.barraNorteBadge,
          style: const TextStyle(
            color: Color(0xFFEF5350),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _NavInfoShareBottomSheet extends StatelessWidget {
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCopyLinkTap;

  const _NavInfoShareBottomSheet({
    required this.onWhatsAppTap,
    required this.onCopyLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.shareShipRate,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: onWhatsAppTap,
                ),
                _ShareOption(
                  icon: Icons.link,
                  label: l10n.copyLink,
                  color: const Color(0xFFB388FF),
                  onTap: onCopyLinkTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
