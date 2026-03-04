import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
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

  // Deep Ocean theme colors
  static const _accentBlue = Color(0xFF64B5F6);
  static const _fieldBg = Color(0x0FFFFFFF);
  static const _fieldBorder = Color(0x1F64B5F6);
  static const _hintColor = Color(0x59FFFFFF);
  static const _labelColor = Color(0x99FFFFFF);
  static const _iconBg = Color(0x2664B5F6);
  static const _warningColor = Colors.orange;

  static const List<String> _cabinTypes = ['Pilot', 'OWNER', 'Spare Officer', 'Crew'];
  static const List<String> _cabinDecks = ['bridge', '1_below', '2_below', '3_below', '4+_below'];

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
  late TextEditingController _otherNationalityController;
  final Set<String> _selectedNationalities = {};
  bool _showOtherNationalityField = false;
  String? _selectedCabinCount;

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
    _otherNationalityController.dispose();
    for (final controller in _observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    _shipNameController = TextEditingController();
    _shipImoController = TextEditingController();
    _observacaoGeralController = TextEditingController();
    _otherNationalityController = TextEditingController();
  }

  /// Converts legacy int or string cabin count to dropdown value.
  String? _normalizeCabinCount(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      if (['1', '2', '3+'].contains(value)) return value;
      return null;
    }
    if (value is int) {
      if (value <= 0) return null;
      if (value == 1) return '1';
      if (value == 2) return '2';
      return '3+';
    }
    return null;
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
          _cabinDeck = _cabinDecks.contains(data.cabinDeck) ? data.cabinDeck : null;
          _observacaoGeralController.text = data.generalObservation;

          // Load ship info
          _loadNationalitiesFromData(data.shipInfo['nacionalidadeTripulacao']);
          _selectedCabinCount = _normalizeCabinCount(data.shipInfo['numeroCabines']);

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
  // NATIONALITY HELPERS
  // ===========================================================================

  static const List<String> _nationalityKeys = [
    'Filipino', 'Russian', 'Ukrainian', 'Indian', 'Chinese', 'Brazilian',
  ];

  String _nationalityLabel(String key) {
    final l10n = AppLocalizations.of(context)!;
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

  List<String> _buildNationalityList() {
    final list = <String>[..._selectedNationalities];
    if (_showOtherNationalityField) {
      final other = _otherNationalityController.text.trim();
      if (other.isNotEmpty) list.add(other);
    }
    return list;
  }

  void _loadNationalitiesFromData(dynamic value) {
    _selectedNationalities.clear();
    _showOtherNationalityField = false;
    _otherNationalityController.clear();

    if (value == null) return;

    List<String> nationalities;
    if (value is List) {
      nationalities = value.map((e) => e.toString()).toList();
    } else {
      nationalities = [value.toString()];
    }

    for (final n in nationalities) {
      if (_nationalityKeys.contains(n)) {
        _selectedNationalities.add(n);
      } else if (n.isNotEmpty) {
        _showOtherNationalityField = true;
        _otherNationalityController.text = n;
      }
    }
  }

  Widget _buildNationalityChips() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.crewNationality,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._nationalityKeys.map((key) {
              final selected = _selectedNationalities.contains(key);
              return FilterChip(
                label: Text(
                  _nationalityLabel(key),
                  style: TextStyle(
                    color: selected ? const Color(0xFF64B5F6) : const Color(0xFF1E3A5F),
                  ),
                ),
                selected: selected,
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedNationalities.add(key);
                    } else {
                      _selectedNationalities.remove(key);
                    }
                  });
                },
                backgroundColor: _fieldBg,
                selectedColor: _iconBg,
                side: BorderSide(
                  color: selected ? _accentBlue : _fieldBorder,
                ),
                checkmarkColor: _accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
            Builder(builder: (_) {
              final selected = _showOtherNationalityField;
              return FilterChip(
                label: Text(
                  l10n.nationalityOther,
                  style: TextStyle(
                    color: selected ? const Color(0xFF64B5F6) : const Color(0xFF1E3A5F),
                  ),
                ),
                selected: selected,
                onSelected: (sel) {
                  setState(() {
                    _showOtherNationalityField = sel;
                    if (!sel) _otherNationalityController.clear();
                  });
                },
                backgroundColor: _fieldBg,
                selectedColor: _iconBg,
                side: BorderSide(
                  color: selected ? _accentBlue : _fieldBorder,
                ),
                checkmarkColor: _accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ],
        ),
        if (_showOtherNationalityField) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherNationalityController,
            style: const TextStyle(color: Colors.white),
            decoration: _darkInputDecoration(
              labelText: l10n.specifyNationality,
              prefixIcon: Icons.edit,
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Common InputDecoration for dark-themed text fields.
  InputDecoration _darkInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: _labelColor),
      prefixIcon: Icon(prefixIcon, size: 20, color: _accentBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentBlue, width: 1.5),
      ),
      filled: true,
      fillColor: enabled ? _fieldBg : const Color(0x08FFFFFF),
    );
  }

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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF0D2137),
              onSurface: Colors.white,
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
      shipName: _shipNameController.text.trim().toUpperCase(),
      disembarkationDate: _disembarkationDate,
      cabinType: _cabinType,
    );

    if (validationError != null) {
      final l10n = AppLocalizations.of(context)!;
      final message = switch (validationError) {
        ValidationError.emptyShipName => l10n.enterShipName,
        ValidationError.missingDate => l10n.fillRequiredFields,
        ValidationError.missingCabinType => l10n.fillRequiredFields,
      };
      _showWarningSnackBar(message);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _controller.saveChanges(
        ratingRef: widget.rating.reference,
        shipRef: _shipRef!,
        updateData: RatingUpdateData(
          shipName: _shipNameController.text.trim().toUpperCase(),
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
            'nacionalidadeTripulacao': _buildNationalityList(),
            'numeroCabines': _selectedCabinCount,
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
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(
          title: Text(l10n.editRatingTitle),
          backgroundColor: const Color(0xFF0A1628),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _accentBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: Text(
          l10n.editRatingTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBar: _buildSaveButton(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: Form(
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
      ),
    );
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1628),
      ),
      child: SafeArea(
        child: Container(
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
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
        color: _warningColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warningColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _warningColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.editWarningBanner,
              style: const TextStyle(
                fontSize: 13,
                color: _warningColor,
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
    return _DeepOceanSectionCard(
      icon: Icons.directions_boat,
      title: l10n.shipData,
      children: [
        TextFormField(
          controller: _shipNameController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInputDecoration(
            labelText: l10n.shipNameRequired,
            prefixIcon: Icons.directions_boat,
          ),
          validator: (v) =>
              v == null || v.isEmpty ? l10n.enterShipName : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shipImoController,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInputDecoration(
            labelText: l10n.imoOptional,
            prefixIcon: Icons.numbers,
          ),
        ),
        const SizedBox(height: 16),
        _buildDisembarkationDatePicker(),
        const SizedBox(height: 16),
        _buildNationalityChips(),
      ],
    );
  }

  Widget _buildDisembarkationDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        border: Border.all(color: _fieldBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event, color: _accentBlue),
        ),
        title: Text(
          l10n.disembarkationDateRequired,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color(0xD9FFFFFF),
          ),
        ),
        subtitle: Text(
          _disembarkationDate == null
              ? l10n.tapToSelect
              : _formatDate(_disembarkationDate!),
          style: TextStyle(
            color: _disembarkationDate == null
                ? const Color(0x66FFFFFF)
                : _accentBlue,
            fontWeight: _disembarkationDate == null
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0x66FFFFFF)),
        onTap: _selectDisembarkationDate,
      ),
    );
  }

  Widget _buildCabinSection() {
    final l10n = AppLocalizations.of(context)!;
    return _DeepOceanSectionCard(
      icon: Icons.bed,
      title: l10n.cabin,
      children: [
        _buildDarkDropdown(
          value: _selectedCabinCount,
          labelText: l10n.cabinCount,
          prefixIcon: Icons.meeting_room,
          items: [
            DropdownMenuItem(value: '1', child: Text(l10n.cabinCountOne)),
            DropdownMenuItem(value: '2', child: Text(l10n.cabinCountTwo)),
            DropdownMenuItem(value: '3+', child: Text(l10n.cabinCountMoreThanTwo)),
          ],
          onChanged: (v) => setState(() => _selectedCabinCount = v),
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

  Widget _buildDarkDropdown({
    required String? value,
    required String labelText,
    required IconData prefixIcon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0D2137),
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: const Color(0x66FFFFFF),
      decoration: _darkInputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildCabinTypeDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return _buildDarkDropdown(
      value: _cabinType,
      labelText: l10n.cabinTypeRequired,
      prefixIcon: Icons.king_bed,
      items: _cabinTypes
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _cabinType = v),
    );
  }

  Widget _buildCabinDeckDropdown() {
    final l10n = AppLocalizations.of(context)!;
    return _buildDarkDropdown(
      value: _cabinDeck,
      labelText: l10n.cabinDeck,
      prefixIcon: Icons.layers,
      items: _cabinDecks
          .map((e) => DropdownMenuItem(value: e, child: Text(_deckLabel(l10n, e))))
          .toList(),
      onChanged: (v) => setState(() => _cabinDeck = v),
    );
  }

  /// Returns localized label for a deck key.
  String _deckLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'bridge': return l10n.deckBridge;
      case '1_below': return l10n.deck1Below;
      case '2_below': return l10n.deck2Below;
      case '3_below': return l10n.deck3Below;
      case '4+_below': return l10n.deck4PlusBelow;
      default: return key;
    }
  }

  Widget _buildBridgeSection() {
    final l10n = AppLocalizations.of(context)!;
    return _DeepOceanSectionCard(
      icon: Icons.navigation,
      title: l10n.bridge,
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
        color: _fieldBg,
        border: Border.all(color: _fieldBorder),
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
          Divider(height: 1, color: _fieldBorder),
          _buildAmenitySwitch(
            title: l10n.hasSink,
            icon: Icons.water_drop,
            value: _bridgeHasSink,
            onChanged: (v) => setState(() => _bridgeHasSink = v),
          ),
          Divider(height: 1, color: _fieldBorder),
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
      title: Text(title, style: const TextStyle(color: Colors.white)),
      secondary: Icon(icon, color: _accentBlue),
      value: value,
      activeColor: _accentBlue,
      onChanged: onChanged,
    );
  }

  Widget _buildOtherRatingsSection() {
    final l10n = AppLocalizations.of(context)!;
    return _DeepOceanSectionCard(
      icon: Icons.star,
      title: l10n.otherRatings,
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
    return _DeepOceanSectionCard(
      icon: Icons.notes,
      title: l10n.generalObservation,
      children: [
        TextFormField(
          controller: _observacaoGeralController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.generalObservationHint,
            hintStyle: const TextStyle(fontSize: 14, color: _hintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accentBlue, width: 1.5),
            ),
            filled: true,
            fillColor: _fieldBg,
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
            color: _accentBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(String item) {
    final l10n = AppLocalizations.of(context)!;
    final score = _ratings[item]!;
    final icon = _criteriaIcons[item] ?? Icons.star;
    final color = _criteriaColors[item] ?? _accentBlue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder),
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
                    color: Colors.white,
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
            style: const TextStyle(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.observationsOptional,
              hintStyle: const TextStyle(fontSize: 13, color: _hintColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              filled: true,
              fillColor: _fieldBg,
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
        color: color.withAlpha(38),
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
        const Text('1.0', style: TextStyle(fontSize: 11, color: _labelColor)),
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
        const Text('5.0', style: TextStyle(fontSize: 11, color: _labelColor)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// =============================================================================
// DEEP OCEAN SECTION CARD WIDGET
// =============================================================================

/// Reusable card widget for form sections with Deep Ocean theme.
class _DeepOceanSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _DeepOceanSectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A64B5F6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x2664B5F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF64B5F6), size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
