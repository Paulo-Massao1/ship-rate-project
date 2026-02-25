import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/ship_search_controller.dart';
import '../../core/events/data_change_notifier.dart';
import '../home/widgets/dashboard_widget.dart';
import '../ratings/add_rating_page.dart';
import '../ratings/rating_detail_page.dart';

/// Main screen for searching and rating ships.
///
/// Features two tabs:
/// - Search: Find ships and view their ratings
/// - Rate: Create new ship ratings
class SearchAndRateShipPage extends StatefulWidget {
  const SearchAndRateShipPage({super.key});

  @override
  State<SearchAndRateShipPage> createState() => _SearchAndRateShipPageState();
}

class _SearchAndRateShipPageState extends State<SearchAndRateShipPage>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _accentBlue = Color(0xFF64B5F6);

  // ===========================================================================
  // CONTROLLERS
  // ===========================================================================

  late final TabController _tabController;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF0D2137),
            Color(0xFF132D4A),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _SearchShipTab(),
                  _RateShipTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shipRatingTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchSubtitle,
            style: TextStyle(
              color: _accentBlue.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: _accentBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        labelColor: _accentBlue,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: l10n.searchTab),
          Tab(text: l10n.rateTab),
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH TAB
// =============================================================================

class _SearchShipTab extends StatefulWidget {
  const _SearchShipTab();

  @override
  State<_SearchShipTab> createState() => _SearchShipTabState();
}

class _SearchShipTabState extends State<_SearchShipTab>
    with AutomaticKeepAliveClientMixin {
  // ===========================================================================
  // CONTROLLER & STATE
  // ===========================================================================

  final _controller = ShipSearchController();
  final _searchTextController = TextEditingController();

  List<QueryDocumentSnapshot> _suggestions = [];
  QueryDocumentSnapshot? _selectedShip;
  List<QueryDocumentSnapshot>? _ratings;

  @override
  bool get wantKeepAlive => true;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _updateSuggestions(String text) async {
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
        _selectedShip = null;
        _ratings = null;
      });
      return;
    }

    final results = await _controller.searchShips(text);
    setState(() => _suggestions = results);
  }

  Future<void> _selectShip(QueryDocumentSnapshot doc) async {
    final ratings = await _controller.loadShipRatings(doc.id);

    setState(() {
      _selectedShip = doc;
      _ratings = ratings;
      _suggestions = [];
      _searchTextController.text = ((doc.data() as Map)['nome'] as String).toUpperCase();
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchField(),
          if (_suggestions.isNotEmpty) _buildSuggestionsList(),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: _searchTextController,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [_UpperCaseTextFormatter()],
      onChanged: _updateSuggestions,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64B5F6)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF64B5F6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF132D4A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
          ),
        ),
        child: ListView.separated(
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          itemBuilder: (_, index) {
            final doc = _suggestions[index];
            final data = doc.data() as Map;

            return ListTile(
              leading: Icon(
                Icons.directions_boat,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              title: _HighlightedText(
                text: (data['nome'] as String).toUpperCase(),
                query: _searchTextController.text,
              ),
              onTap: () => _selectShip(doc),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    // No search yet - show dashboard
    if (_selectedShip == null && _suggestions.isEmpty) {
      return const Expanded(child: DashboardWidget());
    }

    // Ship selected - show details and ratings
    if (_selectedShip != null) {
      final l10n = AppLocalizations.of(context)!;
      return Expanded(
        child: ListView(
          children: [
            _ShipSummaryCard(
              controller: _controller,
              ship: _selectedShip!,
              ratings: _ratings,
            ),
            if (_ratings != null && _ratings!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.ratings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _RatingsList(controller: _controller, ratings: _ratings!),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// =============================================================================
// RATE TAB
// =============================================================================

class _RateShipTab extends StatelessWidget {
  const _RateShipTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Subtle wave decoration at top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 120),
            painter: _WavePainter(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
            ),
          ),
        ),
        // Frosted glass card — centered
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                    ),
                  ),
                  child: _buildCardContent(context),
                ),
              ),
            ),
          ),
        ),
        // Bottom wave decoration
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 60),
            painter: _WavePainter(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.06),
              flip: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ship icon in container
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.directions_boat,
            color: Color(0xFF64B5F6),
            size: 26,
          ),
        ),
        const SizedBox(height: 18),
        // Title
        Text(
          l10n.newShipRating,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          l10n.rateSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        // CTA button
        _buildStartButton(context),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 240,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _navigateToAddRating(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note, size: 20),
              const SizedBox(width: 10),
              Text(
                l10n.startRating,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddRating(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRatingPage(imo: '')),
    );

    if (result == true) {
      notifyDataChanged();
    }
  }
}

