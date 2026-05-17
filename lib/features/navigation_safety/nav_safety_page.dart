import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/nav_safety_controller.dart';
import '../home/main_screen_page.dart';
import '../settings/settings_page.dart';
import 'nav_safety_my_records_page.dart';
import 'nav_safety_new_record_page.dart';
import 'nav_safety_record_detail_page.dart';

/// Main screen for the Navigation Safety module.
class NavSafetyPage extends StatefulWidget {
  const NavSafetyPage({super.key});

  @override
  State<NavSafetyPage> createState() => _NavSafetyPageState();
}

class _NavSafetyPageState extends State<NavSafetyPage> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final NavSafetyController _controller = NavSafetyController();
  bool _showLocationsDropdown = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.fetchLocationsWithLatestRecord();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _onLocationTap(String id, String name) {
    _showLocationsDropdown = false;
    _controller.fetchLocationHistory(id, name);
  }

  void _navigateToNewRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyNewRecordPage()),
    ).then((_) {
      _controller.fetchLocationsWithLatestRecord();
    });
  }

  void _navigateToMyRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyMyRecordsPage()),
    ).then((_) {
      _controller.fetchLocationsWithLatestRecord();
    });
  }

  void _navigateToRecordDetails(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavSafetyRecordDetailPage(
          locationName: _controller.selectedLocationName ?? '',
          record: record,
        ),
      ),
    );
  }

  void _toggleLocationsDropdown() {
    setState(() {
      _showLocationsDropdown = !_showLocationsDropdown;
    });
  }

  Future<void> _handleLogout() async {
    NavSafetyController.clearAllCaches();
    await FirebaseAuth.instance.signOut();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      drawer: _buildDrawer(l10n),
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
            child: Column(
              children: [
                _buildTabPills(l10n),
                Expanded(child: _buildBody(l10n)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0x2664B5F6), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x2626A69A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.anchor, size: 32, color: Color(0xFF26A69A)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.navSafetyModule,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.directions_boat,
                        label: l10n.shipRatingModule,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MainScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.anchor,
                        label: l10n.navSafetyModule,
                        isActive: true,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildDrawerItem(
                        icon: Icons.assignment_turned_in_outlined,
                        label: l10n.drawerMyRecords,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToMyRecords();
                        },
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
                            _buildDrawerItem(
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
                            _buildDrawerItem(
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isActive = false,
  }) {
    final textColor = isActive ? const Color(0xFF26A69A) : (color ?? const Color(0xD9FFFFFF));
    final iconColor = isActive ? const Color(0xFF26A69A) : (color ?? Colors.white.withValues(alpha: 0.7));

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

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.navSafetyModule,
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
    );
  }

  Widget _buildTabPills(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildPill(
            label: l10n.latestDepths,
            isActive:
                _controller.selectedLocationId == null && !_showLocationsDropdown,
            onTap: () {
              setState(() => _showLocationsDropdown = false);
              _controller.clearSelection();
            },
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.locations,
            isActive: _showLocationsDropdown,
            trailing: const Icon(
              Icons.arrow_drop_down,
              color: Color(0x99FFFFFF),
              size: 18,
            ),
            onTap: _toggleLocationsDropdown,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.newRecord,
            isActive: false,
            onTap: _navigateToNewRecord,
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.myRecords,
            isActive: false,
            onTap: _navigateToMyRecords,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isActive,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0x2626A69A) : const Color(0x0FFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0x6626A69A) : const Color(0x1F64B5F6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    isActive ? const Color(0xFF26A69A) : const Color(0x99FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 2), trailing],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_showLocationsDropdown) {
      return _buildLocationsDropdown(l10n);
    }

    if (_controller.selectedLocationId != null) {
      return _buildLocationHistory(l10n);
    }

    return _buildLatestDepths(l10n);
  }

  // ===========================================================================
  // TAB 1 - LATEST DEPTHS
  // ===========================================================================

  Widget _buildLatestDepths(AppLocalizations l10n) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF26A69A)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '\u{1F550} ${l10n.latestDepthsRegistered}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0x99FFFFFF),
            ),
          ),
        ),
        ..._controller.locations.map((loc) => _buildLocationCard(loc, l10n)),
      ],
    );
  }

  Widget _buildLocationCard(LocationWithLatestRecord loc, AppLocalizations l10n) {
    final latestRecord = loc.latestRecord;
    final latestRecordId = latestRecord?['recordId'] as String?;
    final recordPilotId = latestRecord?['pilotId'] as String?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnRecord = recordPilotId != null && recordPilotId == currentUid;
    final liked = latestRecordId != null
        ? _controller.hasUserLiked(loc.id, latestRecordId)
        : false;
    final serverLikeCount = latestRecord?['likeCount'] as int? ?? 0;
    final cachedLikeCount = latestRecordId != null
        ? _controller.getLikeCount(loc.id, latestRecordId)
        : 0;
    final likeCount =
        cachedLikeCount > 0 ? cachedLikeCount : serverLikeCount;
    final likerNames = latestRecordId != null
        ? _controller.getLikerNames(loc.id, latestRecordId)
        : const <String>[];
    final likedByText = _formatLikedByText(likerNames, likeCount, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onLocationTap(loc.id, loc.name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A64B5F6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              l10n.totalDepthShort,
                              style: const TextStyle(
                                color: Color(0x66FFFFFF),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatMeters(loc.latestDepth),
                              style: const TextStyle(
                                color: Color(0xFF26A69A),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.latestDateFormatted ?? l10n.noRecords,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 13,
                        ),
                      ),
                      if (loc.latestPilotName != null && loc.latestPilotName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n.pilotCallSign(loc.latestPilotName!),
                          style: const TextStyle(
                            color: Color(0x66FFFFFF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (latestRecordId != null && (!isOwnRecord || likeCount > 0)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!isOwnRecord)
                              GestureDetector(
                                onTap: () {
                                  _controller.toggleLike(loc.id, latestRecordId);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        liked
                                            ? Icons.thumb_up
                                            : Icons.thumb_up_outlined,
                                        size: 16,
                                        color: liked
                                            ? const Color(0xFF26A69A)
                                            : const Color(0x66FFFFFF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$likeCount',
                                        style: const TextStyle(
                                          color: Color(0x99FFFFFF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (isOwnRecord && likeCount > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.thumb_up,
                                      size: 16,
                                      color: Color(0xFF26A69A),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$likeCount',
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (likedByText.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showLikersSheet(
                                    loc.id,
                                    latestRecordId,
                                    l10n,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      likedByText,
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0x66FFFFFF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2 - LOCATIONS DROPDOWN
  // ===========================================================================

  Widget _buildLocationsDropdown(AppLocalizations l10n) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF26A69A)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF132D4A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x3326A69A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _controller.locations.length,
            itemBuilder: (context, index) {
              final loc = _controller.locations[index];
              return InkWell(
                onTap: () => _onLocationTap(loc.id, loc.name),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    border: index < _controller.locations.length - 1
                        ? const Border(
                            bottom: BorderSide(color: Color(0x0DFFFFFF)),
                          )
                        : null,
                  ),
                  child: Text(
                    '\u{1F4CD} ${loc.name}',
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOCATION HISTORY VIEW
  // ===========================================================================

  Widget _buildLocationHistory(AppLocalizations l10n) {
    if (_controller.isLoadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF26A69A)),
      );
    }

    final records = _controller.locationRecords;
    final latestDepth = records.isNotEmpty
        ? _formatMeters(records.first['profundidadeTotal'])
        : '—';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSummaryCard(l10n, latestDepth),
        const SizedBox(height: 16),
        Text(
          l10n.history,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                l10n.noRecords,
                style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
              ),
            ),
          )
        else
          ...records.map((record) => _buildRecordCard(record, l10n)),
      ],
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n, String latestDepth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x1426A69A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3326A69A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.selectedLocationName ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Text(
                  l10n.lastDepth,
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  latestDepth,
                  style: const TextStyle(
                    color: Color(0xFF26A69A),
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, AppLocalizations l10n) {
    final pilotName = (record['nomeGuerra'] ?? '').toString();
    final shipName = (record['nomeNavio'] ?? '').toString();
    final profTotal = record['profundidadeTotal'];
    final caladoMax = record['caladoMax']?.toString() ?? '—';
    final ukc = record['ukc']?.toString() ?? '—';
    final direction = _formatDirection(record['direcao']?.toString(), l10n);
    final dateStr = _formatDate(record['data']);

    final recordId = record['recordId'] as String?;
    final recordPilotId = record['pilotId'] as String?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnRecord = recordPilotId != null && recordPilotId == currentUid;
    final locationId = _controller.selectedLocationId;

    final bool liked = (locationId != null && recordId != null)
        ? _controller.hasUserLiked(locationId, recordId)
        : false;
    final int likeCount = (locationId != null && recordId != null)
        ? _controller.getLikeCount(locationId, recordId)
        : 0;
    final likerNames = (locationId != null && recordId != null)
        ? _controller.getLikerNames(locationId, recordId)
        : <String>[];
    final likedByText = _formatLikedByText(likerNames, likeCount, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRecordDetails(record),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A64B5F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pilotName.isNotEmpty ? l10n.pilotCallSign(pilotName) : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (shipName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Navio: $shipName',
                      style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x1426A69A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x2626A69A)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.totalDepth,
                        style: const TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatMeters(profTotal),
                        style: const TextStyle(
                          color: Color(0xFF26A69A),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatColumn(l10n.maxDraft, caladoMax),
                    _buildStatColumn(l10n.ukc, ukc),
                    _buildStatColumn(l10n.direction, direction),
                  ],
                ),
                if (locationId != null && recordId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x1A64B5F6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: isOwnRecord
                              ? null
                              : () {
                                  _controller.toggleLike(locationId, recordId);
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  liked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  size: 19,
                                  color: liked
                                      ? const Color(0xFF26A69A)
                                      : const Color(0x66FFFFFF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$likeCount',
                                  style: const TextStyle(
                                    color: Color(0x99FFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (likedByText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLikersSheet(
                                locationId,
                                recordId,
                                l10n,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  likedByText,
                                  style: const TextStyle(
                                    color: Color(0x99FFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatLikedByText(
    List<String> names,
    int totalCount,
    AppLocalizations l10n,
  ) {
    if (names.isEmpty || totalCount <= 0) return '';

    final visibleNames = names
        .where((name) => name.trim().isNotEmpty)
        .take(2)
        .toList();
    if (visibleNames.isEmpty) return '';

    if (totalCount == 1 || visibleNames.length == 1) {
      final remaining = totalCount - 1;
      if (remaining > 0) {
        return l10n.likedBy('${visibleNames.first} ${l10n.andMore(remaining)}');
      }
      return l10n.likedBy(visibleNames.first);
    }

    if (totalCount == 2) {
      return l10n.likedBy('${visibleNames.first} e ${visibleNames.last}');
    }

    return l10n.likedBy(
      '${visibleNames.first}, ${visibleNames.last} ${l10n.andMore(totalCount - 2)}',
    );
  }

  Future<void> _showLikersSheet(
    String locationId,
    String recordId,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF132D4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FutureBuilder<List<String>>(
              future: _controller.fetchAllLikerNames(locationId, recordId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF26A69A),
                      ),
                    ),
                  );
                }

                final names = snapshot.data ?? const <String>[];
                if (names.isEmpty) {
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
                  constraints: const BoxConstraints(maxHeight: 360),
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
                      Text(
                        l10n.likedBy('').trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: names.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: Color(0x1A64B5F6),
                            height: 1,
                          ),
                          itemBuilder: (_, index) {
                            final name = names[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(
                                Icons.thumb_up,
                                color: Color(0xFF26A69A),
                                size: 18,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
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

  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic data) {
    if (data is Timestamp) {
      final date = data.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return '—';
  }

  String _formatMeters(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '—';
    return text.endsWith('m') ? text : '${text}m';
  }

  String _formatDirection(String? value, AppLocalizations l10n) {
    switch (value?.toLowerCase()) {
      case 'subindo':
        return l10n.goingUp;
      case 'baixando':
        return l10n.goingDown;
      default:
        return '—';
    }
  }
}
