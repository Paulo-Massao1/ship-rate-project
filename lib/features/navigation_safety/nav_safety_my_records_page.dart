import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/nav_safety_controller.dart';
import 'nav_safety_new_record_page.dart';

/// Screen showing the current pilot's own navigation safety records
/// with edit and delete functionality.
class NavSafetyMyRecordsPage extends StatefulWidget {
  const NavSafetyMyRecordsPage({super.key});

  @override
  State<NavSafetyMyRecordsPage> createState() =>
      _NavSafetyMyRecordsPageState();
}

class _NavSafetyMyRecordsPageState extends State<NavSafetyMyRecordsPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _teal = Color(0xFF26A69A);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);

  // ===========================================================================
  // STATE
  // ===========================================================================

  final NavSafetyController _controller = NavSafetyController();
  List<MyRecord> _records = [];
  int _totalRecordsCount = 0;
  bool _isLoading = true;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _controller.fetchMyRecords(),
      _controller.getTotalRecordsCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _records = results[0] as List<MyRecord>;
      _totalRecordsCount = results[1] as int;
      _isLoading = false;
    });
  }

  int get _uniqueLocationsCount {
    return _records.map((r) => r.locationId).toSet().length;
  }

  String get _contributionPercentage {
    if (_totalRecordsCount == 0) return '0%';
    final pct = (_records.length / _totalRecordsCount * 100).toStringAsFixed(1);
    return '$pct%';
  }

  void _editRecord(MyRecord record) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NavSafetyNewRecordPage(
          editLocationId: record.locationId,
          editRecordId: record.recordId,
          editData: record.data,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteRecord(MyRecord record) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132D4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.deleteRecordTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.deleteRecordConfirm,
          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: Color(0x99FFFFFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteRecord,
                style: const TextStyle(color: Color(0xFFEF5350))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _controller.deleteRecord(record.locationId, record.recordId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.recordDeletedSuccess),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  String _formatDate(dynamic data) {
    if (data is Timestamp) {
      final d = data.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '—';
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
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _teal),
              )
            : _records.isEmpty
                ? _buildEmptyState(l10n)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildSummaryCard(l10n),
                      const SizedBox(height: 20),
                      Text(
                        l10n.yourRecords,
                        style: const TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._records.map((r) => _buildRecordCard(r, l10n)),
                    ],
                  ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.myRecords,
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
            colors: [_bgDark, Color(0xFF1A3A5C), _bgMid],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                color: Color(0x66FFFFFF), size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.noRecordsYet,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noRecordsSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SUMMARY CARD
  // ===========================================================================

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x1426A69A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x3326A69A)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                value: _records.length.toString(),
                label: l10n.recordsLabel,
                valueColor: Colors.white,
              ),
            ),
            Container(
              width: 1,
              color: const Color(0x2626A69A),
            ),
            Expanded(
              child: _buildStatItem(
                value: _uniqueLocationsCount.toString(),
                label: l10n.locationsLabel,
                valueColor: Colors.white,
              ),
            ),
            Container(
              width: 1,
              color: const Color(0x2626A69A),
            ),
            Expanded(
              child: _buildStatItem(
                value: _contributionPercentage,
                label: l10n.contributionLabel,
                valueColor: _teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0x66FFFFFF),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // RECORD CARD
  // ===========================================================================

  Widget _buildRecordCard(MyRecord record, AppLocalizations l10n) {
    final data = record.data;
    final profTotal = data['profundidadeTotal']?.toString() ?? '—';
    final shipName = (data['nomeNavio'] ?? '').toString();
    final dateStr = _formatDate(data['data']);

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
            // Top row: location + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.locationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            // Ship name
            if (shipName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('\u{1F6A2} ',
                      style: TextStyle(fontSize: 12)),
                  Text(
                    shipName,
                    style: const TextStyle(
                      color: Color(0xFF64B5F6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Profundidade total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1426A69A),
                borderRadius: BorderRadius.circular(8),
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
                      color: _teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Edit + Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  label: l10n.editRecord,
                  icon: '\u270F\uFE0F',
                  bgColor: const Color(0x1A64B5F6),
                  borderColor: const Color(0x3364B5F6),
                  textColor: const Color(0xFF64B5F6),
                  onTap: () => _editRecord(record),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  label: l10n.deleteRecord,
                  icon: '\u{1F5D1}',
                  bgColor: const Color(0x1AEF5350),
                  borderColor: const Color(0x33EF5350),
                  textColor: const Color(0xFFEF5350),
                  onTap: () => _deleteRecord(record),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
