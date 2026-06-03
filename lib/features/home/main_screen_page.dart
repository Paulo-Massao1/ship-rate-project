// lib/features/home/main_screen_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;

import '../ships/search_ship_page.dart';
import '../suggestions/suggestion_page.dart';
import '../ratings/my_ratings_page.dart';
import '../../data/services/version_service.dart';
import '../../shared/widgets/app_drawer.dart';
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
      'Conheça o ShipRate, o app dos práticos para avaliar navios e reportar '
      'profundidades dos trechos navegados. Baixe aqui: $_shareUrl';

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
      drawer: _buildDrawer(context),
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

  Widget _buildDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppDrawer(
      currentScreen: AppScreen.shipRating,
      showNavSafety: _showNavSafetyModule,
      headerOverlayPainter: _LinePatternPainter(opacity: 0.04),
      additionalItems: [
        DrawerItem(
          icon: Icons.assignment_turned_in_outlined,
          label: l10n.drawerMyRatings,
          onTap: _navigateToMyRatings,
        ),
      ],
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
    );
  }

  bool get _showNavSafetyModule {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return !email.toLowerCase().endsWith('@cspam.com.br');
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
