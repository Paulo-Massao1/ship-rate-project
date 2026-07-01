import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../controllers/crossing_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/url_launcher_service.dart';
import '../../main.dart';
import '../../shared/widgets/app_drawer.dart';
import '../suggestions/suggestion_page.dart';
import 'crossing_form_page.dart';

enum _CrossingTab { active, mine }

class CrossingPage extends StatefulWidget {
  const CrossingPage({super.key});

  @override
  State<CrossingPage> createState() => _CrossingPageState();
}

class _CrossingPageState extends State<CrossingPage> {
  static const _amber = Color(0xFFFFB74D);
  static const _amberLight = Color(0x1AFFB74D);
  static const _amberBorder = Color(0x40FFB74D);

  final CrossingController _controller = CrossingController();
  final DashboardController _dashboardController = DashboardController();
  DashboardData? _crossingStats;

  _CrossingTab _selectedTab = _CrossingTab.active;
  bool _pushEnabled = true;
  bool _isLoadingPush = true;
  DateTime? _pushExpiryDate;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    _crossingStats =
        DashboardController.cachedCrossingData ?? DashboardController.cachedData;
    final cachedStats =
        await DashboardController.loadCachedCrossingDashboardData();
    if (mounted && cachedStats != null) {
      setState(() => _crossingStats = cachedStats);
    }
    _loadCrossingStats();
    await Future.wait([
      _controller.fetchActiveCrossings(),
      _loadPushPreference(),
    ]);
  }

  Future<void> _loadCrossingStats({bool force = false}) async {
    if (!force &&
        DashboardController.isCrossingCacheFresh &&
        _crossingStats != null) {
      return;
    }
    try {
      final data = await _dashboardController.loadCrossingDashboardData();
      if (mounted) {
        setState(() => _crossingStats = data);
      }
    } catch (e) {
      debugPrint('[Crossing] Error loading crossing stats: $e');
    }
  }

  Future<void> _loadPushPreference() async {
    final results = await Future.wait([
      _controller.isCrossingPushEnabled(),
      _controller.getCrossingPushExpiryDate(),
    ]);
    if (!mounted) return;

    final enabled = results[0] as bool;
    final savedExpiryDate = results[1] as DateTime?;
    final expiryDate = enabled
        ? (savedExpiryDate ?? _defaultPushExpiryDate())
        : null;

    setState(() {
      _pushEnabled = enabled;
      _pushExpiryDate = expiryDate;
      _isLoadingPush = false;
    });
  }

  Future<void> _refreshCrossings() async {
    DashboardController.invalidateCache();
    await Future.wait([
      _loadCurrentCrossingList(),
      _loadCrossingStats(force: true),
    ]);
  }

  Future<void> _loadCurrentCrossingList() {
    return _selectedTab == _CrossingTab.active
        ? _controller.fetchActiveCrossings()
        : _controller.fetchMyCrossings();
  }

  Future<void> _togglePushAlerts(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (value) {
      final alreadyGranted = await NotificationService.isPermissionGranted();
      if (!alreadyGranted) {
        final granted = await NotificationService.requestPermissionAndEnable();
        if (!granted) {
          _showSnackBar(l10n.notificationPermissionDenied, isError: true);
          return;
        }
      }
    }

    final expiryDate = value
        ? (_pushExpiryDate != null && _pushExpiryDate!.isAfter(DateTime.now())
            ? _pushExpiryDate!
            : _defaultPushExpiryDate())
        : null;

    setState(() {
      _pushEnabled = value;
      _pushExpiryDate = expiryDate;
    });
    await _controller.setCrossingPushEnabled(value, expiryDate: expiryDate);
  }

  Future<void> _pickPushExpiryDate() async {
    final initialDate = _toBrasilia(_pushExpiryDate) ??
        _currentBrasiliaDate().add(const Duration(days: 7));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _currentBrasiliaDate(),
      lastDate: _currentBrasiliaDate().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _amber,
              surface: Color(0xFF0D2137),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final expiryDate = _endOfBrasiliaDay(pickedDate);

    setState(() => _pushExpiryDate = expiryDate);
    await _controller.setCrossingPushEnabled(
      true,
      expiryDate: expiryDate,
    );
  }

  DateTime _defaultPushExpiryDate() {
    return _endOfBrasiliaDay(
      _currentBrasiliaDate().add(const Duration(days: 7)),
    );
  }

  DateTime _currentBrasiliaDate() {
    final brasiliaNow = DateTime.now().toUtc().subtract(
          const Duration(hours: 3),
        );
    return DateTime(brasiliaNow.year, brasiliaNow.month, brasiliaNow.day);
  }

  DateTime _endOfBrasiliaDay(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day, 23, 59, 59).add(
      const Duration(hours: 3),
    );
  }

  Future<void> _navigateToNewCrossing() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrossingFormPage()),
    );

    if (created == true) {
      await _refreshCrossings();
    }
  }

  void _showMyCrossingsFromDrawer() {
    Navigator.pop(context);
    _showMyCrossings();
  }

  void _showActiveCrossings() {
    setState(() => _selectedTab = _CrossingTab.active);
    _controller.fetchActiveCrossings();
  }

  void _showMyCrossings() {
    setState(() => _selectedTab = _CrossingTab.mine);
    _controller.fetchMyCrossings();
  }

  Future<void> _navigateToEditCrossing(Map<String, dynamic> crossing) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CrossingFormPage(crossing: crossing),
      ),
    );

    if (updated == true) {
      await _refreshCrossings();
    }
  }

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
      builder: (_) => _CrossingShareBottomSheet(
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

  Future<void> _confirmDelete(Map<String, dynamic> crossing) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF132D4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.deleteRecordTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.deleteRecordConfirm,
          style: const TextStyle(color: Color(0xD9FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final docId = (crossing['id'] ?? '').toString();
    if (docId.isEmpty) return;

    await _controller.deleteCrossing(docId);
    await _refreshCrossings();
    if (!mounted) return;

    _showSnackBar(l10n.recordDeletedSuccess, isError: false);
  }

  Future<void> _shareCrossing(Map<String, dynamic> crossing) async {
    final l10n = AppLocalizations.of(context)!;
    final location = (crossing['local'] ?? '').toString().trim();
    final shipName = (crossing['nomeNavio'] ?? '').toString().trim();
    final direction = _directionLabel(crossing['direcao']?.toString(), l10n);
    final draft = _draftLabel(crossing['calado']?.toString(), l10n);
    final pilotsToContact = (crossing['praticosContato'] ?? '').toString().trim();
    final formattedTime = _formatBrasiliaDateTimeLong(
      _toBrasilia(_resolveDateTime(crossing['dataHora'])),
    );
    final contactLine = pilotsToContact.isEmpty
        ? ''
        : '\n\u{1F4DE} ${l10n.pilotsToContact}: $pilotsToContact';

    final shareText =
        '\u2693 ${l10n.cruzamentoModule}\n'
        '\u{1F4CD} ${l10n.crossingLocation}: $location\n'
        '\u{1F550} ${l10n.crossingTime}: $formattedTime\n'
        '\u{1F6A2} ${l10n.crossingShipName}: $shipName\n'
        '\u2693 ${l10n.draftLabel}: $draft\n'
        '\u2195\uFE0F $direction'
        '$contactLine\n\n'
        '${l10n.shareDepthFooter}\n'
        '${AppConstants.appUrl}';

    await UrlLauncherService.openWhatsAppShare(shareText);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade800 : const Color(0xFF1B5E20),
      ),
    );
  }

  List<Map<String, dynamic>> get _sortedCrossings {
    final items = List<Map<String, dynamic>>.from(_controller.crossings);
    items.sort((a, b) {
      final aDate = _resolveDateTime(a['dataHora']);
      final bDate = _resolveDateTime(b['dataHora']);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return items;
  }

  List<Map<String, dynamic>> get _myCrossings {
    return _controller.myCrossings;
  }

  bool get _showCrossingStats => _crossingStats != null;

  bool get _showCrossingRanking =>
      _crossingStats != null &&
      _crossingRankingTotal > 0;

  int get _crossingRankingPosition {
    final data = _crossingStats!;
    final total = _crossingRankingTotal;
    final position = data.userCrossingRanking > 0
        ? data.userCrossingRanking
        : data.totalCrossingPilots > 0
            ? data.totalCrossingPilots + 1
            : total;
    return position > total ? total : position;
  }

  int get _crossingRankingTotal {
    final data = _crossingStats!;
    return data.totalUsers > 0 ? data.totalUsers : data.totalCrossingPilots;
  }

  bool get _showNavSafetyModule {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return !email.toLowerCase().endsWith('@cspam.com.br');
  }

  DateTime? _resolveDateTime(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is Timestamp) return value.toDate().toUtc();
    return null;
  }

  DateTime? _toBrasilia(DateTime? value) {
    if (value == null) return null;
    final brasilia = value.toUtc().subtract(const Duration(hours: 3));
    return DateTime(
      brasilia.year,
      brasilia.month,
      brasilia.day,
      brasilia.hour,
      brasilia.minute,
    );
  }

  String _formatBrasiliaDateTimeShort(DateTime? value, AppLocalizations l10n) {
    if (value == null) return l10n.notAvailable;

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String _formatBrasiliaDateTimeLong(DateTime? value) {
    if (value == null) return '';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  String _directionLabel(String? value, AppLocalizations l10n) {
    switch (value?.toLowerCase()) {
      case 'subindo':
        return l10n.directionUp;
      case 'baixando':
        return l10n.directionDown;
      default:
        return l10n.notAvailable;
    }
  }

  String _draftLabel(String? value, AppLocalizations l10n) {
    switch (value) {
      case 'ate_6_5':
        return l10n.draftUpTo65;
      case '6_5_a_9_5':
        return l10n.draft65To95;
      case 'acima_9_5':
        return l10n.draftAbove95;
      default:
        return l10n.notAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.cruzamentoModule,
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
              colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      drawer: AppDrawer(
        currentScreen: AppScreen.crossing,
        showNavSafety: _showNavSafetyModule,
        additionalItems: [
          DrawerItem(
            icon: Icons.assignment_turned_in_outlined,
            label: l10n.myCrossings,
            onTap: _showMyCrossingsFromDrawer,
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
                Padding(
                  padding: EdgeInsets.only(
                    top: Navigator.canPop(context) ? 44 : 0,
                  ),
                  child: Column(
                    children: [
                      if (_showCrossingStats) _buildCrossingStatsCard(l10n),
                      _buildAlertToggle(l10n),
                      if (_showCrossingStats) _buildMotivationalMessage(l10n),
                      _buildTabPills(l10n),
                      Expanded(child: _buildBody(l10n)),
                    ],
                  ),
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

  Widget _buildAlertToggle(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amberLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x26FFB74D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: _amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.receiveAlerts,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pushEnabled ? l10n.yes : l10n.no,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _pushEnabled,
                onChanged: _isLoadingPush ? null : _togglePushAlerts,
                activeColor: _amber,
                activeTrackColor: const Color(0x66FFB74D),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white24,
              ),
            ],
          ),
          if (_pushEnabled) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickPushExpiryDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x141A2E45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _amberBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: _amber,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${l10n.alertsActiveUntil} '
                        '${_formatDate(_toBrasilia(_pushExpiryDate))}',
                        style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      l10n.selectEndDate,
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabPills(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildPill(
            label: l10n.activeCrossings,
            isActive: _selectedTab == _CrossingTab.active,
            onTap: _showActiveCrossings,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.newCrossing,
            isActive: false,
            onTap: _navigateToNewCrossing,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.myCrossings,
            isActive: _selectedTab == _CrossingTab.mine,
            onTap: _showMyCrossings,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _amberLight : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _amberBorder : const Color(0x1F64B5F6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _amber : const Color(0x99FFFFFF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final items = _selectedTab == _CrossingTab.active
        ? _sortedCrossings
        : _myCrossings;

    if (_controller.isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _amber),
      );
    }

    return RefreshIndicator(
      color: _amber,
      onRefresh: _refreshCrossings,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 96),
                _buildEmptyState(l10n),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '\u{1F550} ${l10n.crossingTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  );
                }

                final crossing = items[index - 1];
                return _buildCrossingCard(
                  crossing,
                  l10n,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amberBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _amberLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.compare_arrows,
              color: _amber,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.noCrossings,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossingStatsCard(AppLocalizations l10n) {
    final data = _crossingStats!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, color: _amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.crossingStatsCount(
                    data.userCrossingCount,
                    data.totalCrossings,
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_showCrossingRanking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 16, color: _amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.crossingRankingPosition(
                      _crossingRankingPosition,
                      _crossingRankingTotal,
                    ),
                    style: const TextStyle(
                      color: _amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage(AppLocalizations l10n) {
    final data = _crossingStats!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amberBorder),
      ),
      child: Text(
        l10n.crossingsMotivational(data.totalCrossings),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCrossingCard(
    Map<String, dynamic> crossing,
    AppLocalizations l10n,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnCrossing = crossing['pilotoId'] == currentUid;
    final shipName = (crossing['nomeNavio'] ?? '').toString().trim();
    final location = (crossing['local'] ?? '').toString().trim();
    final pilotName = (crossing['nomeGuerra'] ?? '').toString().trim();
    final pilotsToContact = (crossing['praticosContato'] ?? '').toString().trim();
    final observations = (crossing['observacoes'] ?? '').toString().trim();
    final draft = _draftLabel(crossing['calado']?.toString(), l10n);
    final formattedTime = _formatBrasiliaDateTimeShort(
      _toBrasilia(_resolveDateTime(crossing['dataHora'])),
      l10n,
    );
    final direction = _directionLabel(crossing['direcao']?.toString(), l10n);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  shipName.isEmpty ? l10n.notAvailable : shipName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shareCrossing(crossing),
                icon: const Icon(
                  Icons.message,
                  color: Color(0xFF25D366),
                ),
                tooltip: l10n.shareCrossing,
                splashRadius: 18,
              ),
              if (isOwnCrossing)
                IconButton(
                  onPressed: () => _navigateToEditCrossing(crossing),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: _amber,
                  ),
                  tooltip: l10n.editRecord,
                  splashRadius: 18,
                ),
              if (isOwnCrossing)
                IconButton(
                  onPressed: () => _confirmDelete(crossing),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF5350),
                  ),
                  tooltip: l10n.deleteRecord,
                  splashRadius: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoLine(Icons.place_outlined, l10n.crossingLocation, location, l10n),
          const SizedBox(height: 8),
          _buildInfoLine(
            Icons.schedule_outlined,
            l10n.crossingTime,
            formattedTime,
            l10n,
          ),
          const SizedBox(height: 8),
          _buildInfoLine(
            Icons.anchor_outlined,
            l10n.draftLabel,
            draft,
            l10n,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _amberLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _amberBorder),
                ),
                child: Text(
                  direction,
                  style: const TextStyle(
                    color: _amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${l10n.pilot}: ${pilotName.isEmpty ? l10n.notAvailable : pilotName}',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.pilotsToContact}: '
            '${pilotsToContact.isEmpty ? l10n.notAvailable : pilotsToContact}',
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 13,
            ),
          ),
          if (observations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.crossingObservations}: $observations',
              style: const TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoLine(
    IconData icon,
    String label,
    String value,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _amber, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value.isEmpty ? l10n.notAvailable : value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CrossingShareBottomSheet extends StatelessWidget {
  final VoidCallback onWhatsAppTap;
  final VoidCallback onCopyLinkTap;

  const _CrossingShareBottomSheet({
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
                  label: l10n.shareCrossing,
                  color: const Color(0xFF25D366),
                  onTap: onWhatsAppTap,
                ),
                _ShareOption(
                  icon: Icons.link,
                  label: l10n.copyLink,
                  color: const Color(0xFFFFB74D),
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
                color: color.withValues(alpha: 0.12),
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
