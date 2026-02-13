import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../controllers/dashboard_controller.dart';

// =============================================================================
// CONSTANTS
// =============================================================================

const _primaryColor = Color(0xFF3F51B5);

// =============================================================================
// DASHBOARD WIDGET
// =============================================================================

/// Dashboard widget showing ship/rating statistics and recent activity.
///
/// Replaces the ship background image in the search tab when no ship is selected.
class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  final _controller = DashboardController();
  late Future<DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _controller.loadDashboardData();
  }

  void _retry() {
    setState(() {
      _dataFuture = _controller.loadDashboardData();
    });
  }

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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(data, l10n),
          const SizedBox(height: 16),
          _buildProgressCard(data, l10n),
          const SizedBox(height: 16),
          _buildRecentActivityCard(data, l10n),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardData data, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_boat,
            label: l10n.totalShipsLabel,
            value: data.totalShips.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline,
            label: l10n.totalRatingsLabel,
            value: data.totalRatings.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.person_outline,
            label: l10n.yourRatingsLabel,
            value: data.userRatings.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(DashboardData data, AppLocalizations l10n) {
    final percent = data.totalRatings > 0
        ? (data.userRatings / data.totalRatings * 100)
        : 0.0;
    final progress =
        data.totalRatings > 0 ? data.userRatings / data.totalRatings : 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.yourContribution,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.contributionProgress(percent.toStringAsFixed(1)),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(DashboardData data, AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recentActivity,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (data.recentRatings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    l10n.noRecentActivity,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              )
            else
              ...data.recentRatings.map((rating) => _buildRecentItem(rating)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(RecentRating rating) {
    final dateStr =
        '${rating.date.day.toString().padLeft(2, '0')}/'
        '${rating.date.month.toString().padLeft(2, '0')}/'
        '${rating.date.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_boat,
              size: 20,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rating.shipName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rating.averageScore.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: _primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
