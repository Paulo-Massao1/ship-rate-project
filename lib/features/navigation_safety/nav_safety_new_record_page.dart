import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import '../../controllers/nav_safety_controller.dart';

/// Form screen for registering a new depth/passage record.
class NavSafetyNewRecordPage extends StatefulWidget {
  const NavSafetyNewRecordPage({super.key});

  @override
  State<NavSafetyNewRecordPage> createState() =>
      _NavSafetyNewRecordPageState();
}

class _NavSafetyNewRecordPageState extends State<NavSafetyNewRecordPage>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const _teal = Color(0xFF26A69A);
  static const _tealLight = Color(0x1426A69A);
  static const _tealBorder = Color(0x3326A69A);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _fieldBg = Color(0x0FFFFFFF);
  static const _fieldBorder = Color(0x1F64B5F6);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xD9FFFFFF);
  static const _textMuted = Color(0x66FFFFFF);
  static const _textLabel = Color(0x99FFFFFF);
  static const _inputBg = Color(0x0FFFFFFF);
  static const _inputBorder = Color(0x1F26A69A);
  static const _dropdownBg = Color(0xFF132D4A);

  // ===========================================================================
  // STATE
  // ===========================================================================

  final NavSafetyController _controller = NavSafetyController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Locations
  List<LocationWithLatestRecord> _locations = [];
  bool _isLoadingLocations = true;
  String? _selectedLocationId;
  String? _selectedLocationName;

  // Add new location
  bool _showNewLocationInput = false;
  final _newLocationController = TextEditingController();

  // Fundeadouro Itacoatiara point
  int? _selectedPoint;

  // Ship name
  final _shipNameController = TextEditingController();

  // Date
  DateTime _selectedDate = DateTime.now();

  // Direction
  String? _direction; // 'subindo' or 'baixando'

  // Depth
  final _depthController = TextEditingController();

  // Complementary data
  final _maxDraftController = TextEditingController();
  final _ukcController = TextEditingController();
  final _speedController = TextEditingController();
  String? _squatConsidered; // 'sim' or 'nao'
  String? _sonarPosition; // 'proa' or 'popa'

  // LAT/LONG
  bool _latLongExpanded = false;
  late AnimationController _arrowAnimController;
  late Animation<double> _arrowAnim;
  final _latDegController = TextEditingController();
  final _latMinController = TextEditingController();
  final _latSecController = TextEditingController();
  String _latHemisphere = 'S';
  final _lonDegController = TextEditingController();
  final _lonMinController = TextEditingController();
  final _lonSecController = TextEditingController();
  String _lonHemisphere = 'W';

  // Observations
  final _observationsController = TextEditingController();

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _arrowAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );
    _loadLocations();
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    _newLocationController.dispose();
    _shipNameController.dispose();
    _depthController.dispose();
    _maxDraftController.dispose();
    _ukcController.dispose();
    _speedController.dispose();
    _latDegController.dispose();
    _latMinController.dispose();
    _latSecController.dispose();
    _lonDegController.dispose();
    _lonMinController.dispose();
    _lonSecController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  Future<void> _loadLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('locais')
          .orderBy('nome')
          .get();

      final locs = snapshot.docs
          .map((doc) => LocationWithLatestRecord(
                id: doc.id,
                name: (doc.data()['nome'] ?? '').toString(),
              ))
          .toList();

      if (mounted) {
        setState(() {
          _locations = locs;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      debugPrint('[NavSafety] Error loading locations: $e');
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _teal,
              surface: _bgMid,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool get _isItacoatiara {
    if (_selectedLocationName == null) return false;
    return _selectedLocationName!
        .toLowerCase()
        .contains('fundeadouro itacoatiara');
  }

  String? _validate() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedLocationId == null) return l10n.locationRequired;
    if (_depthController.text.trim().isEmpty) return l10n.depthRequired;
    if (_maxDraftController.text.trim().isEmpty) return l10n.draftRequired;
    if (_ukcController.text.trim().isEmpty) return l10n.ukcRequired;
    if (_direction == null) return l10n.directionRequired;
    if (_sonarPosition == null) return l10n.sonarRequired;
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final data = <String, dynamic>{
        'profundidadeTotal': double.tryParse(_depthController.text.trim()),
        'caladoMax': double.tryParse(_maxDraftController.text.trim()),
        'ukc': double.tryParse(_ukcController.text.trim()),
        'direcao': _direction,
        'posicaoSonda': _sonarPosition,
        'data': Timestamp.fromDate(_selectedDate),
        'pilotId': user?.uid ?? '',
        'nomeGuerra': user?.displayName ?? '',
      };

      // Optional fields
      final shipName = _shipNameController.text.trim();
      if (shipName.isNotEmpty) data['nomeNavio'] = shipName;

      final speed = double.tryParse(_speedController.text.trim());
      if (speed != null) data['velocidade'] = speed;

      if (_squatConsidered != null) {
        data['squatConsiderado'] = _squatConsidered == 'sim';
      }

      if (_isItacoatiara && _selectedPoint != null) {
        data['ponto'] = _selectedPoint;
      }

      // LAT/LONG
      if (_latDegController.text.isNotEmpty ||
          _lonDegController.text.isNotEmpty) {
        data['latitude'] = {
          'graus': int.tryParse(_latDegController.text) ?? 0,
          'minutos': int.tryParse(_latMinController.text) ?? 0,
          'segundos': _latSecController.text.trim(),
          'hemisferio': _latHemisphere,
        };
        data['longitude'] = {
          'graus': int.tryParse(_lonDegController.text) ?? 0,
          'minutos': int.tryParse(_lonMinController.text) ?? 0,
          'segundos': _lonSecController.text.trim(),
          'hemisferio': _lonHemisphere,
        };
      }

      final obs = _observationsController.text.trim();
      if (obs.isNotEmpty) data['observacoes'] = obs;

      await _controller.saveRecord(_selectedLocationId!, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.recordSavedSuccess),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addNewLocation() async {
    final name = _newLocationController.text.trim();
    if (name.isEmpty) return;

    try {
      final id = await _controller.addLocation(name);
      final newLoc = LocationWithLatestRecord(id: id, name: name);
      setState(() {
        _locations.add(newLoc);
        _locations.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _selectedLocationId = id;
        _selectedLocationName = name;
        _showNewLocationInput = false;
        _newLocationController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildSection1PassageData(l10n),
              const SizedBox(height: 16),
              _buildSection2TotalDepth(l10n),
              const SizedBox(height: 16),
              _buildSection3ComplementaryData(l10n),
              const SizedBox(height: 16),
              _buildSection4LatLong(l10n),
              const SizedBox(height: 16),
              _buildSection5Observations(l10n),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSaveButton(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.newRecord,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _textPrimary,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimary,
      elevation: 4,
      shadowColor: Colors.black54,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgDark, Color(0xFF1A3A5C), _bgMid],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1 — PASSAGE DATA
  // ===========================================================================

  Widget _buildSection1PassageData(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.place,
      title: l10n.passageData,
      children: [
        _buildLocationDropdown(l10n),
        if (_isItacoatiara) ...[
          const SizedBox(height: 14),
          _buildPointDropdown(l10n),
        ],
        const SizedBox(height: 14),
        _buildTextField(
          controller: _shipNameController,
          label: l10n.shipNameOptional,
          icon: Icons.directions_boat,
          iconColor: const Color(0xFF64B5F6),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 14),
        _buildDateField(l10n),
        const SizedBox(height: 14),
        _buildDirectionToggle(l10n),
      ],
    );
  }

  Widget _buildLocationDropdown(AppLocalizations l10n) {
    if (_isLoadingLocations) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectLocation,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _dropdownBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x3326A69A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLocationId,
              hint: Text(
                l10n.selectLocation,
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),
              isExpanded: true,
              dropdownColor: _dropdownBg,
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: const Icon(Icons.arrow_drop_down, color: _teal),
              menuMaxHeight: 300,
              items: [
                ..._locations.map((loc) => DropdownMenuItem<String>(
                      value: loc.id,
                      child: Text(
                        '\u{1F4CD} ${loc.name}',
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 14),
                      ),
                    )),
              ],
              onChanged: (value) {
                if (value == null) return;
                final loc = _locations.firstWhere((l) => l.id == value);
                setState(() {
                  _selectedLocationId = loc.id;
                  _selectedLocationName = loc.name;
                  _selectedPoint = null;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_showNewLocationInput) ...[
          Row(
            children: [
              Expanded(
                child: _buildRawTextField(
                  controller: _newLocationController,
                  hint: l10n.newLocationName,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addNewLocation,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _tealBorder),
                  ),
                  child: const Icon(Icons.check, color: _teal, size: 20),
                ),
              ),
            ],
          ),
        ] else
          GestureDetector(
            onTap: () => setState(() => _showNewLocationInput = true),
            child: Row(
              children: [
                const Icon(Icons.add, color: _teal, size: 18),
                const SizedBox(width: 6),
                Text(
                  l10n.addNewLocation,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPointDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.anchoragePt,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _dropdownBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x3326A69A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedPoint,
              hint: Text(
                l10n.anchoragePt,
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),
              isExpanded: true,
              dropdownColor: _dropdownBg,
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              icon: const Icon(Icons.arrow_drop_down, color: _teal),
              items: List.generate(
                15,
                (i) => DropdownMenuItem<int>(
                  value: i + 1,
                  child: Text(
                    '${i + 1}',
                    style:
                        const TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                ),
              ),
              onChanged: (value) => setState(() => _selectedPoint = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.passageDate,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _inputBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: _teal, size: 18),
                const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionToggle(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.direction,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildToggleBtn(
              label: l10n.goingUp,
              isActive: _direction == 'subindo',
              onTap: () => setState(() => _direction = 'subindo'),
            ),
            const SizedBox(width: 10),
            _buildToggleBtn(
              label: l10n.goingDown,
              isActive: _direction == 'baixando',
              onTap: () => setState(() => _direction = 'baixando'),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 2 — TOTAL DEPTH (PROMINENT)
  // ===========================================================================

  Widget _buildSection2TotalDepth(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x1426A69A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x3326A69A)),
      ),
      child: Column(
        children: [
          Text(
            l10n.totalDepthLabel,
            style: const TextStyle(
              color: _teal,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x4D26A69A)),
                  ),
                  child: TextField(
                    controller: _depthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'm',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 3 — COMPLEMENTARY DATA
  // ===========================================================================

  Widget _buildSection3ComplementaryData(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.straighten,
      title: l10n.complementaryData,
      children: [
        _buildTextField(
          controller: _maxDraftController,
          label: l10n.maxDraftInput,
          icon: Icons.straighten,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _ukcController,
          label: l10n.ukcInput,
          icon: Icons.straighten,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _speedController,
          label: l10n.speedOptional,
          icon: Icons.speed,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: '(${l10n.optional})',
        ),
        const SizedBox(height: 14),
        _buildSquatToggle(l10n),
        const SizedBox(height: 14),
        _buildSonarToggle(l10n),
      ],
    );
  }

  Widget _buildSquatToggle(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.squatConsidered,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildToggleBtn(
              label: l10n.yes,
              isActive: _squatConsidered == 'sim',
              onTap: () => setState(() => _squatConsidered = 'sim'),
            ),
            const SizedBox(width: 10),
            _buildToggleBtn(
              label: l10n.no,
              isActive: _squatConsidered == 'nao',
              onTap: () => setState(() => _squatConsidered = 'nao'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSonarToggle(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sonarPosition,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildToggleBtn(
              label: l10n.bow,
              isActive: _sonarPosition == 'proa',
              onTap: () => setState(() => _sonarPosition = 'proa'),
            ),
            const SizedBox(width: 10),
            _buildToggleBtn(
              label: l10n.stern,
              isActive: _sonarPosition == 'popa',
              onTap: () => setState(() => _sonarPosition = 'popa'),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 4 — LAT/LONG (COLLAPSIBLE)
  // ===========================================================================

  Widget _buildSection4LatLong(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _latLongExpanded = !_latLongExpanded);
              if (_latLongExpanded) {
                _arrowAnimController.forward();
              } else {
                _arrowAnimController.reverse();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.explore, color: _teal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.positionLatLong,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          l10n.optional,
                          style: const TextStyle(
                              color: _textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _arrowAnim,
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: _textMuted, size: 24),
                  ),
                ],
              ),
            ),
          ),
          if (_latLongExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0x1AFFFFFF), height: 1),
                  const SizedBox(height: 14),
                  const Text('Latitude',
                      style: TextStyle(color: _textLabel, fontSize: 12)),
                  const SizedBox(height: 6),
                  _buildCoordRow(
                    degController: _latDegController,
                    minController: _latMinController,
                    secController: _latSecController,
                    degDigits: 2,
                    hemisphere: _latHemisphere,
                    hemisphereOptions: const ['N', 'S'],
                    onHemisphereChanged: (v) =>
                        setState(() => _latHemisphere = v),
                  ),
                  const SizedBox(height: 14),
                  const Text('Longitude',
                      style: TextStyle(color: _textLabel, fontSize: 12)),
                  const SizedBox(height: 6),
                  _buildCoordRow(
                    degController: _lonDegController,
                    minController: _lonMinController,
                    secController: _lonSecController,
                    degDigits: 3,
                    hemisphere: _lonHemisphere,
                    hemisphereOptions: const ['W', 'E'],
                    onHemisphereChanged: (v) =>
                        setState(() => _lonHemisphere = v),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoordRow({
    required TextEditingController degController,
    required TextEditingController minController,
    required TextEditingController secController,
    required int degDigits,
    required String hemisphere,
    required List<String> hemisphereOptions,
    required ValueChanged<String> onHemisphereChanged,
  }) {
    return Row(
      children: [
        _buildCoordField(degController, degDigits, 48),
        const Text(' \u00B0 ',
            style: TextStyle(color: _textSecondary, fontSize: 16)),
        _buildCoordField(minController, 2, 42),
        const Text(" \u2032 ",
            style: TextStyle(color: _textSecondary, fontSize: 16)),
        _buildCoordField(secController, 5, 64),
        const Text(' \u2033 ',
            style: TextStyle(color: _textSecondary, fontSize: 16)),
        const SizedBox(width: 4),
        ...hemisphereOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onHemisphereChanged(opt),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hemisphere == opt ? _teal : _inputBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hemisphere == opt ? _teal : _inputBorder,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: hemisphere == opt ? Colors.white : _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildCoordField(
      TextEditingController controller, int maxLength, double width) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: _inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _inputBorder),
        ),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          maxLength: maxLength,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 5 — OBSERVATIONS
  // ===========================================================================

  Widget _buildSection5Observations(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.notes,
      title: l10n.observations,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _inputBorder),
          ),
          constraints: const BoxConstraints(minHeight: 60),
          child: TextField(
            controller: _observationsController,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.additionalInfo,
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SAVE BUTTON
  // ===========================================================================

  Widget _buildSaveButton(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000D2137), _bgMid],
        ),
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _save,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00897B), Color(0xFF26A69A)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D26A69A),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    l10n.registerPassage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SHARED WIDGETS
  // ===========================================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _teal, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color iconColor = _teal,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: _textLabel, fontSize: 12)),
            if (suffixText != null) ...[
              const SizedBox(width: 6),
              Text(suffixText,
                  style: const TextStyle(color: _textMuted, fontSize: 10)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _inputBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: iconColor, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _inputBorder),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: _textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildToggleBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x2626A69A) : _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? _teal : _fieldBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? _teal : _textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
