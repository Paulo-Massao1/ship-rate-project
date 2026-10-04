import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../data/models/maneuver_report.dart';
import '../../data/models/maneuver_tug.dart';
import '../../data/services/maneuver_report_service.dart';
import '../../data/services/maneuver_tug_service.dart';

class ManeuverReportPage extends StatefulWidget {
  const ManeuverReportPage({
    super.key,
    required this.portName,
    required this.portCode,
    required this.terminalId,
    required this.terminalName,
  });

  final String portName;
  final String portCode;
  final String terminalId;
  final String terminalName;

  @override
  State<ManeuverReportPage> createState() => _ManeuverReportPageState();
}

class _ManeuverReportPageState extends State<ManeuverReportPage> {
  static const _amber = Color(0xFFFFB74D);
  static const _blue = Color(0xFF64B5F6);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _card = Color(0x0DFFFFFF);
  static const _muted = Color(0x99FFFFFF);
  static final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9,.]'),
  );
  static final _integerFormatter = FilteringTextInputFormatter.digitsOnly;

  final _shipNameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _beamController = TextEditingController();
  final _maximumDraftController = TextEditingController();
  final _officerNationalityController = TextEditingController();
  final _crewNationalityController = TextEditingController();
  final _currentDirectionController = TextEditingController();
  final _currentIntensityController = TextEditingController();
  final _windDirectionController = TextEditingController();
  final _windIntensityController = TextEditingController();
  final _approachCommentsController = TextEditingController();
  final _mooringCommentsController = TextEditingController();
  final _shipNameFocusNode = FocusNode();

  late final ManeuverTugService _tugService;
  late final ManeuverReportService _reportService;
  late final Stream<List<ManeuverTug>> _tugsStream;
  List<ManeuverShipOption> _ships = const [];
  String? _selectedShipId;
  ManeuverTug? _forwardTug;
  ManeuverTug? _aftTug;
  ManeuverPropellerDirection? _propellerDirection;
  ManeuverPropellerPitch? _propellerPitch;
  ManeuverFirstLine? _forwardFirstLine;
  ManeuverFirstLine? _aftFirstLine;
  bool _loadingShips = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tugService = ManeuverTugService();
    _reportService = ManeuverReportService();
    _tugsStream = _tugService.watchTugsForPort(widget.portCode);
    _loadShips();
  }

  @override
  void dispose() {
    _shipNameController.dispose();
    _lengthController.dispose();
    _beamController.dispose();
    _maximumDraftController.dispose();
    _officerNationalityController.dispose();
    _crewNationalityController.dispose();
    _currentDirectionController.dispose();
    _currentIntensityController.dispose();
    _windDirectionController.dispose();
    _windIntensityController.dispose();
    _approachCommentsController.dispose();
    _mooringCommentsController.dispose();
    _shipNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadShips() async {
    try {
      final ships = await _reportService.loadShips();
      if (!mounted) return;
      setState(() {
        _ships = ships;
        _loadingShips = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingShips = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reportManeuver,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: _bgDark,
      ),
      bottomNavigationBar: _buildSaveBar(l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgDark, _bgMid],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildHeader(l10n),
                const SizedBox(height: 18),
                _buildShipSection(l10n),
                const SizedBox(height: 14),
                _buildTugSection(l10n),
                const SizedBox(height: 14),
                _buildMooringSection(l10n),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.terminalName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.portName} (${widget.portCode})',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.info_outline, color: _amber, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.maneuverReportOptionalFields,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipSection(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.directions_boat_outlined,
      title: l10n.shipData,
      child: Column(
        children: [
          _buildShipAutocomplete(l10n),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lengthController,
                  label: l10n.maneuverShipLength,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalFormatter],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _beamController,
                  label: l10n.maneuverShipBeam,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalFormatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _maximumDraftController,
            label: l10n.maneuverMaximumDraft,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildChoiceGroup<ManeuverPropellerDirection>(
                  label: l10n.maneuverPropellerDirection,
                  value: _propellerDirection,
                  options: {
                    ManeuverPropellerDirection.rightHanded:
                        l10n.maneuverRightHanded,
                    ManeuverPropellerDirection.leftHanded:
                        l10n.maneuverLeftHanded,
                  },
                  onChanged: (value) {
                    setState(() => _propellerDirection = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceGroup<ManeuverPropellerPitch>(
                  label: l10n.maneuverPropellerPitch,
                  value: _propellerPitch,
                  options: {
                    ManeuverPropellerPitch.fixed: l10n.maneuverPitchFixed,
                    ManeuverPropellerPitch.controllable:
                        l10n.maneuverPitchControllable,
                  },
                  onChanged: (value) {
                    setState(() => _propellerPitch = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _officerNationalityController,
                  label: l10n.maneuverOfficerNationality,
                  maxLength: 80,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _crewNationalityController,
                  label: l10n.crewNationality,
                  maxLength: 80,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipAutocomplete(AppLocalizations l10n) {
    return RawAutocomplete<ManeuverShipOption>(
      textEditingController: _shipNameController,
      focusNode: _shipNameFocusNode,
      displayStringForOption: (ship) => ship.name.toUpperCase(),
      optionsBuilder: (value) {
        final query = value.text.trim().toUpperCase();
        if (query.isEmpty) return const Iterable<ManeuverShipOption>.empty();
        return _ships
            .where((ship) => ship.name.toUpperCase().contains(query))
            .take(20);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: !_saving,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(120),
            _UpperCaseTextFormatter(),
          ],
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            label: l10n.shipName,
            hint: _loadingShips
                ? l10n.maneuverLoadingShips
                : l10n.maneuverSearchShip,
            prefixIcon: Icons.search,
          ),
          onChanged: (_) => _selectedShipId = null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (options.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: _bgMid,
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 568, maxHeight: 260),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, index) {
                  final ship = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.directions_boat_outlined,
                      color: _blue,
                      size: 20,
                    ),
                    title: Text(
                      ship.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    onTap: () {
                      onSelected(ship);
                      setState(() {
                        _selectedShipId = ship.id;
                        _shipNameController.text = ship.name.toUpperCase();
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMooringSection(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.anchor,
      title: l10n.maneuverMooring,
      child: Column(
        children: [
          _buildChoiceGroup<ManeuverFirstLine>(
            label: l10n.maneuverForwardFirstLines,
            value: _forwardFirstLine,
            options: {
              ManeuverFirstLine.headLine: l10n.maneuverHeadLine,
              ManeuverFirstLine.breastLine: l10n.maneuverBreastLine,
              ManeuverFirstLine.spring: l10n.maneuverSpring,
            },
            onChanged: (value) => setState(() => _forwardFirstLine = value),
          ),
          const SizedBox(height: 14),
          _buildChoiceGroup<ManeuverFirstLine>(
            label: l10n.maneuverAftFirstLines,
            value: _aftFirstLine,
            options: {
              ManeuverFirstLine.headLine: l10n.maneuverHeadLine,
              ManeuverFirstLine.breastLine: l10n.maneuverBreastLine,
              ManeuverFirstLine.spring: l10n.maneuverSpring,
            },
            onChanged: (value) => setState(() => _aftFirstLine = value),
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _mooringCommentsController,
            label: l10n.maneuverComments,
            maxLength: 2000,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _amber, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: keyboardType,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _inputDecoration(label: label, hint: hint),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _muted, fontSize: 12),
      hintStyle: const TextStyle(color: Color(0x55FFFFFF), fontSize: 12),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: _blue, size: 19),
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _amber),
      ),
    );
  }

  Widget _buildChoiceGroup<T>({
    required String label,
    required T? value,
    required Map<T, String> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.entries.map((entry) {
            final selected = value == entry.key;
            return Semantics(
              button: true,
              selected: selected,
              child: Material(
                color: selected
                    ? _amber.withValues(alpha: 0.13)
                    : const Color(0x08FFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: selected
                        ? _amber.withValues(alpha: 0.55)
                        : const Color(0x33FFFFFF),
                  ),
                ),
                child: InkWell(
                  onTap: _saving
                      ? null
                      : () => onChanged(selected ? null : entry.key),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: selected
                            ? _amber
                            : const Color(0xD9FFFFFF),
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildTugSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assistant_direction, color: _amber, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.maneuverApproach,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.maneuverTugboats,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.maneuverTugSharedNotice,
            style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 11),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ManeuverTug>>(
            stream: _tugsStream,
            builder: (context, snapshot) {
              final official = _tugService.officialTugsForPort(widget.portCode);
              final tugs = snapshot.data ?? official;

              return Column(
                children: [
                  _buildTugDropdown(
                    l10n: l10n,
                    label: l10n.maneuverTugForward,
                    value: _forwardTug?.id,
                    tugs: tugs,
                    onChanged: (value) {
                      setState(() {
                        _forwardTug = _findTug(tugs, value);
                        if (_aftTug?.id == value) _aftTug = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTugDropdown(
                    l10n: l10n,
                    label: l10n.maneuverTugAft,
                    value: _aftTug?.id,
                    tugs: tugs,
                    onChanged: (value) {
                      setState(() {
                        _aftTug = _findTug(tugs, value);
                        if (_forwardTug?.id == value) _forwardTug = null;
                      });
                    },
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          color: _amber,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            l10n.maneuverCommunityTugsLoadError,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _saving ? null : () => _showAddTugSheet(l10n),
              icon: const Icon(Icons.add, size: 17),
              label: Text(l10n.maneuverAddTug),
              style: TextButton.styleFrom(foregroundColor: _blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.maneuverCurrent,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _currentDirectionController,
                  label: l10n.maneuverDirectionDegrees,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_integerFormatter],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _currentIntensityController,
                  label: l10n.maneuverIntensityKnots,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalFormatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.maneuverWind,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _windDirectionController,
                  label: l10n.maneuverDirectionDegrees,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_integerFormatter],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  controller: _windIntensityController,
                  label: l10n.maneuverIntensityKnots,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [_decimalFormatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _approachCommentsController,
            label: l10n.maneuverComments,
            maxLength: 2000,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  ManeuverTug? _findTug(List<ManeuverTug> tugs, String? id) {
    if (id == null) return null;
    for (final tug in tugs) {
      if (tug.id == id) return tug;
    }
    return null;
  }

  Widget _buildTugDropdown({
    required AppLocalizations l10n,
    required String label,
    required String? value,
    required List<ManeuverTug> tugs,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = tugs.any((tug) => tug.id == value) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      dropdownColor: _bgMid,
      iconEnabledColor: const Color(0x99FFFFFF),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 12),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _amber),
        ),
      ),
      hint: Text(
        tugs.isEmpty ? l10n.maneuverNoTugs : l10n.maneuverSelectTug,
        style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13),
      ),
      items: [
        DropdownMenuItem<String>(
          value: '',
          child: Text(l10n.maneuverNoTugSelected),
        ),
        ...tugs.map(
          (tug) => DropdownMenuItem<String>(
            value: tug.id,
            child: Text(
              _tugOptionLabel(tug, l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: tugs.isEmpty
          ? null
          : (selected) => onChanged(selected == '' ? null : selected),
    );
  }

  String _tugOptionLabel(ManeuverTug tug, AppLocalizations l10n) {
    final metadata = <String>[
      if (tug.bollardPull != null)
        'BP ${tug.bollardPull!.toStringAsFixed(2).replaceAll('.', ',')}',
      switch (tug.type) {
        ManeuverTugType.azimuthal => l10n.maneuverTugTypeAzimuthal,
        ManeuverTugType.conventional => l10n.maneuverTugTypeConventional,
        ManeuverTugType.unspecified => l10n.maneuverTugTypeUnspecified,
      },
      tug.isOfficial
          ? l10n.maneuverTugOfficialSource
          : l10n.maneuverTugCommunitySource,
    ];
    return '${tug.name} · ${metadata.join(' · ')}';
  }

  Future<void> _showAddTugSheet(AppLocalizations l10n) async {
    final created = await showModalBottomSheet<ManeuverTug>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddManeuverTugSheet(
        portCode: widget.portCode,
        service: _tugService,
      ),
    );
    if (!mounted || created == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.maneuverTugSaved(created.name)),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }

  Widget _buildSaveBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: _bgDark,
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.maybePop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _muted,
                  side: const BorderSide(color: Color(0x33FFFFFF)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveReport,
                style: FilledButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: _bgDark,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _bgDark,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 19),
                label: Text(l10n.maneuverSaveReport),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReport() async {
    final l10n = AppLocalizations.of(context)!;
    final length = _parseDecimal(_lengthController.text);
    final beam = _parseDecimal(_beamController.text);
    final maximumDraft = _parseDecimal(_maximumDraftController.text);
    final currentDirection = _parseInteger(_currentDirectionController.text);
    final currentIntensity = _parseDecimal(_currentIntensityController.text);
    final windDirection = _parseInteger(_windDirectionController.text);
    final windIntensity = _parseDecimal(_windIntensityController.text);

    final invalid =
        !_validOptionalDecimal(_lengthController.text, length, 500) ||
        !_validOptionalDecimal(_beamController.text, beam, 100) ||
        !_validOptionalDecimal(
          _maximumDraftController.text,
          maximumDraft,
          100,
        ) ||
        !_validOptionalDirection(_currentDirectionController.text, currentDirection) ||
        !_validOptionalNumber(
          _currentIntensityController.text,
          currentIntensity,
          100,
        ) ||
        !_validOptionalDirection(_windDirectionController.text, windDirection) ||
        !_validOptionalNumber(_windIntensityController.text, windIntensity, 200);
    if (invalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maneuverInvalidNumericValue),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final draft = ManeuverReportDraft(
      portName: widget.portName,
      portCode: widget.portCode,
      terminalId: widget.terminalId,
      terminalName: widget.terminalName,
      shipId: _selectedShipId,
      shipName: _trimmedOrNull(_shipNameController.text)?.toUpperCase(),
      lengthMeters: length,
      beamMeters: beam,
      maximumDraftMeters: maximumDraft,
      propellerDirection: _propellerDirection,
      propellerPitch: _propellerPitch,
      officerNationality: _trimmedOrNull(_officerNationalityController.text),
      crewNationality: _trimmedOrNull(_crewNationalityController.text),
      forwardTug: _forwardTug,
      aftTug: _aftTug,
      currentDirectionDegrees: currentDirection,
      currentIntensityKnots: currentIntensity,
      windDirectionDegrees: windDirection,
      windIntensityKnots: windIntensity,
      approachComments: _trimmedOrNull(_approachCommentsController.text),
      forwardFirstLine: _forwardFirstLine,
      aftFirstLine: _aftFirstLine,
      mooringComments: _trimmedOrNull(_mooringCommentsController.text),
    );

    setState(() => _saving = true);
    try {
      await _reportService.saveReport(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maneuverReportSaved),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
      Navigator.pop(context, true);
    } on ManeuverReportException catch (error) {
      if (!mounted) return;
      final message = error.code == ManeuverReportError.signedOut
          ? l10n.maneuverReportSignedOut
          : l10n.maneuverReportSaveError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  int? _parseInteger(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : int.tryParse(normalized);
  }

  bool _validOptionalDecimal(String raw, double? value, double maximum) {
    return raw.trim().isEmpty ||
        (value != null && value.isFinite && value > 0 && value <= maximum);
  }

  bool _validOptionalNumber(String raw, double? value, double maximum) {
    return raw.trim().isEmpty ||
        (value != null && value.isFinite && value >= 0 && value <= maximum);
  }

  bool _validOptionalDirection(String raw, int? value) {
    return raw.trim().isEmpty || (value != null && value >= 0 && value <= 359);
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _AddManeuverTugSheet extends StatefulWidget {
  const _AddManeuverTugSheet({
    required this.portCode,
    required this.service,
  });

  final String portCode;
  final ManeuverTugService service;

  @override
  State<_AddManeuverTugSheet> createState() => _AddManeuverTugSheetState();
}

class _AddManeuverTugSheetState extends State<_AddManeuverTugSheet> {
  static const _blue = Color(0xFF64B5F6);
  static const _muted = Color(0x99FFFFFF);

  final _nameController = TextEditingController();
  final _bollardPullController = TextEditingController();
  ManeuverTugType _type = ManeuverTugType.unspecified;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _bollardPullController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.maneuverAddTugTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.maneuverTugRegistrationNotice,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                maxLength: 60,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: l10n.maneuverTugName,
                  hint: l10n.maneuverTugNameHint,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bollardPullController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  label: l10n.maneuverTugBollardPull,
                  hint: '50,00',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ManeuverTugType>(
                value: _type,
                dropdownColor: const Color(0xFF0D2137),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(label: l10n.maneuverTugType),
                items: [
                  DropdownMenuItem(
                    value: ManeuverTugType.unspecified,
                    child: Text(l10n.maneuverTugTypeUnspecified),
                  ),
                  DropdownMenuItem(
                    value: ManeuverTugType.azimuthal,
                    child: Text(l10n.maneuverTugTypeAzimuthal),
                  ),
                  DropdownMenuItem(
                    value: ManeuverTugType.conventional,
                    child: Text(l10n.maneuverTugTypeConventional),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _type = value);
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _muted,
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: const Color(0xFF0A1628),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A1628),
                              ),
                            )
                          : Text(l10n.maneuverSaveTug),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
      counterStyle: const TextStyle(color: Color(0x55FFFFFF)),
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _blue),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final rawBollardPull = _bollardPullController.text.trim();
    final bollardPull = rawBollardPull.isEmpty
        ? null
        : double.tryParse(rawBollardPull.replaceAll(',', '.'));

    if (rawBollardPull.isNotEmpty && bollardPull == null) {
      setState(() => _error = l10n.maneuverTugInvalidBollardPull);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final tug = await widget.service.createCommunityTug(
        portCode: widget.portCode,
        name: _nameController.text,
        type: _type,
        bollardPull: bollardPull,
      );
      if (mounted) Navigator.pop(context, tug);
    } on ManeuverTugException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (error.code) {
          ManeuverTugError.invalidName => l10n.maneuverTugInvalidName,
          ManeuverTugError.invalidBollardPull =>
            l10n.maneuverTugInvalidBollardPull,
          ManeuverTugError.duplicate => l10n.maneuverTugDuplicate,
          ManeuverTugError.signedOut => l10n.maneuverTugSignedOut,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.maneuverTugSaveError;
      });
    }
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
