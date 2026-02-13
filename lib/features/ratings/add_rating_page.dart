import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../controllers/rating_controller.dart';
/// Screen for adding a new ship rating.
///
/// Features:
/// - Ship autocomplete from existing database
/// - Cabin information (type, deck, count)
/// - Bridge amenities (minibar, sink, microwave)
/// - Rating sliders for each criterion
/// - Optional observations per criterion
/// - General observation field
class AddRatingPage extends StatefulWidget {
  final String imo;

  const AddRatingPage({super.key, required this.imo});

  @override
  State<AddRatingPage> createState() => _AddRatingPageState();
}

class _AddRatingPageState extends State<AddRatingPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _primaryColor = Color(0xFF3F51B5);
  static const _cabinSectionColor = Color(0xFF4CAF50);
  static const _bridgeSectionColor = Color(0xFFFF9800);
  static const _otherSectionColor = Color(0xFF607D8B);

  static const List<String> _cabinTypes = ['Pilot', 'OWNER', 'Spare Officer', 'Crew'];
  static const List<String> _cabinDecks = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  /// Rating criteria organized by section.
  static const List<String> _cabinCriteria = [
    'Temperatura da Cabine',
    'Limpeza da Cabine',
  ];

  static const List<String> _bridgeCriteria = [
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
  ];

  static const List<String> _otherCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// Icons for each criterion.
  static const Map<String, IconData> _criteriaIcons = {
    'Temperatura da Cabine': Icons.thermostat,
    'Limpeza da Cabine': Icons.cleaning_services,
    'Passadiço – Equipamentos': Icons.control_camera,
    'Passadiço – Temperatura': Icons.device_thermostat,
    'Dispositivo de Embarque/Desembarque': Icons.transfer_within_a_station,
    'Comida': Icons.restaurant,
    'Relacionamento com comandante/tripulação': Icons.handshake,
  };

  /// Colors for each criterion.
  static const Map<String, Color> _criteriaColors = {
    'Temperatura da Cabine': Color(0xFFE91E63),
    'Limpeza da Cabine': Color(0xFF4CAF50),
    'Passadiço – Equipamentos': Color(0xFFFF9800),
    'Passadiço – Temperatura': Color(0xFF9C27B0),
    'Dispositivo de Embarque/Desembarque': Color(0xFF3F51B5),
    'Comida': Color(0xFFF44336),
    'Relacionamento com comandante/tripulação': Color(0xFF00BCD4),
  };

  // ===========================================================================
  // CONTROLLERS & STATE
  // ===========================================================================

  final _formKey = GlobalKey<FormState>();
  final _ratingController = RatingController();

  final _shipNameController = TextEditingController();
  final _imoController = TextEditingController();
  final _generalObservationController = TextEditingController();
  final _crewNationalityController = TextEditingController();
  final _cabinCountController = TextEditingController();
  final _shipNameFocusNode = FocusNode();

  List<QueryDocumentSnapshot> _registeredShips = [];
  String _currentShipName = '';
  String? _selectedCabinType;
  String? _selectedCabinDeck;
  DateTime? _disembarkationDate;
  bool _isSaving = false;
  bool _shipAlreadyExists = false;

  // Bridge amenities
  bool _bridgeHasMinibar = false;
  bool _bridgeHasSink = false;
  bool _bridgeHasMicrowave = false;

  late final Map<String, double> _ratingsByItem;
  late final Map<String, TextEditingController> _observationControllers;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadShips();
    _initializeRatings();
  }

  @override
  void dispose() {
    _shipNameFocusNode.dispose();
    _shipNameController.dispose();
    _imoController.dispose();
    _generalObservationController.dispose();
    _crewNationalityController.dispose();
    _cabinCountController.dispose();
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Initializes rating maps with default values.
  void _initializeRatings() {
    final allCriteria = [..._cabinCriteria, ..._bridgeCriteria, ..._otherCriteria];
    _ratingsByItem = {for (final item in allCriteria) item: 3.0};
    _observationControllers = {
      for (final item in allCriteria) item: TextEditingController()
    };
  }

  /// Loads ships from Firestore for autocomplete.
  Future<void> _loadShips() async {
    final snapshot = await FirebaseFirestore.instance.collection('navios').get();
    if (!mounted) return;
    setState(() => _registeredShips = snapshot.docs);
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Maps Firestore criteria keys to translated display names.
  String _criteriaLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'Temperatura da Cabine': return l10n.criteriaCabinTemp;
      case 'Limpeza da Cabine': return l10n.criteriaCabinCleanliness;
      case 'Passadiço – Equipamentos': return l10n.criteriaBridgeEquipment;
      case 'Passadiço – Temperatura': return l10n.criteriaBridgeTemp;
      case 'Dispositivo de Embarque/Desembarque': return l10n.criteriaDevice;
      case 'Comida': return l10n.criteriaFood;
      case 'Relacionamento com comandante/tripulação': return l10n.criteriaRelationship;
      default: return key;
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Saves the rating to Firestore.
  Future<void> _saveRating() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validateRequiredFields()) return;

    setState(() => _isSaving = true);

    try {
      final allCriteria = [..._cabinCriteria, ..._bridgeCriteria, ..._otherCriteria];

      await _ratingController.salvarAvaliacao(
        nomeNavio: _currentShipName.trim(),
        imoInicial: _imoController.text.trim(),
        dataDesembarque: _disembarkationDate!,
        tipoCabine: _selectedCabinType!,
        deckCabine: _selectedCabinDeck,
        observacaoGeral: _generalObservationController.text.trim(),
        infoNavio: {
          'nacionalidadeTripulacao': _crewNationalityController.text.trim(),
          'numeroCabines': int.tryParse(_cabinCountController.text) ?? 0,
          'frigobar': _bridgeHasMinibar,
          'pia': _bridgeHasSink,
          'microondas': _bridgeHasMicrowave,
        },
        infoPassadico: {},
        itens: {
          for (final item in allCriteria)
            item: {
              'nota': _ratingsByItem[item]!,
              'observacao': _observationControllers[item]!.text.trim(),
            }
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Validates required fields.
  bool _validateRequiredFields() {
    if (_disembarkationDate == null || _selectedCabinType == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillRequiredFields),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  /// Opens date picker for disembarkation date.
  Future<void> _selectDisembarkationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _disembarkationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 100)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _disembarkationDate = picked);
    }
  }

  /// Handles ship selection from autocomplete.
  void _onShipSelected(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final info = (data['info'] ?? {}) as Map<String, dynamic>;

    setState(() {
      _shipAlreadyExists = true;
      _shipNameController.text = data['nome'];
      _currentShipName = data['nome'];
      _imoController.text = data['imo'] ?? '';
      _crewNationalityController.text = info['nacionalidadeTripulacao'] ?? '';
      _cabinCountController.text = info['numeroCabines']?.toString() ?? '';
    });
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
          l10n.rateShipTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildShipInfoCard(),
            const SizedBox(height: 16),
            _buildCabinSection(),
            const SizedBox(height: 16),
            _buildBridgeSection(),
            const SizedBox(height: 16),
            _buildOtherRatingsSection(),
            const SizedBox(height: 16),
            _buildGeneralObservationCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD - SAVE BUTTON
  // ===========================================================================

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  l10n.saveRating,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD - SHIP INFO SECTION
  // ===========================================================================

  Widget _buildShipInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.directions_boat,
      title: l10n.shipData,
      color: _primaryColor,
      children: [
        _buildShipAutocomplete(),
        const SizedBox(height: 16),
        _buildImoField(),
        const SizedBox(height: 16),
        _buildDisembarkationDatePicker(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _crewNationalityController,
          enabled: !_shipAlreadyExists,
          decoration: InputDecoration(
            labelText: l10n.crewNationality,
            prefixIcon: const Icon(Icons.flag, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: _shipAlreadyExists ? Colors.grey[100] : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildShipAutocomplete() {
    final l10n = AppLocalizations.of(context)!;
    return RawAutocomplete<QueryDocumentSnapshot>(
      textEditingController: _shipNameController,
      focusNode: _shipNameFocusNode,
      displayStringForOption: (opt) => opt['nome'],
      optionsBuilder: (value) {
        if (value.text.isEmpty) {
          return const Iterable<QueryDocumentSnapshot>.empty();
        }
        return _registeredShips.where((doc) {
          final nome = doc['nome'].toString().toLowerCase();
          return nome.contains(value.text.toLowerCase());
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l10n.shipName,
            prefixIcon: const Icon(Icons.directions_boat, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) => v == null || v.isEmpty ? l10n.enterShipName : null,
          onChanged: (v) {
            _currentShipName = v;
            setState(() => _shipAlreadyExists = false);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) return const SizedBox.shrink();

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            itemBuilder: (_, index) {
              final opt = options.elementAt(index);
              final data = opt.data() as Map<String, dynamic>;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_boat, color: _primaryColor),
                ),
                title: RichText(
                  text: _highlightMatch(data['nome'], _shipNameController.text),
                ),
                onTap: () {
                  onSelected(opt);
                  _onShipSelected(opt);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImoField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _imoController,
      enabled: !_shipAlreadyExists,
      decoration: InputDecoration(
        labelText: l10n.imoOptional,
        prefixIcon: const Icon(Icons.numbers, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: _shipAlreadyExists ? Colors.grey[100] : Colors.white,
      ),
    );
  }

  Widget _buildDisembarkationDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: _primaryColor),
        ),
        title: Text(
          l10n.disembarkationDate,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _disembarkationDate == null
              ? l10n.tapToSelect
              : _formatDate(_disembarkationDate!),
          style: TextStyle(
            color: _disembarkationDate == null ? Colors.grey : _primaryColor,
            fontWeight: _disembarkationDate == null
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: _primaryColor),
        onTap: _selectDisembarkationDate,
      ),
    );
  }

  // ===========================================================================
  // BUILD - CABIN SECTION
  // ===========================================================================

  Widget _buildCabinSection() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.bed,
      title: l10n.cabin,
      color: _cabinSectionColor,
      children: [
        TextFormField(
          controller: _cabinCountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.cabinCount,
            prefixIcon: const Icon(Icons.meeting_room, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _buildCabinTypeDropdown(),
        const SizedBox(height: 12),
        _buildCabinDeckDropdown(),
        const SizedBox(height: 24),
        _buildSubsectionHeader(l10n.ratings),
        const SizedBox(height: 16),
        ..._cabinCriteria.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRatingItem(c),
            )),
      ],
    );
  }

  Widget _buildCabinTypeDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: _selectedCabinType,
      decoration: InputDecoration(
        labelText: l10n.cabinType,
        prefixIcon: const Icon(Icons.king_bed, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _cabinTypes
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCabinType = v),
    );
  }

  Widget _buildCabinDeckDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: _selectedCabinDeck,
      decoration: InputDecoration(
        labelText: l10n.cabinDeck,
        prefixIcon: const Icon(Icons.layers, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _cabinDecks
          .map((e) => DropdownMenuItem(value: e, child: Text(l10n.deckLabel(e))))
          .toList(),
      onChanged: (v) => setState(() => _selectedCabinDeck = v),
    );
  }

  // ===========================================================================
  // BUILD - BRIDGE SECTION
  // ===========================================================================

  Widget _buildBridgeSection() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.navigation,
      title: l10n.bridge,
      color: _bridgeSectionColor,
      children: [
        _buildAmenitiesContainer(),
        const SizedBox(height: 24),
        _buildSubsectionHeader(l10n.ratings),
        const SizedBox(height: 16),
        ..._bridgeCriteria.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRatingItem(c),
            )),
      ],
    );
  }

  Widget _buildAmenitiesContainer() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildAmenitySwitch(
            title: l10n.hasMinibar,
            icon: Icons.kitchen,
            value: _bridgeHasMinibar,
            onChanged: (v) => setState(() => _bridgeHasMinibar = v),
          ),
          const Divider(height: 1),
          _buildAmenitySwitch(
            title: l10n.hasSink,
            icon: Icons.water_drop,
            value: _bridgeHasSink,
            onChanged: (v) => setState(() => _bridgeHasSink = v),
          ),
          const Divider(height: 1),
          _buildAmenitySwitch(
            title: l10n.hasMicrowave,
            icon: Icons.microwave,
            value: _bridgeHasMicrowave,
            onChanged: (v) => setState(() => _bridgeHasMicrowave = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitySwitch({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon, color: _bridgeSectionColor),
      value: value,
      activeColor: _bridgeSectionColor,
      onChanged: onChanged,
    );
  }

  // ===========================================================================
  // BUILD - OTHER RATINGS SECTION
  // ===========================================================================

  Widget _buildOtherRatingsSection() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.star,
      title: l10n.otherRatings,
      color: _primaryColor,
      children: _otherCriteria
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRatingItem(c),
              ))
          .toList(),
    );
  }

  // ===========================================================================
  // BUILD - GENERAL OBSERVATION
  // ===========================================================================

  Widget _buildGeneralObservationCard() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.notes,
      title: l10n.generalObservation,
      color: _otherSectionColor,
      children: [
        TextFormField(
          controller: _generalObservationController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.generalObservationHint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // BUILD - REUSABLE COMPONENTS
  // ===========================================================================

  Widget _buildSubsectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(String item) {
    final l10n = AppLocalizations.of(context)!;
    final score = _ratingsByItem[item]!;
    final icon = _criteriaIcons[item] ?? Icons.star;
    final color = _criteriaColors[item] ?? _primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Criterion header
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _criteriaLabel(item),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              _buildScoreBadge(score, color),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          _buildRatingSlider(item, score, color),
          const SizedBox(height: 8),

          // Observation field
          TextField(
            controller: _observationControllers[item],
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: l10n.observationsOptional,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSlider(String item, double score, Color color) {
    return Row(
      children: [
        const Text('1.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(51),
              thumbColor: color,
              overlayColor: color.withAlpha(51),
              valueIndicatorColor: color,
            ),
            child: Slider(
              value: score,
              min: 1,
              max: 5,
              divisions: 8,
              label: score.toStringAsFixed(1),
              onChanged: (v) => setState(() => _ratingsByItem[item] = v),
            ),
          ),
        ),
        const Text('5.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Highlights matching characters in autocomplete.
  TextSpan _highlightMatch(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);

    final queryChars = query.toLowerCase().split('');
    return TextSpan(
      children: text.split('').map((char) {
        final isMatch = queryChars.contains(char.toLowerCase());
        return TextSpan(
          text: char,
          style: TextStyle(
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        );
      }).toList(),
    );
  }

  /// Formats date for display.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// =============================================================================
// SECTION CARD WIDGET
// =============================================================================

/// Reusable card widget for form sections.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
