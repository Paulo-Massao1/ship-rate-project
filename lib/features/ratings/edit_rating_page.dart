import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../controllers/edit_rating_controller.dart';
/// Screen for editing an existing ship rating.
///
/// Important: This screen is intended for correcting typos and errors only,
/// not for updating ratings due to ship changes over time.
class EditRatingPage extends StatefulWidget {
  final QueryDocumentSnapshot rating;

  const EditRatingPage({super.key, required this.rating});

  @override
  State<EditRatingPage> createState() => _EditRatingPageState();
}

class _EditRatingPageState extends State<EditRatingPage> {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _primaryColor = Colors.orange;
  static const _cabinSectionColor = Color(0xFF4CAF50);
  static const _bridgeSectionColor = Color(0xFFFF9800);
  static const _otherSectionColor = Color(0xFF3F51B5);

  static const List<String> _cabinTypes = ['Pilot', 'OWNER', 'Spare Officer', 'Crew'];
  static const List<String> _cabinDecks = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

  static const Map<String, IconData> _criteriaIcons = {
    'Temperatura da Cabine': Icons.thermostat,
    'Limpeza da Cabine': Icons.cleaning_services,
    'Passadiço – Equipamentos': Icons.control_camera,
    'Passadiço – Temperatura': Icons.device_thermostat,
    'Dispositivo de Embarque/Desembarque': Icons.transfer_within_a_station,
    'Comida': Icons.restaurant,
    'Relacionamento com comandante/tripulação': Icons.handshake,
  };

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
  // CONTROLLER & STATE
  // ===========================================================================

  final _controller = EditRatingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _shipNameController;
  late TextEditingController _shipImoController;
  late TextEditingController _observacaoGeralController;
  late TextEditingController _crewNationalityController;
  late TextEditingController _cabinCountController;

  DateTime? _disembarkationDate;
  String? _cabinType;
  String? _cabinDeck;

  bool _bridgeHasMinibar = false;
  bool _bridgeHasSink = false;
  bool _bridgeHasMicrowave = false;

  late Map<String, double> _ratings;
  late Map<String, TextEditingController> _observationControllers;

