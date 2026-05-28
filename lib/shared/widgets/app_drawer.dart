import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../app/auth_gate.dart';
import '../../controllers/nav_safety_controller.dart';
import '../../features/home/main_screen_page.dart';
import '../../features/navigation_safety/nav_safety_page.dart';
import '../../features/settings/settings_page.dart';

enum AppScreen { home, shipRating, navSafety }

class AppDrawer extends StatelessWidget {
  final AppScreen currentScreen;
  final bool showNavSafety;
  final List<Widget> additionalItems;
  final List<Widget> bottomItems;
  final VoidCallback? onBeforeLogout;
  final CustomPainter? headerOverlayPainter;

  const AppDrawer({
    super.key,
    required this.currentScreen,
    this.showNavSafety = true,
    this.additionalItems = const [],
    this.bottomItems = const [],
    this.onBeforeLogout,
    this.headerOverlayPainter,
  });

  static Future<void> performLogout(
    BuildContext context, {
    VoidCallback? onBeforeLogout,
  }) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    NavSafetyController.clearAllCaches();
    onBeforeLogout?.call();
    await FirebaseAuth.instance.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      ..._buildModuleItems(context, l10n),
                      ...additionalItems,
                      const Spacer(),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0x1A64B5F6),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            ...bottomItems,
                            DrawerItem(
                              icon: Icons.settings,
                              label: l10n.settings,
                              onTap: () {
                                final navigator = Navigator.of(context);
                                navigator.pop();
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                            DrawerItem(
                              icon: Icons.logout,
                              label: l10n.drawerLogout,
                              color: const Color(0xFFEF5350),
                              onTap: () => performLogout(
                                context,
                                onBeforeLogout: onBeforeLogout,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildModuleItems(BuildContext context, AppLocalizations l10n) {
    switch (currentScreen) {
      case AppScreen.home:
        return [
          DrawerItem(
            icon: Icons.directions_boat,
            label: l10n.shipRatingModule,
            isActive: false,
            onTap: () => _navigateTo(context, AppScreen.shipRating),
          ),
          if (showNavSafety)
            DrawerItem(
              icon: Icons.anchor,
              label: l10n.navSafetyModule,
              isActive: false,
              onTap: () => _navigateTo(context, AppScreen.navSafety),
            ),
        ];
      case AppScreen.shipRating:
        return [
          _SwitchModuleItem(
            icon: Icons.anchor,
            label: l10n.switchToNavSafety,
            accentColor: const Color(0xFF26A69A),
            onTap: () => _navigateTo(context, AppScreen.navSafety),
          ),
        ];
      case AppScreen.navSafety:
        return [
          _SwitchModuleItem(
            icon: Icons.directions_boat,
            label: l10n.switchToShipRating,
            accentColor: const Color(0xFF64B5F6),
            onTap: () => _navigateTo(context, AppScreen.shipRating),
          ),
        ];
    }
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final bool isNavSafety = currentScreen == AppScreen.navSafety;

    final icon = isNavSafety ? Icons.anchor : Icons.directions_boat;
    final iconColor =
        isNavSafety ? const Color(0xFF26A69A) : const Color(0xFF64B5F6);
    final iconBgColor =
        isNavSafety ? const Color(0x2626A69A) : const Color(0x2664B5F6);
    final title = isNavSafety ? l10n.navSafetyModule : 'ShipRate';
    final subtitle = isNavSafety ? null : l10n.appSubtitle;

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x2664B5F6), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xB364B5F6),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );

    if (headerOverlayPainter != null) {
      return Stack(
        children: [
          content,
          Positioned.fill(
            child: CustomPaint(painter: headerOverlayPainter!),
          ),
        ],
      );
    }

    return content;
  }

  void _navigateTo(BuildContext context, AppScreen target) {
    final navigator = Navigator.of(context);
    if (currentScreen == target) {
      navigator.pop();
      return;
    }
    navigator.pop();
    switch (target) {
      case AppScreen.shipRating:
        navigator.push(MaterialPageRoute(builder: (_) => const MainScreen()));
      case AppScreen.navSafety:
        navigator
            .push(MaterialPageRoute(builder: (_) => const NavSafetyPage()));
      case AppScreen.home:
        break;
    }
  }
}

class _SwitchModuleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _SwitchModuleItem({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: accentColor.withValues(alpha: 0.12),
          splashColor: accentColor.withValues(alpha: 0.12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: accentColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isActive;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isActive ? const Color(0xFF26A69A) : (color ?? const Color(0xD9FFFFFF));
    final iconColor = isActive
        ? const Color(0xFF26A69A)
        : (color ?? Colors.white.withValues(alpha: 0.7));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? const Color(0x1A26A69A) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: const Color(0x1A64B5F6),
          splashColor: const Color(0x1A64B5F6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