// =============================================================================
// SHIP SUMMARY CARD
// =============================================================================

class _ShipSummaryCard extends StatelessWidget {
  final ShipSearchController controller;
  final QueryDocumentSnapshot ship;
  final List<QueryDocumentSnapshot>? ratings;

  const _ShipSummaryCard({
    required this.controller,
    required this.ship,
    this.ratings,
  });

  static const _primaryColor = Colors.indigo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = ship.data() as Map<String, dynamic>;
    final shipData = controller.extractShipData(ship);
    final infoItems = _buildInfoItems(context, shipData.info);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shipData.name.toUpperCase(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMarineTrafficButton(context, data),
            if (infoItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.generalInfo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInfoGrid(context, infoItems),
            ],
            if (shipData.averages.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                l10n.ratingAverages,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAveragesList(context, shipData.averages),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarineTrafficButton(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openMarineTraffic(context, data),
        icon: const Icon(Icons.waves, size: 20),
        label: Text(
          l10n.viewOnMarineTraffic,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openMarineTraffic(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final success = await controller.openMarineTraffic(
      shipName: data['nome'],
      imo: data['imo'],
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.marineTrafficError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildInfoItems(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final items = <Widget>[];

    // Crew nationality
    final nationalityDisplay = _formatNationality(l10n, info['nacionalidadeTripulacao']);
    if (nationalityDisplay.isNotEmpty) {
      items.add(_buildInfoItem(
        Icons.groups,
        l10n.crew,
        nationalityDisplay,
      ));
    }

    // Cabin count
    final cabinLabel = _formatCabinCount(info['numeroCabines'], l10n);
    if (cabinLabel != null) {
      items.add(_buildInfoItem(
        Icons.bed,
        l10n.cabins,
        cabinLabel,
      ));
    }

    // Amenities
    final amenities = controller.resolveAmenities(info, ratings);

    if (amenities['frigobar'] != null) {
      items.add(_buildInfoItem(
        Icons.kitchen,
        l10n.minibar,
        amenities['frigobar']! ? l10n.yes : l10n.no,
      ));
    }

    if (amenities['pia'] != null) {
      items.add(_buildInfoItem(
        Icons.water_drop,
        l10n.sink,
        amenities['pia']! ? l10n.yes : l10n.no,
      ));
    }

    if (amenities['microondas'] != null) {
      items.add(_buildInfoItem(
        Icons.microwave,
        l10n.microwave,
        amenities['microondas']! ? l10n.yes : l10n.no,
      ));
    }

    return items;
  }

  /// Maps a nationality key to its localized label.
  String _nationalityLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Filipino': return l10n.nationalityFilipino;
      case 'Russian': return l10n.nationalityRussian;
      case 'Ukrainian': return l10n.nationalityUkrainian;
      case 'Indian': return l10n.nationalityIndian;
      case 'Chinese': return l10n.nationalityChinese;
      case 'Brazilian': return l10n.nationalityBrazilian;
      default: return key;
    }
  }

  /// Formats nationality value for display with i18n (backward compatible).
  String _formatNationality(AppLocalizations l10n, dynamic value) {
    if (value == null) return '';
    if (value is List) {
      final joined = value.map((e) => _nationalityLabel(l10n, e.toString())).join(', ');
      return joined;
    }
    return _nationalityLabel(l10n, value.toString());
  }

  /// Converts cabin count value to localized display label.
  String? _formatCabinCount(dynamic value, AppLocalizations l10n) {
    if (value == null) return null;
    String key;
    if (value is int) {
      if (value <= 0) return null;
      key = value >= 3 ? '3+' : value.toString();
    } else {
      key = value.toString();
    }
    switch (key) {
      case '1': return l10n.cabinCountOne;
      case '2': return l10n.cabinCountTwo;
      case '3+': return l10n.cabinCountMoreThanTwo;
      default: return null;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, List<Widget> items) {
    final itemWidth = (MediaQuery.of(context).size.width - 64) / 2;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items.map((item) => SizedBox(width: itemWidth, child: item)).toList(),
    );
  }

  Widget _buildAveragesList(BuildContext context, Map<String, dynamic> averages) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (averages['temp_cabine'] != null)
          _buildAverageItem(
            Icons.thermostat,
            l10n.avgCabinTemp,
            averages['temp_cabine'].toString(),
          ),
        if (averages['limpeza_cabine'] != null)
          _buildAverageItem(
            Icons.cleaning_services,
            l10n.avgCabinCleanliness,
            averages['limpeza_cabine'].toString(),
          ),
        if (averages['passadico_equip'] != null)
          _buildAverageItem(
            Icons.control_camera,
            l10n.avgBridgeEquipment,
            averages['passadico_equip'].toString(),
          ),
        if (averages['passadico_temp'] != null)
          _buildAverageItem(
            Icons.device_thermostat,
            l10n.avgBridgeTemp,
            averages['passadico_temp'].toString(),
          ),
        if (averages['comida'] != null)
          _buildAverageItem(
            Icons.restaurant,
            l10n.avgFood,
            averages['comida'].toString(),
          ),
        if (averages['relacionamento'] != null)
          _buildAverageItem(
            Icons.handshake,
            l10n.avgRelationship,
            averages['relacionamento'].toString(),
          ),
        if (averages['dispositivo'] != null)
          _buildAverageItem(
            Icons.transfer_within_a_station,
            l10n.avgDevice,
            averages['dispositivo'].toString(),
          ),
      ],
    );
  }

  Widget _buildAverageItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// RATINGS LIST
// =============================================================================

class _RatingsList extends StatelessWidget {
  final ShipSearchController controller;
  final List<QueryDocumentSnapshot> ratings;

  const _RatingsList({
    required this.controller,
    required this.ratings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ratings.map((doc) => _buildRatingCard(context, doc)).toList(),
    );
  }

  Widget _buildRatingCard(BuildContext context, QueryDocumentSnapshot doc) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;
    final callSign = data['nomeGuerra'] ?? l10n.pilot;
    final timestamp = data['createdAt'] as Timestamp?;
    final relativeTime = controller.getRelativeTime(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.indigo),
        title: Text(
          l10n.pilotCallSign(callSign),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.viewRating,
              style: const TextStyle(
                color: Colors.indigo,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              relativeTime,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToDetail(context, doc),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, QueryDocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RatingDetailPage(rating: doc)),
    );
  }
}

// =============================================================================
// HIGHLIGHTED TEXT WIDGET
// =============================================================================

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final defaultColor = Colors.white.withValues(alpha: 0.85);
    if (query.isEmpty) return Text(text, style: TextStyle(color: defaultColor));

    final queryChars = query.toLowerCase().split('');

    return RichText(
      text: TextSpan(
        style: TextStyle(color: defaultColor),
        children: text.split('').map((char) {
          final isMatch = queryChars.contains(char.toLowerCase());
          return TextSpan(
            text: char,
            style: TextStyle(
              fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
              color: isMatch ? const Color(0xFF64B5F6) : defaultColor,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Forces all text input to uppercase.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// =============================================================================
// PAINTERS
// =============================================================================

/// Paints a subtle wave curve for decorative ocean atmosphere.
class _WavePainter extends CustomPainter {
  final Color color;
  final bool flip;

  _WavePainter({required this.color, this.flip = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (flip) {
      path.moveTo(0, size.height);
      path.lineTo(0, size.height * 0.4);
      path.quadraticBezierTo(
        size.width * 0.25, 0,
        size.width * 0.5, size.height * 0.3,
      );
      path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6,
        size.width, size.height * 0.2,
      );
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, size.height * 0.6);
      path.quadraticBezierTo(
        size.width * 0.25, size.height,
        size.width * 0.5, size.height * 0.7,
      );
      path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.4,
        size.width, size.height * 0.8,
      );
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flip != flip;
}
