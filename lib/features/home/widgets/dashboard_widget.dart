import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../core/events/data_change_notifier.dart';
import '../../ratings/rating_detail_page.dart';

/// Dashboard widget with two visual blocks:
/// - Block 1: App stats (total ships + total ratings)
/// - Block 2: User activity (your ratings, contribution, recent)
///
/// Handles loading, error, and loaded states.
class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  // ===========================================================================
  // DEPENDENCIES & STATE
  // ===========================================================================

  final _controller = DashboardController();
  late Future<DashboardData> _dataFuture;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _dataFuture = _controller.loadDashboardData();
    dataRevision.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    dataRevision.removeListener(_onDataChanged);
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _onDataChanged() {
    setState(() {
      _dataFuture = _controller.loadDashboardData();
    });
  }

  void _retry() {
    setState(() {
      _dataFuture = _controller.loadDashboardData();
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError();
        }

        final data = snapshot.data ?? DashboardData.empty();
        return _buildDashboard(data);
      },
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6).withValues(alpha: 0.15),
              foregroundColor: const Color(0xFF64B5F6),
            ),
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DashboardData data) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppStatsBlock(data, l10n),
          if (data.lastRatedShipName != null) ...[
            const SizedBox(height: 14),
            _buildLastRatedBlock(data, l10n),
          ],
          const SizedBox(height: 14),
          _buildUserActivityBlock(data, l10n),
        ],
      ),
    );
  }

  // ===========================================================================
  // BLOCK 1 — APP STATS
  // ===========================================================================

  /// Dark card with section title + 2 stats side by side.
  Widget _buildAppStatsBlock(DashboardData data, AppLocalizations l10n) {
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
          _SectionTitle(label: l10n.dashboardAppStats),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.directions_boat,
                  value: data.totalShips.toString(),
                  label: l10n.totalShipsLabel,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.star_outline,
                  value: data.totalRatings.toString(),
                  label: l10n.totalRatingsLabel,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.people,
                  value: data.totalUsers.toString(),
                  label: l10n.activePilotsLabel,
                ),
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
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.topRaterInfo(data.topRaterCount.toString()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
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

  // ===========================================================================
  // BLOCK — LAST RATED SHIP
  // ===========================================================================

  Widget _buildLastRatedBlock(DashboardData data, AppLocalizations l10n) {
    final date = data.lastRatedDate!;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final isTappable =
        data.lastRatedShipId != null && data.lastRatedRatingId != null;

    return GestureDetector(
      onTap: isTappable ? () => _onLastRatedTap(data) : null,
      child: Container(
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
            _SectionTitle(label: l10n.lastRatedShip),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_boat,
                    size: 20,
                    color: Color(0xFF64B5F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.lastRatedShipName!.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data.lastRatedByPilot != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.pilotCallSign(data.lastRatedByPilot!),
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
                if (isTappable) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLastRatedTap(DashboardData data) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('navios')
          .doc(data.lastRatedShipId)
          .collection('avaliacoes')
          .where(FieldPath.documentId, isEqualTo: data.lastRatedRatingId)
          .limit(1)
          .get();

      if (!mounted) return;
      Navigator.pop(context);

      if (querySnapshot.docs.isEmpty) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RatingDetailPage(rating: querySnapshot.docs.first),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // ===========================================================================
  // BLOCK 2 — USER ACTIVITY
  // ===========================================================================

  /// Dark card with user ratings count, progress bar, and recent.
  Widget _buildUserActivityBlock(DashboardData data, AppLocalizations l10n) {
    final progress =
        data.totalRatings > 0 ? data.userRatings / data.totalRatings : 0.0;

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
          _SectionTitle(label: l10n.dashboardYourActivity),
          const SizedBox(height: 14),

          // User rating count — highlighted
          _buildUserRatingsBadge(data, l10n),
          const SizedBox(height: 14),

          // Contribution progress
          _buildContribution(data, l10n, progress),

          if (data.userRankingPosition > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: Color(0xFF4DB6AC),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.userRankingPosition(
                    data.userRankingPosition.toString(),
                    data.totalPilotsWhoRated.toString(),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF4DB6AC),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // Recent activity
          _buildRecentActivity(data, l10n),
        ],
      ),
    );
  }

  /// Highlighted badge showing user's total ratings.
  Widget _buildUserRatingsBadge(DashboardData data, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            l10n.yourRatingsLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            data.userRatings.toString(),
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar with motivational summary text.
  Widget _buildContribution(
    DashboardData data,
    AppLocalizations l10n,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourContribution,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.contributionSummary(
            data.userRatings.toString(),
            data.totalRatings.toString(),
          ),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Recent activity list or empty message.
  Widget _buildRecentActivity(DashboardData data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentActivity,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        if (data.recentRatings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                l10n.noRecentActivity,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          ...data.recentRatings.asMap().entries.map((entry) =>
              _buildRecentItem(
                  entry.value, entry.key < data.recentRatings.length - 1)),
      ],
    );
  }

  /// Single recent rating row: ship icon + name + date.
  Widget _buildRecentItem(RecentRating rating, bool showDivider) {
    final dateStr =
        '${rating.date.day.toString().padLeft(2, '0')}/'
        '${rating.date.month.toString().padLeft(2, '0')}/'
        '${rating.date.year}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_boat,
                  size: 16,
                  color: Color(0xFF64B5F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rating.shipName.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
      ],
    );
  }
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

/// Section title used in both blocks — ocean theme.
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
      ),
    );
  }
}

/// Single stat item (icon + value + label) used in the app stats block.
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF64B5F6), size: 22),
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
    );
  }
}
