import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/nav_safety_controller.dart';
import 'nav_safety_new_record_page.dart';
import 'nav_safety_my_records_page.dart';

/// Main screen for the Navigation Safety module.
///
/// Shows three inner tab pills:
/// 1. Últimas Profundidades — list of all locations with latest depth
/// 2. Locais — dropdown to pick a location
/// 3. Novo Registro — placeholder for future form
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

  void _onBackFromHistory() {
    _controller.clearSelection();
  }

  void _navigateToNewRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyNewRecordPage()),
    ).then((_) {
      // Refresh locations after returning from the form
      _controller.fetchLocationsWithLatestRecord();
    });
  }

  void _navigateToMyRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NavSafetyMyRecordsPage()),
    );
  }

  void _toggleLocationsDropdown() {
    setState(() {
      _showLocationsDropdown = !_showLocationsDropdown;
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: Column(
          children: [
            _buildTabPills(l10n),
            Expanded(child: _buildBody(l10n)),
          ],
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x1F26A69A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4026A69A)),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF26A69A)),
              onPressed: _navigateToNewRecord,
            ),
          ),
        ),
      ],
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
            isActive: _controller.selectedLocationId == null && !_showLocationsDropdown,
            onTap: () {
              setState(() => _showLocationsDropdown = false);
              _controller.clearSelection();
            },
          ),
          const SizedBox(width: 8),
          _buildPill(
            label: l10n.locations,
            isActive: _showLocationsDropdown,
            trailing: const Icon(Icons.arrow_drop_down, color: Color(0x99FFFFFF), size: 18),
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
                color: isActive ? const Color(0xFF26A69A) : const Color(0x99FFFFFF),
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
  // TAB 1 — LATEST DEPTHS
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
    final depth = loc.latestDepth;
    final date = loc.latestDateFormatted;

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
                      const SizedBox(height: 4),
                      Text(
                        depth ?? '—',
                        style: const TextStyle(
                          color: Color(0xFF26A69A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date ?? l10n.noRecords,
                        style: const TextStyle(
                          color: Color(0x66FFFFFF),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '\u203A',
                  style: TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2 — LOCATIONS DROPDOWN
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
        ? (records.first['profundidadeTotal']?.toString() ?? '—')
        : '—';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Summary card
        _buildSummaryCard(l10n, latestDepth),
        const SizedBox(height: 16),
        // History label
        Text(
          l10n.history,
          style: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        // Records list
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
      child: Row(
        children: [
          Expanded(
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
          GestureDetector(
            onTap: _onBackFromHistory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x1F64B5F6)),
              ),
              child: Text(
                l10n.back,
                style: const TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record, AppLocalizations l10n) {
    final pilotName = (record['nomeGuerra'] ?? '').toString();
    final profTotal = record['profundidadeTotal']?.toString() ?? '—';
    final caladoMax = record['caladoMax']?.toString() ?? '—';
    final ukc = record['ukc']?.toString() ?? '—';
    final direcao = record['direcao']?.toString() ?? '—';

    String dateStr = '—';
    final data = record['data'];
    if (data is Timestamp) {
      final d = data.toDate();
      dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1A64B5F6)),
        ),
        child: Column(
          children: [
            // Pilot name + date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pilotName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Profundidade total — centered and prominent
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
                    profTotal,
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
            // 3 columns: CALADO MÁX. | UKC | DIREÇÃO
            Row(
              children: [
                _buildStatColumn(l10n.maxDraft, caladoMax),
                _buildStatColumn(l10n.ukc, ukc),
                _buildStatColumn(l10n.direction, direcao),
              ],
            ),
          ],
        ),
      ),
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
}
