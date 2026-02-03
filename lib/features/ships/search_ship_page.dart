import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../controllers/ship_search_controller.dart';
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

  static const _primaryColor = Color(0xFF3F51B5);
  static const _tabBackgroundColor = Color(0xFFE9EAEE);

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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE6E6EA)),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F9),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avaliação de Navios',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pesquise avaliações ou registre sua experiência',
            style: TextStyle(
              color: Colors.black54,
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
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _tabBackgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.black87,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Buscar'),
          Tab(text: 'Avaliar'),
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
  // CONSTANTS
  // ===========================================================================

  static const _primaryColor = Color(0xFF3F51B5);

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
      _searchTextController.text = (doc.data() as Map)['nome'];
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
    return TextField(
      controller: _searchTextController,
      onChanged: _updateSuggestions,
      decoration: InputDecoration(
        hintText: 'Buscar por nome do navio ou IMO',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: ListView.separated(
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey[200]),
          itemBuilder: (_, index) {
            final doc = _suggestions[index];
            final data = doc.data() as Map;

            return ListTile(
              leading: const Icon(Icons.directions_boat),
              title: _HighlightedText(
                text: data['nome'],
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
    // No search yet - show background image
    if (_selectedShip == null && _suggestions.isEmpty) {
      return Expanded(
        child: Opacity(
          opacity: 0.95,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/images/navio3.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Ship selected - show details and ratings
    if (_selectedShip != null) {
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
              const Text(
                'Avaliações',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  static const _overlayColor = Color(0xFF2F3E9E);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/navio2.png', fit: BoxFit.cover),
        Container(color: Colors.black.withAlpha(115)),
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nova Avaliação de Navio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Registre sua avaliação técnica de forma rápida e segura',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _overlayColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withAlpha(64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _navigateToAddRating(context),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 18),
            SizedBox(width: 10),
            Text(
              'Iniciar avaliação',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddRating(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRatingPage(imo: '')),
    );
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
              shipData.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMarineTrafficButton(context, data),
            if (infoItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Informações Gerais',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInfoGrid(context, infoItems),
            ],
            if (shipData.averages.isNotEmpty) ...[
              const Divider(height: 32),
              const Text(
                'Médias das Avaliações',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAveragesList(shipData.averages),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openMarineTraffic(context, data),
        icon: const Icon(Icons.waves, size: 20),
        label: const Text(
          'Ver Detalhes no MarineTraffic',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
    final success = await controller.openMarineTraffic(
      shipName: data['nome'],
      imo: data['imo'],
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir MarineTraffic'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Widget> _buildInfoItems(
    BuildContext context,
    Map<String, dynamic> info,
  ) {
    final items = <Widget>[];

    // Crew nationality
    if (info['nacionalidadeTripulacao'] != null &&
        info['nacionalidadeTripulacao'].toString().isNotEmpty) {
      items.add(_buildInfoItem(
        Icons.groups,
        'Tripulação',
        info['nacionalidadeTripulacao'],
      ));
    }

    // Cabin count
    if (info['numeroCabines'] != null && info['numeroCabines'] != 0) {
      items.add(_buildInfoItem(
        Icons.bed,
        'Cabines',
        info['numeroCabines'].toString(),
      ));
    }

    // Amenities
    final amenities = controller.resolveAmenities(info, ratings);

    if (amenities['frigobar'] != null) {
      items.add(_buildInfoItem(
        Icons.kitchen,
        'Frigobar',
        amenities['frigobar']! ? 'Sim' : 'Não',
      ));
    }

    if (amenities['pia'] != null) {
      items.add(_buildInfoItem(
        Icons.water_drop,
        'Pia',
        amenities['pia']! ? 'Sim' : 'Não',
      ));
    }

    if (amenities['microondas'] != null) {
      items.add(_buildInfoItem(
        Icons.microwave,
        'Micro-ondas',
        amenities['microondas']! ? 'Sim' : 'Não',
      ));
    }

    return items;
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

  Widget _buildAveragesList(Map<String, dynamic> averages) {
    return Column(
      children: [
        if (averages['temp_cabine'] != null)
          _buildAverageItem(
            Icons.thermostat,
            'Temp. Cabine',
            averages['temp_cabine'].toString(),
          ),
        if (averages['limpeza_cabine'] != null)
          _buildAverageItem(
            Icons.cleaning_services,
            'Limpeza Cabine',
            averages['limpeza_cabine'].toString(),
          ),
        if (averages['passadico_equip'] != null)
          _buildAverageItem(
            Icons.control_camera,
            'Equip. Passadiço',
            averages['passadico_equip'].toString(),
          ),
        if (averages['passadico_temp'] != null)
          _buildAverageItem(
            Icons.device_thermostat,
            'Temp. Passadiço',
            averages['passadico_temp'].toString(),
          ),
        if (averages['comida'] != null)
          _buildAverageItem(
            Icons.restaurant,
            'Alimentação',
            averages['comida'].toString(),
          ),
        if (averages['relacionamento'] != null)
          _buildAverageItem(
            Icons.handshake,
            'Relacionamento',
            averages['relacionamento'].toString(),
          ),
        if (averages['dispositivo'] != null)
          _buildAverageItem(
            Icons.transfer_within_a_station,
            'Dispositivo',
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
    final data = doc.data() as Map<String, dynamic>;
    final callSign = data['nomeGuerra'] ?? 'Prático';
    final timestamp = data['createdAt'] as Timestamp?;
    final relativeTime = controller.getRelativeTime(timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.person, color: Colors.indigo),
        title: Text(
          'Prático: $callSign',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visualizar avaliação',
              style: TextStyle(
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
    if (query.isEmpty) return Text(text);

    final queryChars = query.toLowerCase().split('');

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: text.split('').map((char) {
          final isMatch = queryChars.contains(char.toLowerCase());
          return TextSpan(
            text: char,
            style: TextStyle(
              fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}