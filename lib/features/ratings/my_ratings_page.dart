import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/my_ratings_controller.dart';
import '../../core/events/data_change_notifier.dart';
import '../../data/services/pdf_labels_factory.dart';
import 'rating_detail_page.dart';
import 'edit_rating_page.dart';

/// Screen displaying all ratings created by the current user.
///
/// Features:
/// - Lists all user's ratings sorted by date (newest first)
/// - Pull-to-refresh support
/// - View rating details
/// - Edit rating (with warning dialog)
/// - Delete rating (with confirmation dialog)
/// - Export rating to PDF
class MyRatingsPage extends StatefulWidget {
  const MyRatingsPage({super.key});

  @override
  State<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  // Deep Ocean theme colors
  static const _accentBlue = Color(0xFF64B5F6);
  static const _cardBg = Color(0x0DFFFFFF);
  static const _cardBorder = Color(0x1A64B5F6);
  static const _iconBg = Color(0x1A64B5F6);
  static const _bodyText = Color(0xD9FFFFFF);
  static const _subtitleText = Color(0x99FFFFFF);
  static const _secondaryText = Color(0x59FFFFFF);
  static const _dividerColor = Color(0x0DFFFFFF);

  // ===========================================================================
  // CONTROLLER & STATE
  // ===========================================================================

  final _controller = MyRatingsController();

  bool _isLoading = true;
  String? _errorMessage;
  List<RatingWithShipInfo> _ratings = [];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ratings = await _controller.loadUserRatings();

      if (mounted) {
        setState(() {
          _ratings = ratings;
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('[MyRatings] Error loading ratings: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _showEditWarning(RatingWithShipInfo item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _EditWarningDialog(),
    );

    if (confirmed == true && mounted) {
      final edited = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditRatingPage(rating: item.rating)),
      );

      if (edited == true) {
        _loadRatings();
        notifyDataChanged();
      }
    }
  }

  Future<void> _showDeleteConfirmation(RatingWithShipInfo item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmationDialog(shipName: item.shipName),
    );

    if (confirmed == true && mounted) {
      await _deleteRating(item);
    }
  }

  Future<void> _deleteRating(RatingWithShipInfo item) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _showLoadingDialog();
      await _controller.deleteRating(item.rating.reference);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(l10n.ratingDeletedSuccess);
        _loadRatings();
        notifyDataChanged();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(l10n.errorDeleting(e.toString()));
      }
    }
  }

  Future<void> _exportRatingToPdf(RatingWithShipInfo item) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _showLoadingDialog();

      final pdf = await _controller.generateRatingPdf(item, buildPdfLabels(l10n));

      if (mounted) {
        Navigator.pop(context);
      }

      await _controller.saveAndSharePdf(pdf, item.shipName);

      if (mounted) {
        _showSuccessSnackBar(l10n.pdfGeneratedSuccess);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showErrorSnackBar(l10n.errorGeneratingPdf(e.toString()));
      }
    }
  }

  void _navigateToDetail(RatingWithShipInfo item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RatingDetailPage(rating: item.rating)),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text(
          l10n.myRatingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_ratings.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRatingsList();
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _accentBlue),
          const SizedBox(height: 16),
          Text(
            l10n.loadingRatings,
            style: const TextStyle(color: _subtitleText, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: _bodyText),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(-1, -1),
                  end: Alignment(1, 1),
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x661565C0),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loadRatings,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _iconBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: _accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noRatingsYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noRatingsSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _subtitleText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList() {
    return RefreshIndicator(
      onRefresh: _loadRatings,
      color: _accentBlue,
      backgroundColor: const Color(0xFF0D2137),
      child: Column(
        children: [
          _buildListHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _ratings.length,
              itemBuilder: (_, index) => _buildRatingCard(_ratings[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final l10n = AppLocalizations.of(context)!;
    final count = _ratings.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: _accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.totalRatings(count),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _accentBlue,
            ),
          ),
          const Spacer(),
          const Icon(Icons.schedule, color: _secondaryText, size: 16),
          const SizedBox(width: 4),
          Text(
            l10n.newestFirst,
            style: const TextStyle(fontSize: 12, color: _secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(RatingWithShipInfo item) {
    final data = item.rating.data() as Map<String, dynamic>;
    final ratingDate = _controller.resolveRatingDate(data);
    final averageRating = _controller.calculateAverageRating(data);
    final cabinType = data['tipoCabine'] ?? '';
    final cabinDeck = data['deckCabine'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: InkWell(
          onTap: () => _navigateToDetail(item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(item),
                const SizedBox(height: 16),
                Divider(height: 1, color: _dividerColor),
                const SizedBox(height: 12),
                _buildCardInfo(ratingDate, averageRating, cabinType, cabinDeck),
                const SizedBox(height: 12),
                _buildCardActions(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(RatingWithShipInfo item) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.directions_boat,
            color: _accentBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.shipName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (item.shipImo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'IMO: ${item.shipImo}',
                  style: const TextStyle(fontSize: 12, color: _secondaryText),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: _accentBlue),
      ],
    );
  }

  Widget _buildCardInfo(
    DateTime ratingDate,
    double averageRating,
    String cabinType,
    String? cabinDeck,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoChip(
                icon: Icons.star,
                label: l10n.averageScore,
                value: averageRating.toStringAsFixed(1),
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoChip(
                icon: Icons.calendar_today,
                label: l10n.ratingDate,
                value: _controller.formatDate(ratingDate),
                color: _accentBlue,
              ),
            ),
          ],
        ),
        if (cabinType.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.bed,
                  label: l10n.cabin,
                  value: cabinType,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              if (cabinDeck != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.layers,
                    label: 'Deck',
                    value: _formatDeckLabel(l10n, cabinDeck),
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Returns localized label for a deck key (backward compatible).
  String _formatDeckLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'bridge': return l10n.deckBridge;
      case '1_below': return l10n.deck1Below;
      case '2_below': return l10n.deck2Below;
      case '3_below': return l10n.deck3Below;
      case '4+_below': return l10n.deck4PlusBelow;
      default: return l10n.deckLabel(key);
    }
  }

  Widget _buildCardActions(RatingWithShipInfo item) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _ActionButton(
          icon: Icons.delete_outline,
          label: l10n.deleteLabel,
          color: Colors.red,
          onTap: () => _showDeleteConfirmation(item),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.edit,
          label: l10n.editLabel,
          color: Colors.orange,
          onTap: () => _showEditWarning(item),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.picture_as_pdf,
          label: 'PDF',
          color: _accentBlue,
          onTap: () => _exportRatingToPdf(item),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _accentBlue),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(38)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withAlpha(179),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: color.withAlpha(26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _EditWarningDialog extends StatelessWidget {
  const _EditWarningDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          Text(l10n.editWarningTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.editWarningCorrectionsOnly,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(l10n.editWarningDescription),
          const SizedBox(height: 8),
          Text(
            l10n.editWarningImportant,
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.editWarningNewRating,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.editWarningHistory,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.editWarningConfirm),
        ),
      ],
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final String shipName;

  const _DeleteConfirmationDialog({required this.shipName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_forever, color: Colors.red, size: 28),
          const SizedBox(width: 8),
          Text(l10n.deleteRatingTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deleteRatingConfirm(shipName),
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.deleteWarning,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.deleteButton),
        ),
      ],
    );
  }
}
