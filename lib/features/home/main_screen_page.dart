// lib/features/home/main_screen_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;

import '../auth/login_page.dart';
import '../settings/settings_page.dart';
import 'home_page.dart';
import '../ships/search_ship_page.dart';
import '../suggestions/suggestion_page.dart';
import '../ratings/my_ratings_page.dart';
import '../../controllers/home_controller.dart';
import '../../data/services/version_service.dart';
import '../../main.dart';

/// Main screen of the ShipRate application.
///
/// Responsibilities:
/// - Manage main navigation drawer
/// - Control app lifecycle (foreground/background)
/// - Force data refresh when returning to app
/// - Display update banner when available
/// - Handle navigation between main screens
///
/// Versioning System:
/// - Checks version on app open (initState)
/// - Checks version when returning to app (resumed)
/// - Compares local version (localStorage) with remote (Firestore)
/// - Shows blue banner when update is available
/// - User clicks OK → banner disappears
/// - On app reopen → updated code is applied
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _shareUrl = 'https://shiprate-daf18.web.app/';
  static const _shareText =
      'Conheça o ShipRate! O app de avaliação profissional de navios para práticos. '
      'Acesse: $_shareUrl';

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// Controls update banner visibility.
  bool _showUpdateBanner = false;

  /// Custom message displayed in banner (from Firestore).
  String _updateMessage = '';

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called when the app changes state (resumed, paused, detached).
  ///
  /// Behavior:
  /// - resumed: App returned to foreground → force refresh and check updates
  /// - paused: App went to background → no action
  /// - detached: App was closed → no action
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Checks if an update is available.
  ///
  /// Queries VersionService which compares local version with remote (Firestore).
  /// If there's a difference and user hasn't seen banner, shows blue banner.
  Future<void> _checkForUpdates() async {
    final result = await VersionService.shouldShowUpdateBanner();

    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    if (result['shouldShow'] == true) {
      setState(() {
        _showUpdateBanner = true;
        _updateMessage = result['message'] ??
            l10n.updateAvailable;
      });
    }
  }

  /// Logs out the user.
  ///
  /// Execution flow:
  /// 1. Calls logout via HomeController (Firebase Auth)
  /// 2. Removes all screens from navigation stack
  /// 3. Navigates to LoginPage as new root
  ///
  /// Uses pushAndRemoveUntil to completely clear navigation stack,
  /// preventing user from returning to main screen after logout.
  Future<void> _handleLogout() async {
    final controller = MainScreenController();
    await controller.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  /// Toggles between PT and EN locales.
  void _toggleLocale() {
    Navigator.pop(context);
    final next = localeController.locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    localeController.changeLocale(next);
  }

  /// Dismisses the update banner.
  Future<void> _dismissUpdateBanner() async {
    await VersionService.markBannerAsSeen();
    setState(() => _showUpdateBanner = false);
  }

  /// Shows share app bottom sheet.
  void _shareApp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ShareBottomSheet(
        onWhatsAppTap: _shareViaWhatsApp,
        onCopyLinkTap: _copyLinkToClipboard,
      ),
    );
  }

  /// Opens WhatsApp with share text.
  void _shareViaWhatsApp() {
    Navigator.pop(context);
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(_shareText)}';
    html.window.open(whatsappUrl, '_blank');
  }

  /// Copies app link to clipboard.
  Future<void> _copyLinkToClipboard() async {
    Navigator.pop(context);
    await Clipboard.setData(const ClipboardData(text: _shareUrl));

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

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void _navigateToMyRatings() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyRatingsPage()),
    );
  }

  void _navigateToSuggestions() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SuggestionPage()),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildUpdateBanner(),
          const Expanded(child: SearchAndRateShipPage()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_boat,
            color: const Color(0xFF64B5F6).withValues(alpha: 0.85),
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'SHIPRATE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black54,
      flexibleSpace: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF1A3A5C),
                  Color(0xFF0D2137),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Subtle horizontal line texture overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _LinePatternPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2137),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDrawerHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _DrawerItem(
                        icon: Icons.home,
                        label: l10n.modules,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomePage()),
                            (_) => false,
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.search,
                        label: l10n.drawerSearchRate,
                        onTap: () => Navigator.pop(context),
                      ),
                      _DrawerItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: l10n.drawerMyRatings,
                        onTap: _navigateToMyRatings,
                      ),
                      _DrawerItem(
                        icon: Icons.lightbulb_outline,
                        label: l10n.drawerSendSuggestion,
                        onTap: _navigateToSuggestions,
                      ),
                      _DrawerItem(
                        icon: Icons.share,
                        label: l10n.drawerShareApp,
                        onTap: () {
                          Navigator.pop(context);
                          _shareApp();
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.language,
                        label: localeController.locale.languageCode == 'pt'
                            ? 'English'
                            : 'Português',
                        onTap: _toggleLocale,
                      ),
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
                            _DrawerItem(
                              icon: Icons.settings,
                              label: l10n.settings,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                                );
                              },
                            ),
                            _DrawerItem(
                              icon: Icons.logout,
                              label: l10n.drawerLogout,
                              color: const Color(0xFFEF5350),
                              onTap: _handleLogout,
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

  Widget _buildDrawerHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Gradient background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF1A3A5C),
                Color(0xFF0D2137),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            border: Border(
              bottom: BorderSide(
                color: Color(0x2664B5F6),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ship icon in rounded container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x2664B5F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_boat,
                  size: 32,
                  color: Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ShipRate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.appSubtitle,
                style: const TextStyle(
                  color: Color(0xB364B5F6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // Subtle horizontal line texture
        Positioned.fill(
          child: CustomPaint(
            painter: _LinePatternPainter(opacity: 0.04),
          ),
        ),
      ],
    );
  }

  /// Builds update banner displayed at top when update is available.
  ///
  /// Design:
  /// - Blue gradient
  /// - Update icon
  /// - Two-line message
  /// - OK button aligned to the right
  Widget _buildUpdateBanner() {
    if (!_showUpdateBanner) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade600],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.updateAvailable,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _updateMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _dismissUpdateBanner,
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAINTERS
// =============================================================================

/// Draws subtle horizontal lines for texture overlay.
class _LinePatternPainter extends CustomPainter {
  final double opacity;

  _LinePatternPainter({this.opacity = 0.06});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePatternPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

/// Drawer navigation item widget with deep ocean theme.
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? const Color(0xD9FFFFFF);
    final iconColor = color ?? Colors.white.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
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

/// Share bottom sheet widget.
class _ShareBottomSheet extends StatelessWidget {
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCopyLinkTap;

  const _ShareBottomSheet({
    required this.onWhatsAppTap,
    required this.onCopyLinkTap,
  });

  static const _whatsAppColor = Color(0xFF25D366);
  static const _primaryColor = Color(0xFF3F51B5);

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
                  color: _whatsAppColor,
                  onTap: onWhatsAppTap,
                ),
                _ShareOption(
                  icon: Icons.link,
                  label: l10n.copyLink,
                  color: _primaryColor,
                  onTap: onCopyLinkTap,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Share option button widget.
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
