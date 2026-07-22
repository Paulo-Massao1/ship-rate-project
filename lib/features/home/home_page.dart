// lib/features/home/home_page.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../crossing/crossing_page.dart';
import '../ratings/last_rated_page.dart';
import '../suggestions/suggestion_page.dart';
import 'main_screen_page.dart';
import '../nav_info/nav_info_page.dart';
import '../navigation_safety/nav_safety_page.dart';
import '../../data/services/notification_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/constants.dart';
import '../../core/module_access.dart';
import '../../data/services/milestone_service.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/milestone_overlay.dart';
import '../../main.dart';
import '../../core/app_cache.dart';
import '../../data/services/version_service.dart';
import '../../data/services/web_update_service.dart';
import '../../data/services/url_launcher_service.dart';

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

  static const String _appStoreUrl =
      'https://apps.apple.com/br/app/shiprate-pro/id6777518989';

  // ===========================================================================
  // STATE
  // ===========================================================================

  static bool _notificationsInitialized = false;
  static bool _milestoneCheckedThisSession = false;
  final _milestoneService = MilestoneService();
  OverlayEntry? _milestoneOverlayEntry;
  static final Map<String, String> _cachedNomeGuerraByUid = {};
  static const Duration _nomeGuerraServerTimeout = Duration(seconds: 4);
  bool _showUpdateBanner = false;
  bool _updateBannerDismissed = false;
  bool _isApplyingWebUpdate = false;
  String? _nomeGuerra = AppCache.nomeGuerra;
  bool _restrictedToCoreModules = false;
  bool _showNotificationSetupBanner = false;
  bool _isRequestingNotificationSetup = false;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  final _dashboardController = DashboardController();
  DashboardData _statsData =
      DashboardController.cachedData ??
      (AppCache.stats.values.any((v) => v > 0)
          ? DashboardData(
              totalShips: AppCache.stats['ships'] ?? 0,
              totalRatings: AppCache.stats['ratings'] ?? 0,
              totalCrossings: AppCache.stats['crossings'] ?? 0,
              totalUsers: AppCache.stats['pilots'] ?? 0,
              topRaterCount: AppCache.stats['topRaterCount'] ?? 0,
              userRatings: 0,
              userRankingPosition: 0,
              totalPilotsWhoRated: 0,
              userCrossingCount: 0,
              topCrosserCount: 0,
              userCrossingRanking: 0,
              totalCrossingPilots: 0,
              totalDepthRecords: 0,
              userDepthRecordCount: 0,
              topDepthContributorCount: 0,
              userDepthRanking: 0,
              totalDepthPilots: 0,
              recentRatings: const [],
            )
          : DashboardData.empty());

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshModuleAccess();
    _checkForUpdates();
    _fetchNomeGuerra();
    debugPrint('HOME: init with cached stats: ships=${_statsData.totalShips}, ratings=${_statsData.totalRatings}, crossings=${_statsData.totalCrossings}');
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingRoute();
      _initNotifications();
    });
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    _milestoneOverlayEntry?.remove();
    _milestoneOverlayEntry = null;
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

    _listenNotificationTapsIfSupported();
  }

  Future<void> _listenNotificationTapsIfSupported() async {
    if (!await NotificationService.isMessagingSupported()) return;
    if (!mounted || _notificationTapSubscription != null) return;

    _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        final type = message.data['type'] as String?;
        if (type == 'nav_safety' && !_restrictedToCoreModules) {
          _navigateToNavSafety();
        } else if (type == 'crossing') {
          _navigateToCrossing();
        }
      },
      onError: (Object error) {
        debugPrint('[Home] Notification tap listener error: $error');
      },
    );
  }

  void _refreshModuleAccess() {
    _restrictedToCoreModules = ModuleAccess.isCurrentUserRestricted;
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

  Future<void> _markNotificationPromptShown(String uid) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'notificationPromptShown': true},
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

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cached_nomeGuerra', trimmed);
    });

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
      _maybeShowMilestone();
      return;
    }
    try {
      final data = await _dashboardController.loadDashboardData();
      debugPrint('HOME: Firestore returned fresh stats: ships=${data.totalShips}, ratings=${data.totalRatings}, crossings=${data.totalCrossings}');
      if (mounted) {
        setState(() => _statsData = data);
        _maybeShowMilestone();
      }
    } catch (e) {
      debugPrint('[Home] Error loading stats: $e');
    }
  }

  /// Checks for an unseen milestone once per app session, after the dashboard
  /// stats have loaded, and shows the celebration overlay when one qualifies.
  Future<void> _maybeShowMilestone() async {
    if (_milestoneCheckedThisSession) return;
    _milestoneCheckedThisSession = true;

    final milestoneId = await _milestoneService.checkMilestones(
      _statsData.totalRatings,
      _statsData.totalUsers,
    );
    if (milestoneId == null || !mounted || _milestoneOverlayEntry != null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMilestoneOverlay(milestoneId);
    });
  }

  void _showMilestoneOverlay(String milestoneId) {
    final l10n = AppLocalizations.of(context)!;
    final String title;
    final String message;

    if (milestoneId == MilestoneService.milestone500Ratings) {
      title = l10n.milestone500RatingsTitle;
      message = l10n.milestone500RatingsMessage;
    } else if (milestoneId == MilestoneService.milestone100Users) {
      title = l10n.milestone100UsersTitle;
      message = l10n.milestone100UsersMessage;
    } else {
      return;
    }

    final entry = OverlayEntry(
      builder: (_) => MilestoneOverlay(
        title: title,
        message: message,
        onClose: () => _dismissMilestoneOverlay(milestoneId),
      ),
    );

    _milestoneOverlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _dismissMilestoneOverlay(String milestoneId) {
    _milestoneService.dismissMilestone(milestoneId);
    _milestoneOverlayEntry?.remove();
    _milestoneOverlayEntry = null;
  }

  Future<void> _checkForUpdates() async {
    if (_updateBannerDismissed || !_supportsUpdateBanner) return;

    final result = await VersionService.shouldShowUpdateBanner();
    if (!mounted || _updateBannerDismissed) return;

    setState(() => _showUpdateBanner = result['shouldShow'] == true);
  }

  bool get _supportsUpdateBanner {
    return kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _dismissUpdateBanner() {
    setState(() {
      _updateBannerDismissed = true;
      _showUpdateBanner = false;
    });
  }

  Future<void> _openAppStore() async {
    await UrlLauncherService.openExternalUrl(_appStoreUrl);
  }

  Future<void> _applyWebUpdate() async {
    if (_isApplyingWebUpdate) return;

    setState(() => _isApplyingWebUpdate = true);
    await WebUpdateService.applyUpdate();

    if (!mounted) return;
    setState(() => _isApplyingWebUpdate = false);
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
  // DRAWER ACTIONS
  // ===========================================================================

  void _navigateToSuggestions() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SuggestionPage()),
    );
  }

  void _toggleLocale() {
    Navigator.pop(context);
    final next = localeController.locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    localeController.changeLocale(next);
  }

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

  void _shareViaWhatsApp() {
    Navigator.pop(context);
    final l10n = AppLocalizations.of(context)!;
    UrlLauncherService.openWhatsAppShare(l10n.shareText);
  }

  Future<void> _copyLinkToClipboard() async {
    Navigator.pop(context);
    await Clipboard.setData(const ClipboardData(text: _appStoreUrl));

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

  void _navigateToShipRating() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    ).then((_) {
      DashboardController.invalidateCache();
      _loadStats();
    });
  }

  void _navigateToNavSafety() {
    if (_restrictedToCoreModules) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyPage()),
    ).then((_) {
      DashboardController.invalidateCache();
      _loadStats();
    });
  }

  void _navigateToCrossing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrossingPage()),
    ).then((_) {
      DashboardController.invalidateCache();
      _loadStats();
    });
  }

  void _navigateToNavInfo() {
    if (_restrictedToCoreModules) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavInfoPage()),
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
        showNavSafety: !_restrictedToCoreModules,
        showNavInfo: !_restrictedToCoreModules,
        onBeforeLogout: () {
          _notificationsInitialized = false;
          _cachedNomeGuerraByUid.clear();
        },
        bottomItems: [
          DrawerItem(
            icon: Icons.lightbulb_outline,
            label: AppLocalizations.of(context)!.drawerSendSuggestion,
            onTap: _navigateToSuggestions,
          ),
          DrawerItem(
            icon: Icons.share,
            label: AppLocalizations.of(context)!.drawerShareApp,
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
                        if (!_restrictedToCoreModules) ...[
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
                        if (!_restrictedToCoreModules) ...[
                          const SizedBox(height: 16),
                          _buildModuleCard(
                            icon: Icons.explore,
                            iconBgColor: const Color(0x1FB388FF),
                            iconBorderColor: const Color(0x26B388FF),
                            iconColor: const Color(0xFFB388FF),
                            borderColor: const Color(0x26B388FF),
                            title: AppLocalizations.of(context)!.navInfoModule,
                            subtitle: AppLocalizations.of(context)!.navInfoDesc,
                            onTap: _navigateToNavInfo,
                          ),
                        ],
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LastRatedPage()),
                ),
              ),
              _buildStatDivider(),
              _buildStatItem(
                Icons.star_outline,
                data.totalRatings.toString(),
                l10n.totalRatingsLabel,
                onTap: _showRatingsRankingSheet,
              ),
              _buildStatDivider(),
              _buildStatItem(
                Icons.compare_arrows,
                data.totalCrossings.toString(),
                l10n.totalCrossingsLabel,
                iconColor: const Color(0xFFFFB74D),
                onTap: _showCrossingsRankingSheet,
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
    VoidCallback? onTap,
  }) {
    final content = Column(
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: content)
          : content,
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
    );
  }

  // ===========================================================================
  // STAT RANKINGS
  // ===========================================================================

  void _showRatingsRankingSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showStatRankingSheet(
      title: l10n.ratingsRankingTitle,
      future: _fetchRatingsRanking(),
      countLabel: l10n.ratingsRankingCount,
    );
  }

  void _showCrossingsRankingSheet() {
    final l10n = AppLocalizations.of(context)!;
    _showStatRankingSheet(
      title: l10n.crossingsRankingTitle,
      future: _fetchCrossingsRanking(),
      countLabel: l10n.crossingsRankingCount,
    );
  }

  /// Fetches per-pilot rating counts, mirroring the dashboard's attribution
  /// rules (realPilotId/realPilotIds override, uid or callSign fallback).
  Future<List<_StatRankingEntry>> _fetchRatingsRanking() async {
    final firestore = FirebaseFirestore.instance;
    final countsByPilot = <String, int>{};

    final shipsSnapshot =
        await firestore.collection(AppConstants.shipsCollection).get();

    final ratingsSnapshots = await Future.wait(
      shipsSnapshot.docs.map(
        (ship) => ship.reference
            .collection(AppConstants.ratingsSubcollection)
            .get()
            .then<QuerySnapshot<Map<String, dynamic>>?>((snapshot) => snapshot)
            .catchError((Object _) => null),
      ),
    );

    for (final snapshot in ratingsSnapshots) {
      if (snapshot == null) continue;
      for (final rating in snapshot.docs) {
        final data = rating.data();
        final ratingUid = data['usuarioId'] as String?;
        final realPilotId = data['realPilotId'] as String?;
        final realPilotIds = data['realPilotIds'] as List<dynamic>?;

        if (realPilotId != null) {
          countsByPilot[realPilotId] = (countsByPilot[realPilotId] ?? 0) + 1;
        } else if (realPilotIds != null && realPilotIds.isNotEmpty) {
          for (final id in realPilotIds) {
            final key = id as String;
            countsByPilot[key] = (countsByPilot[key] ?? 0) + 1;
          }
        } else if (ratingUid != AppConstants.cspamUid) {
          final pilotKey = ratingUid ?? (data['nomeGuerra'] as String?) ?? '';
          if (pilotKey.isNotEmpty) {
            countsByPilot[pilotKey] = (countsByPilot[pilotKey] ?? 0) + 1;
          }
        }
      }
    }

    countsByPilot.remove(AppConstants.cspamUid);
    return _buildRankingEntries(countsByPilot);
  }

  /// Fetches per-pilot crossing counts from pre-aggregated pilot stats, with
  /// a fallback that groups raw crossing records when counters are missing.
  Future<List<_StatRankingEntry>> _fetchCrossingsRanking() async {
    final firestore = FirebaseFirestore.instance;
    final countsByPilot = <String, int>{};

    try {
      final statsSnapshot = await firestore
          .collection(AppConstants.pilotStatsCollection)
          .where('crossingCount', isGreaterThan: 0)
          .get();
      for (final doc in statsSnapshot.docs) {
        if (doc.id == AppConstants.cspamUid) continue;
        final count = (doc.data()['crossingCount'] as int?) ?? 0;
        if (count > 0) countsByPilot[doc.id] = count;
      }
    } catch (e) {
      debugPrint('[Home] Error fetching pilot crossing counts: $e');
    }

    if (countsByPilot.isEmpty) {
      final crossingsSnapshot =
          await firestore.collection(AppConstants.cruzamentosCollection).get();
      for (final doc in crossingsSnapshot.docs) {
        final pilotKey = _resolveCrossingPilotKey(doc.data());
        if (pilotKey == null || pilotKey == AppConstants.cspamUid) continue;
        countsByPilot[pilotKey] = (countsByPilot[pilotKey] ?? 0) + 1;
      }
    }

    return _buildRankingEntries(countsByPilot);
  }

  String? _resolveCrossingPilotKey(Map<String, dynamic> data) {
    for (final field in [
      'pilotoId',
      'pilotId',
      'usuarioId',
      'userId',
      'nomeGuerra',
    ]) {
      final value = data[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Applies the ranking-only dev-account exclusions and maps counts to
  /// sorted, tie-aware ranking entries.
  Future<List<_StatRankingEntry>> _buildRankingEntries(
    Map<String, int> countsByPilot,
  ) async {
    final excludedKeys = await _fetchRankingExcludedKeys();
    excludedKeys.forEach(countsByPilot.remove);

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final callSign = _nomeGuerra?.trim();
    bool isCurrentUser(String key) =>
        key == currentUid ||
        (callSign != null && callSign.isNotEmpty && key == callSign);

    final sorted = countsByPilot.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final counts = sorted.map((e) => e.value).toList();

    return [
      for (final entry in sorted)
        _StatRankingEntry(
          position: counts.where((c) => c > entry.value).length + 1,
          count: entry.value,
          isCurrentUser: isCurrentUser(entry.key),
          name: isCurrentUser(entry.key) ? (callSign ?? '') : '',
        ),
    ];
  }

  /// Resolves uid and callSign keys for the dev accounts excluded from
  /// every ranking, mirroring the dashboard's exclusion lookup.
  Future<Set<String>> _fetchRankingExcludedKeys() async {
    final excluded = <String>{};
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('email', whereIn: AppConstants.excludedFromRankings)
          .get();
      for (final doc in snapshot.docs) {
        excluded.add(doc.id);
        final callSign = (doc.data()['nomeGuerra'] as String?)?.trim();
        if (callSign != null && callSign.isNotEmpty) excluded.add(callSign);
      }
    } catch (e) {
      debugPrint('[Home] Error resolving ranking exclusions: $e');
    }
    return excluded;
  }

  Future<void> _showStatRankingSheet({
    required String title,
    required Future<List<_StatRankingEntry>> future,
    required String Function(int) countLabel,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF132D4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FutureBuilder<List<_StatRankingEntry>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
                    ),
                  );
                }

                final entries = snapshot.data ?? const <_StatRankingEntry>[];
                if (entries.isEmpty) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        l10n.noRecords,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0x3364B5F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Color(0xFF64B5F6),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, index) => _buildStatRankingRow(
                            entries[index],
                            l10n,
                            countLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRankingRow(
    _StatRankingEntry entry,
    AppLocalizations l10n,
    String Function(int) countLabel,
  ) {
    final isUser = entry.isCurrentUser;
    final label = isUser
        ? (entry.name.isNotEmpty
            ? '${l10n.rankingYou} (${entry.name})'
            : l10n.rankingYou)
        : l10n.pilot;
    const accent = Color(0xFF64B5F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUser
            ? accent.withValues(alpha: 0.12)
            : const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUser ? accent : const Color(0x1A64B5F6),
          width: isUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.position}',
              style: TextStyle(
                color: isUser ? accent : const Color(0x99FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUser ? accent : const Color(0xD9FFFFFF),
                fontSize: 13,
                fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            countLabel(entry.count),
            style: TextStyle(
              color: isUser ? accent : const Color(0x99FFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final message = kIsWeb
        ? l10n.updateAvailableWeb
        : l10n.updateAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x4064B5F6), Color(0x1A64B5F6)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x6664B5F6)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.system_update,
            color: Color(0xFF64B5F6),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          TextButton(
            onPressed: kIsWeb
                ? (_isApplyingWebUpdate ? null : _applyWebUpdate)
                : _openAppStore,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64B5F6),
            ),
            child: Text(
              l10n.updateButton,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _dismissUpdateBanner,
            icon: const Icon(Icons.close, color: Colors.white70, size: 19),
            tooltip: l10n.close,
          ),
        ],
      ),
    );
  }
}

/// Single row of an anonymous stat ranking (ratings or crossings).
class _StatRankingEntry {
  final int position;
  final int count;
  final bool isCurrentUser;
  final String name;

  const _StatRankingEntry({
    required this.position,
    required this.count,
    required this.isCurrentUser,
    required this.name,
  });
}

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
