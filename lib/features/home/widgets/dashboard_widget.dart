import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../controllers/rating_controller.dart';
import '../../../core/constants.dart';
import '../../../core/events/data_change_notifier.dart';
import '../../ratings/last_rated_page.dart';
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
  final _ratingController = RatingController();
  late Future<DashboardData> _dataFuture;
  Future<_LastRatedRatingMeta?>? _lastRatedMetaFuture;
  String? _lastRatedMetaKey;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _reloadDashboard();
    dataRevision.addListener(_onDataChanged);
    _ratingController.addListener(_onRatingControllerChanged);
  }

  @override
  void dispose() {
    dataRevision.removeListener(_onDataChanged);
    _ratingController.removeListener(_onRatingControllerChanged);
    _ratingController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _onDataChanged() {
    setState(() {
      _reloadDashboard();
    });
  }

  void _retry() {
    setState(() {
      _reloadDashboard();
    });
  }

  void _onRatingControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _reloadDashboard() {
    _lastRatedMetaFuture = null;
    _lastRatedMetaKey = null;
    _dataFuture = _controller.loadDashboardData();
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
                  showChevron: true,
                  onTap: _openLastRatedPage,
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

  // ===========================================================================
  // BLOCK — LAST RATED SHIP
  // ===========================================================================

  Widget _buildLastRatedBlock(DashboardData data, AppLocalizations l10n) {
    _syncLastRatedMetaFuture(data);
    final date = data.lastRatedDate!;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final isTappable =
        data.lastRatedShipId != null && data.lastRatedRatingId != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isTappable ? () => _onLastRatedTap(data) : null,
        borderRadius: BorderRadius.circular(14),
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
              if (isTappable && _lastRatedMetaFuture != null)
                FutureBuilder<_LastRatedRatingMeta?>(
                  future: _lastRatedMetaFuture,
                  builder: (context, snapshot) {
                    final meta = snapshot.data;
                    if (meta == null) {
                      return const SizedBox.shrink();
                    }
                    return _buildLastRatedLikeSection(data, meta, l10n);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastRatedLikeSection(
    DashboardData data,
    _LastRatedRatingMeta meta,
    AppLocalizations l10n,
  ) {
    final shipId = data.lastRatedShipId;
    final ratingId = data.lastRatedRatingId;
    if (shipId == null || ratingId == null) {
      return const SizedBox.shrink();
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isOwnRating = meta.userId.isNotEmpty && meta.userId == currentUid;
    if (isOwnRating) {
      return const SizedBox.shrink();
    }

    final liked = _ratingController.hasUserLikedRating(shipId, ratingId);
    final likeCount = _ratingController.getRatingLikeCount(shipId, ratingId);
    final likerNames = _ratingController.getRatingLikerNames(shipId, ratingId);
    final likedByText = _formatLikedByText(likerNames, likeCount, l10n);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _ratingController.toggleRatingLike(shipId, ratingId);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: liked
                        ? const Color(0xFF26A69A)
                        : const Color(0x99FFFFFF),
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
                onTap: () => _showRatingLikersSheet(shipId, ratingId, l10n),
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
    );
  }

  void _syncLastRatedMetaFuture(DashboardData data) {
    final shipId = data.lastRatedShipId;
    final ratingId = data.lastRatedRatingId;
    if (shipId == null || ratingId == null) {
      _lastRatedMetaFuture = null;
      _lastRatedMetaKey = null;
      return;
    }

    final key = '$shipId/$ratingId';
    if (_lastRatedMetaKey == key && _lastRatedMetaFuture != null) {
      return;
    }

    _lastRatedMetaKey = key;
    _lastRatedMetaFuture = _loadLastRatedMeta(shipId, ratingId);
  }

  Future<_LastRatedRatingMeta?> _loadLastRatedMeta(
    String shipId,
    String ratingId,
  ) async {
    final ratingDoc = await FirebaseFirestore.instance
        .collection(AppConstants.shipsCollection)
        .doc(shipId)
        .collection(AppConstants.ratingsSubcollection)
        .doc(ratingId)
        .get();

    if (!ratingDoc.exists) return null;

    await _ratingController.loadRatingLikeStates(
      shipId,
      [ratingId],
      notify: false,
    );

    final ratingData = ratingDoc.data() ?? const <String, dynamic>{};
    return _LastRatedRatingMeta(
      userId: (ratingData['usuarioId'] ?? '').toString().trim(),
      likeCount: ratingData['likeCount'] as int? ?? 0,
    );
  }

  Future<void> _openLastRatedPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LastRatedPage()),
    );

    if (!mounted) return;
    setState(_reloadDashboard);
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
          .collection(AppConstants.shipsCollection)
          .doc(data.lastRatedShipId)
          .collection(AppConstants.ratingsSubcollection)
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
      return l10n.likedBy(
        '${visibleNames.first} ${l10n.andWord} ${visibleNames.last}',
      );
    }

    return l10n.likedBy(
      '${visibleNames.first}, ${visibleNames.last} ${l10n.andMore(totalCount - 2)}',
    );
  }

  Future<void> _showRatingLikersSheet(
    String shipId,
    String ratingId,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF132D4A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FutureBuilder<List<String>>(
              future: _ratingController.fetchAllRatingLikerNames(shipId, ratingId),
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
                          color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
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
                    data.totalUsers.toString(),
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

  /// Single recent rating row: ship icon + name + date. Tappable to view details.
  Widget _buildRecentItem(RecentRating rating, bool showDivider) {
    final dateStr =
        '${rating.date.day.toString().padLeft(2, '0')}/'
        '${rating.date.month.toString().padLeft(2, '0')}/'
        '${rating.date.year}';

    return Column(
      children: [
        GestureDetector(
          onTap: () => _onRecentRatingTap(rating),
          child: Padding(
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
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ],
            ),
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

  Future<void> _onRecentRatingTap(RecentRating rating) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.shipsCollection)
          .doc(rating.shipId)
          .collection(AppConstants.ratingsSubcollection)
          .where(FieldPath.documentId, isEqualTo: rating.ratingId)
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
}

class _LastRatedRatingMeta {
  final String userId;
  final int likeCount;

  const _LastRatedRatingMeta({
    required this.userId,
    required this.likeCount,
  });
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
  final bool showChevron;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
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
                  if (showChevron) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
