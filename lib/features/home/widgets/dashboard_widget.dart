import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../core/events/data_change_notifier.dart';
import '../../../core/theme/app_colors.dart';

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
    setState(() => _dataFuture = _controller.loadDashboardData());
  }

  void _retry() {
    setState(() => _dataFuture = _controller.loadDashboardData());
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
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _retry,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DashboardData data) {
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.dashboardGradientStart,
              AppColors.dashboardGradientMid,
              AppColors.dashboardGradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            ..._buildDecorativeCircles(),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppStatsBlock(data, l10n),
                  const SizedBox(height: 14),
                  _buildUserActivityBlock(data, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Subtle translucent circles for visual depth on the gradient background.
  List<Widget> _buildDecorativeCircles() {
    return [
      Positioned(
        top: -40,
        right: -30,
        child: _DecorativeCircle(size: 140, opacity: 10),
      ),
      Positioned(
        bottom: -60,
        left: -40,
        child: _DecorativeCircle(size: 180, opacity: 8),
      ),
      Positioned(
        top: 60,
        left: -20,
        child: _DecorativeCircle(size: 80, opacity: 6),
      ),
    ];
  }

  // ===========================================================================
  // BLOCK 1 — APP STATS
  // ===========================================================================

  /// White card with section title + 2 stats side by side.
  Widget _buildAppStatsBlock(DashboardData data, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
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
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _StatItem(
                  icon: Icons.star_outline,
                  value: data.totalRatings.toString(),
                  label: l10n.totalRatingsLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BLOCK 2 — USER ACTIVITY
  // ===========================================================================

  /// Grey-tinted container with user ratings count, progress bar, and recent.
  Widget _buildUserActivityBlock(DashboardData data, AppLocalizations l10n) {
    final progress =
        data.totalRatings > 0 ? data.userRatings / data.totalRatings : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
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
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            l10n.yourRatingsLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            data.userRatings.toString(),
            style: const TextStyle(
              color: Colors.white,
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.grey[300],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.contributionSummary(
            data.userRatings.toString(),
            data.totalRatings.toString(),
          ),
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (data.recentRatings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                l10n.noRecentActivity,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.directions_boat,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rating.shipName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

/// Translucent circle used as background decoration.
class _DecorativeCircle extends StatelessWidget {
  final double size;
  final int opacity;

  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(opacity),
      ),
    );
  }
}

/// Section title used in both blocks.
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
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
        Icon(icon, color: AppColors.secondary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }
}
