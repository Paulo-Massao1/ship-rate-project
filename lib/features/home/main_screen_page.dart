// lib/features/home/main_screen_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;

import '../auth/login_page.dart';
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

  static const _primaryColor = Color(0xFF3F51B5);
  static const _gradientStart = Color(0xFF3F51B5);
  static const _gradientEnd = Color(0xFF2F3E9E);
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

  /// Key used to force complete widget tree rebuild.
  /// Useful for clearing caches and reloading Firestore data.
  Key _rebuildKey = UniqueKey();

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _forceRefresh();
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
      _forceRefresh();
      _checkForUpdates();
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Forces complete data refresh.
  ///
  /// Generates new Key to force complete KeyedSubtree rebuild.
  /// This clears caches and forces Firestore data reload.
  ///
  /// Called:
  /// - Automatically on app open
  /// - Automatically when returning to app (resumed)
  /// - Manually when needed
  Future<void> _forceRefresh() async {
    if (!mounted) return;
    setState(() => _rebuildKey = UniqueKey());
  }

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
      body: KeyedSubtree(
        key: _rebuildKey,
        child: Column(
          children: [
            _buildUpdateBanner(),
            const Expanded(child: SearchAndRateShipPage()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'ShipRate',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      centerTitle: true,
    );
  }

  Widget _buildDrawer() {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrawerHeader(),
            const SizedBox(height: 20),
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
            const Divider(height: 32, thickness: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: l10n.drawerLogout,
              color: Colors.redAccent,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_boat_filled, size: 48, color: Colors.white),
          const SizedBox(height: 14),
          const Text(
            'ShipRate',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appSubtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
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
// PRIVATE WIDGETS
// =============================================================================

/// Drawer navigation item widget.
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
    final itemColor = color ?? Colors.black87;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: itemColor),
      ),
      onTap: onTap,
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
