import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../controllers/my_ratings_controller.dart';
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

  static const _primaryColor = Color(0xFF3F51B5);

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
      debugPrint('❌ Error loading ratings: $error');
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
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          l10n.myRatingsTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
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
          const CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text(
            l10n.loadingRatings,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
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
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRatings,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              decoration: BoxDecoration(
                color: _primaryColor.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noRatingsYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noRatingsSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsList() {
    return RefreshIndicator(
      onRefresh: _loadRatings,
      color: _primaryColor,
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.totalRatings(count),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const Spacer(),
          const Icon(Icons.schedule, color: Colors.black54, size: 16),
          const SizedBox(width: 4),
          Text(
            l10n.newestFirst,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
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
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(item),
                const SizedBox(height: 16),
                const Divider(height: 1),
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
            color: _primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.directions_boat,
            color: _primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.shipName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              if (item.shipImo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'IMO: ${item.shipImo}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: _primaryColor),
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
                color: _primaryColor,
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
                    value: l10n.deckLabel(cabinDeck),
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
          color: _primaryColor,
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
        child: CircularProgressIndicator(color: _primaryColor),
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