  DocumentReference? _shipRef;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeRatings();
    _loadExistingData();
  }

  @override
  void dispose() {
    _shipNameController.dispose();
    _shipImoController.dispose();
    _observacaoGeralController.dispose();
    _crewNationalityController.dispose();
    _cabinCountController.dispose();
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _shipNameController = TextEditingController();
    _shipImoController = TextEditingController();
    _observacaoGeralController = TextEditingController();
    _crewNationalityController = TextEditingController();
    _cabinCountController = TextEditingController();
  }

  void _initializeRatings() {
    _ratings = {for (final item in _controller.allCriteria) item: 3.0};
    _observationControllers = {
      for (final item in _controller.allCriteria) item: TextEditingController()
    };
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await _controller.loadRatingData(widget.rating);

      if (mounted) {
        setState(() {
          _shipRef = data.shipRef;
          _shipNameController.text = data.shipName;
          _shipImoController.text = data.shipImo;
          _disembarkationDate = data.disembarkationDate;
          _cabinType = data.cabinType;
          _cabinDeck = data.cabinDeck;
          _observacaoGeralController.text = data.generalObservation;

          // Load ship info
          _crewNationalityController.text =
              data.shipInfo['nacionalidadeTripulacao'] ?? '';
          final cabinCount = data.shipInfo['numeroCabines'];
          _cabinCountController.text = cabinCount?.toString() ?? '';

          // Load bridge info
          _bridgeHasMinibar = data.bridgeInfo['frigobar'] ?? false;
          _bridgeHasSink = data.bridgeInfo['pia'] ?? false;
          _bridgeHasMicrowave = data.bridgeInfo['microondas'] ?? false;

          // Load ratings
          data.ratingItems.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              final nota = value['nota'];
              final observacao = value['observacao'] ?? '';

              if (_ratings.containsKey(key) && nota is num) {
                _ratings[key] = nota.toDouble();
              }
              if (_observationControllers.containsKey(key)) {
                _observationControllers[key]!.text = observacao;
              }
            }
          });

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar(AppLocalizations.of(context)!.errorLoadingData(e.toString()));
      }
    }
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

  Future<void> _selectDisembarkationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _disembarkationDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final validationError = _controller.validateFields(
      shipName: _shipNameController.text.trim(),
      disembarkationDate: _disembarkationDate,
      cabinType: _cabinType,
    );

    if (validationError != null) {
      _showWarningSnackBar(validationError);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final cabinCountText = _cabinCountController.text.trim();

      await _controller.saveChanges(
        ratingRef: widget.rating.reference,
        shipRef: _shipRef!,
        updateData: RatingUpdateData(
          shipName: _shipNameController.text.trim(),
          shipImo: _shipImoController.text.trim(),
          disembarkationDate: _disembarkationDate!,
          cabinType: _cabinType!,
          cabinDeck: _cabinDeck,
          generalObservation: _observacaoGeralController.text.trim(),
          ratings: Map.from(_ratings),
          observations: {
            for (final entry in _observationControllers.entries)
              entry.key: entry.value.text.trim()
          },
          shipInfo: {
            'nacionalidadeTripulacao':
                _crewNationalityController.text.trim().isNotEmpty
                    ? _crewNationalityController.text.trim()
                    : null,
            'numeroCabines':
                cabinCountText.isNotEmpty ? int.tryParse(cabinCountText) : null,
          },
          bridgeInfo: {
            'frigobar': _bridgeHasMinibar,
            'pia': _bridgeHasSink,
            'microondas': _bridgeHasMicrowave,
          },
        ),
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessSnackBar(l10n.ratingUpdatedSuccess);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorSaving(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ===========================================================================
  // SNACKBAR HELPERS
  // ===========================================================================

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text(l10n.editRatingTitle),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          l10n.editRatingTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWarningBanner(),
            const SizedBox(height: 16),
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
          onPressed: _isSaving ? null : _saveChanges,
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
                  l10n.saveChanges,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.editWarningBanner,
              style: const TextStyle(
                fontSize: 13,
                color: _primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.directions_boat,
      title: l10n.shipData,
      color: _primaryColor,
      children: [
        TextFormField(
          controller: _shipNameController,
          decoration: InputDecoration(
            labelText: l10n.shipNameRequired,
            prefixIcon: const Icon(Icons.directions_boat, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) =>
              v == null || v.isEmpty ? l10n.enterShipName : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shipImoController,
          decoration: InputDecoration(
            labelText: l10n.imoOptional,
            prefixIcon: const Icon(Icons.numbers, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildDisembarkationDatePicker(),
        const SizedBox(height: 16),
        TextFormField(
          controller: _crewNationalityController,
          decoration: InputDecoration(
            labelText: l10n.crewNationality,
            prefixIcon: const Icon(Icons.flag, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
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
          l10n.disembarkationDateRequired,
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
        ...EditRatingController.cabinCriteria.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRatingItem(c),
          ),
        ),
      ],
    );
  }

  Widget _buildCabinTypeDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: _cabinType,
      decoration: InputDecoration(
        labelText: l10n.cabinTypeRequired,
        prefixIcon: const Icon(Icons.king_bed, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _cabinTypes
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _cabinType = v),
    );
  }

  Widget _buildCabinDeckDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: _cabinDeck,
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
      onChanged: (v) => setState(() => _cabinDeck = v),
    );
  }

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
        ...EditRatingController.bridgeCriteria.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRatingItem(c),
          ),
        ),
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

  Widget _buildOtherRatingsSection() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.star,
      title: l10n.otherRatings,
      color: _otherSectionColor,
      children: EditRatingController.otherCriteria
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRatingItem(c),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGeneralObservationCard() {
    final l10n = AppLocalizations.of(context)!;
    return _SectionCard(
      icon: Icons.notes,
      title: l10n.generalObservation,
      color: const Color(0xFF607D8B),
      children: [
        TextFormField(
          controller: _observacaoGeralController,
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
    final score = _ratings[item]!;
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
          _buildRatingSlider(item, score, color),
          const SizedBox(height: 8),
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
              onChanged: (v) => setState(() => _ratings[item] = v),
            ),
          ),
        ),
        const Text('5.0', style: TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// =============================================================================
// SECTION CARD WIDGET
// =============================================================================

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
