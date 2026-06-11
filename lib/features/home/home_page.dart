// lib/features/home/home_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../crossing/crossing_page.dart';
import 'main_screen_page.dart';
import '../navigation_safety/nav_safety_page.dart';
import '../../data/services/notification_service.dart';
import '../../controllers/dashboard_controller.dart';
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

  static const bool _milestone200DialogEnabled = false;

  // ===========================================================================
  // STATE
  // ===========================================================================

  static bool _notificationsInitialized = false;
  static final Map<String, String> _cachedNomeGuerraByUid = {};
  static const Duration _nomeGuerraServerTimeout = Duration(seconds: 4);
  bool _showUpdateBanner = false;
  String _updateMessage = '';
  String? _nomeGuerra;
  bool _isCspam = false;
  bool _showNotificationSetupBanner = false;
  bool _isRequestingNotificationSetup = false;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  final _dashboardController = DashboardController();
  DashboardData _statsData =
      DashboardController.cachedData ?? DashboardData.empty();

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
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingRoute();
      _initNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
      _checkNotificationSetupBanner();
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _consumePendingRoute() {
    final route = NotificationService.pendingRoute;
    if (route != null) {
      NotificationService.pendingRoute = null;
      if (route == 'nav_safety') {
        _navigateToNavSafety();
      } else if (route == 'crossing') {
        _navigateToCrossing();
      }
    }

    _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) {
      final type = message.data['type'] as String?;
      if (type == 'nav_safety') {
        _navigateToNavSafety();
      } else if (type == 'crossing') {
        _navigateToCrossing();
      }
    });
  }

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
    // Milestone 200 ships dialog — disabled (already shown to active pilots)
    // To re-enable for a new milestone, update the threshold and Firestore flag.
    if (_milestone200DialogEnabled) {
      await _showMilestoneDialogIfNeeded();
    }
    await _showCrossingDialogIfNeeded();
    await _checkNotificationSetupBanner();
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

  Future<void> _showCrossingDialogIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    if (!mounted) return;

    if (doc.data()?['cruzamentoDialogShown'] == true) return;

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
                color: const Color(0x1AFFB74D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.swap_vert,
                color: Color(0xFFFFB74D),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.cruzamentoDialogTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.cruzamentoDialogBody,
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
              backgroundColor: const Color(0xFFFFB74D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await _markCrossingDialogShown(uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              l10n.cruzamentoDialogButton,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markCrossingDialogShown(String uid) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'cruzamentoDialogShown': true},
      SetOptions(merge: true),
    );
  }

  Future<void> _fetchNomeGuerra() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final cachedName = _cachedNomeGuerraByUid[uid];
    if (cachedName != null && cachedName.isNotEmpty) {
      _setNomeGuerra(cachedName, uid: uid);
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(_nomeGuerraServerTimeout);
      _setNomeGuerraFromData(doc.data(), uid);
    } catch (e) {
      debugPrint('[Home] Error fetching nomeGuerra: $e');
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        _setNomeGuerraFromData(doc.data(), uid);
      } catch (_) {}
    }
  }

  void _setNomeGuerraFromData(Map<String, dynamic>? data, String uid) {
    final rawName = data?['nomeGuerra'];
    final name = rawName == null ? '' : rawName.toString().trim();
    if (name.isNotEmpty) {
      _setNomeGuerra(name, uid: uid);
    }
  }

  void _setNomeGuerra(String value, {String? uid}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    if (uid != null) {
      _cachedNomeGuerraByUid[uid] = trimmed;
    }

    if (!mounted) {
      _nomeGuerra = trimmed;
      return;
    }

    if (_nomeGuerra == trimmed) return;
    setState(() => _nomeGuerra = trimmed);
  }

  Future<void> _loadStats() async {
    if (DashboardController.isCacheFresh) {
      _statsData = DashboardController.cachedData!;
      return;
    }
    try {
      final data = await _dashboardController.loadDashboardData();
      if (mounted) {
        setState(() => _statsData = data);
      }
    } catch (e) {
      debugPrint('[Home] Error loading stats: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    final result = await VersionService.shouldShowUpdateBanner();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    if (result['shouldShow'] == true) {
      setState(() {
        _showUpdateBanner = true;
        _updateMessage = result['message'] ?? l10n.defaultUpdateMessage;
      });
    }
  }

  Future<void> _dismissUpdateBanner() async {
    await VersionService.markBannerAsSeen();
    setState(() => _showUpdateBanner = false);
  }

  Future<void> _checkNotificationSetupBanner() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      final data = doc.data();

      if (data?['notificationBannerDismissed'] == true) {
        if (mounted) setState(() => _showNotificationSetupBanner = false);
        return;
      }

      final hasFcmToken =
          (data?['fcmToken'] ?? '').toString().trim().isNotEmpty;
      final wantsAnyPush = _isAnyPushPreferenceEnabled(data);

      if (!mounted) return;
      setState(() {
        _showNotificationSetupBanner = wantsAnyPush && !hasFcmToken;
      });
    } catch (e) {
      debugPrint('[Home] Error checking notification setup: $e');
    }
  }

  Future<void> _dismissNotificationBannerPermanently() async {
    setState(() => _showNotificationSetupBanner = false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'notificationBannerDismissed': true},
      SetOptions(merge: true),
    );
  }

  bool _isAnyPushPreferenceEnabled(Map<String, dynamic>? data) {
    final pushNotifications = data?['pushNotifications'] as bool? ?? true;
    final pushNavSafety =
        data?['pushNavSafety'] as bool? ?? pushNotifications;
    final pushCrossing =
        data?['pushCruzamento'] as bool? ?? pushNotifications;

    return pushNotifications || pushNavSafety || pushCrossing;
  }

  Future<void> _requestNotificationSetup() async {
    if (_isRequestingNotificationSetup) return;

    setState(() => _isRequestingNotificationSetup = true);
    final granted = await NotificationService.requestPermissionAndEnable();
    if (!mounted) return;

    setState(() => _isRequestingNotificationSetup = false);

    if (granted) {
      await _checkNotificationSetupBanner();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notificationsEnabled),
          backgroundColor: const Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _dismissNotificationBannerPermanently();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.enableNotificationsMessage,
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _navigateToCrossing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrossingPage()),
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
          _cachedNomeGuerraByUid.clear();
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
            _buildNotificationSetupBanner(),
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _buildWelcomeText(),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildModuleCard(
                          icon: Icons.directions_boat,
                          iconBgColor: const Color(0x1F64B5F6),
                          iconBorderColor: const Color(0x3364B5F6),
                          iconColor: const Color(0xFF64B5F6),
                          borderColor: const Color(0x1A64B5F6),
                          title: AppLocalizations.of(context)!.shipRatingModule,
                          subtitle:
                              AppLocalizations.of(context)!.shipRatingDesc,
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
                            title:
                                AppLocalizations.of(context)!.navSafetyModule,
                            subtitle:
                                AppLocalizations.of(context)!.navSafetyDesc,
                            onTap: _navigateToNavSafety,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildModuleCard(
                          icon: Icons.compare_arrows,
                          iconBgColor: const Color(0x1FFFB74D),
                          iconBorderColor: const Color(0x40FFB74D),
                          iconColor: const Color(0xFFFFB74D),
                          borderColor: const Color(0x33FFB74D),
                          title: AppLocalizations.of(context)!.cruzamentoModule,
                          subtitle: AppLocalizations.of(context)!.cruzamentoDesc,
                          onTap: _navigateToCrossing,
                        ),
                      ],
                    ),
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
    final displayName = _nomeGuerra ?? l10n.defaultPilotName;

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

  Widget _buildStatsSection() {
    return _buildStatsCard(_statsData);
  }

  Widget _buildStatsCard(DashboardData data) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardAppStats.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatItem(
                Icons.directions_boat,
                data.totalShips.toString(),
                l10n.totalShipsLabel,
              ),
              _buildStatDivider(),
              _buildStatItem(
                Icons.star_outline,
                data.totalRatings.toString(),
                l10n.totalRatingsLabel,
              ),
              _buildStatDivider(),
              _buildStatItem(
                Icons.compare_arrows,
                data.totalCrossings.toString(),
                l10n.totalCrossingsLabel,
                iconColor: const Color(0xFFFFB74D),
              ),
              _buildStatDivider(),
              _buildStatItem(
                Icons.people,
                data.totalUsers.toString(),
                l10n.activePilotsLabel,
              ),
            ],
          ),
          if (data.topRaterCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.topRaterInfo(data.topRaterCount.toString()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    Color iconColor = const Color(0xFF64B5F6),
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
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


  Widget _buildNotificationSetupBanner() {
    if (!_showNotificationSetupBanner) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _isRequestingNotificationSetup ? null : _requestNotificationSetup,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0E3A3A),
            border: Border(
              bottom: BorderSide(color: Color(0x3326A69A)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF26A69A),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.enableNotificationsBanner,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isRequestingNotificationSetup)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF26A69A),
                  ),
                )
              else
                const Icon(
                  Icons.touch_app_outlined,
                  color: Color(0xB3FFFFFF),
                  size: 18,
                ),
              IconButton(
                onPressed: _dismissNotificationBannerPermanently,
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                splashRadius: 18,
                tooltip: AppLocalizations.of(context)!.close,
              ),
            ],
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
