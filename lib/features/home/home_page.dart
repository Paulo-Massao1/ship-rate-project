// lib/features/home/home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import 'main_screen_page.dart';
import '../navigation_safety/nav_safety_page.dart';
import '../../data/services/notification_service.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../data/services/version_service.dart';

/// Home screen displayed after login with module selection cards.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  // ===========================================================================
  // STATE
  // ===========================================================================

  static bool _notificationsInitialized = false;

  bool _showUpdateBanner = false;
  String _updateMessage = '';
  String? _nomeGuerra;
  bool _isCspam = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUserDomain();
    _checkForUpdates();
    _fetchNomeGuerra();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _checkUserDomain() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    _isCspam = email.toLowerCase().endsWith('@cspam.com.br');
  }

  Future<void> _initNotifications() async {
    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      if (mounted) {
        await NotificationService.initializeWithoutPermission(
          ScaffoldMessenger.of(context),
        );
      }
    }

    await _showNotificationDialogIfNeeded();
    await _showMilestoneDialogIfNeeded();
  }

  Future<void> _showNotificationDialogIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (!mounted) return;

    if (doc.data()?['notificationPromptShown'] == true) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1A26A69A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFF26A69A),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.notificationDialogTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.notificationDialogBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _markNotificationPromptShown(uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              l10n.notificationDialogNotNow,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final granted =
                  await NotificationService.requestPermissionAndEnable();
              await _markNotificationPromptShown(uid);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (granted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.notificationsEnabled),
                    backgroundColor: const Color(0xFF26A69A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              l10n.notificationDialogEnable,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMilestoneDialogIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (!mounted) return;

    if (doc.data()?['milestone200Shown'] == true) return;

    final countSnapshot = await FirebaseFirestore.instance
        .collection('navios')
        .count()
        .get();
    final totalShips = countSnapshot.count ?? 0;
    if (totalShips < 200) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x1A26A69A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF26A69A),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.milestone200Title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.milestone200Body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .set(
                {'milestone200Shown': true},
                SetOptions(merge: true),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              l10n.milestone200Button,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markNotificationPromptShown(String uid) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'notificationPromptShown': true},
      SetOptions(merge: true),
    );
  }

  Future<void> _fetchNomeGuerra() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!mounted) return;
      final nome = doc.data()?['nomeGuerra'] as String?;
      setState(() {
        _nomeGuerra = (nome != null && nome.trim().isNotEmpty) ? nome : 'Prático';
      });
    } catch (e) {
      debugPrint('[Home] Error fetching nomeGuerra: $e');
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        if (!mounted) return;
        final nome = doc.data()?['nomeGuerra'] as String?;
        setState(() {
          _nomeGuerra = (nome != null && nome.trim().isNotEmpty) ? nome : 'Prático';
        });
      } catch (_) {}
    }
  }

  Future<void> _checkForUpdates() async {
    final result = await VersionService.shouldShowUpdateBanner();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (result['shouldShow'] == true) {
      setState(() {
        _showUpdateBanner = true;
        _updateMessage = result['message'] ?? l10n.updateAvailable;
      });
    }
  }

  Future<void> _dismissUpdateBanner() async {
    await VersionService.markBannerAsSeen();
    setState(() => _showUpdateBanner = false);
  }


  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void _navigateToShipRating() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _navigateToNavSafety() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyPage()),
    );
  }


  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        currentScreen: AppScreen.home,
        showNavSafety: !_isCspam,
        onBeforeLogout: () {
          _notificationsInitialized = false;
        },
      ),
      body: Container(
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
        child: Column(
          children: [
            _buildUpdateBanner(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildWelcomeText(),
                      const SizedBox(height: 32),
                      _buildModuleCard(
                        icon: Icons.directions_boat,
                        iconBgColor: const Color(0x1F64B5F6),
                        iconBorderColor: const Color(0x3364B5F6),
                        iconColor: const Color(0xFF64B5F6),
                        borderColor: const Color(0x1A64B5F6),
                        title: AppLocalizations.of(context)!.shipRatingModule,
                        subtitle: AppLocalizations.of(context)!.shipRatingDesc,
                        onTap: _navigateToShipRating,
                      ),
                      if (!_isCspam) ...[
                        const SizedBox(height: 16),
                        _buildModuleCard(
                          icon: Icons.anchor,
                          iconBgColor: const Color(0x1F26A69A),
                          iconBorderColor: const Color(0x4026A69A),
                          iconColor: const Color(0xFF26A69A),
                          borderColor: const Color(0x3326A69A),
                          title: AppLocalizations.of(context)!.navSafetyModule,
                          subtitle: AppLocalizations.of(context)!.navSafetyDesc,
                          onTap: _navigateToNavSafety,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _nomeGuerra ?? 'Prático';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomePilot(displayName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.selectModule,
          style: const TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconBorderColor,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
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
      flexibleSpace: Container(
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
    );
  }


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
          BoxShadow(
              color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _dismissUpdateBanner,
            child: const Text(
              'OK',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

