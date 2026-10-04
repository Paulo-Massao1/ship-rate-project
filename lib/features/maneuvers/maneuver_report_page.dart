import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../data/models/maneuver_report.dart';
import '../../data/models/maneuver_tug.dart';
import '../../data/services/image_upload_service.dart';
import '../../data/services/maneuver_report_service.dart';
import '../../data/services/maneuver_media_service.dart';
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
  late final ManeuverMediaService _mediaService;
  late final Stream<List<ManeuverTug>> _tugsStream;
  List<ManeuverShipOption> _ships = const [];
  String? _selectedShipId;
  ManeuverTug? _forwardTug;
  ManeuverTug? _aftTug;
  ManeuverPropellerDirection? _propellerDirection;
  ManeuverPropellerPitch? _propellerPitch;
  ManeuverFirstLine? _forwardFirstLine;
  ManeuverFirstLine? _aftFirstLine;
  final List<PendingManeuverMedia> _approachMedia = [];
  final List<PendingManeuverMedia> _mooringMedia = [];
  bool _loadingShips = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tugService = ManeuverTugService();
    _reportService = ManeuverReportService();
    _mediaService = const ManeuverMediaService();
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
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.maneuverNewReportTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.maneuverReportPort(
                widget.terminalName,
                widget.portName,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _amber,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: _bgDark,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0x1FFFFFFF)),
        ),
      ),
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
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xCCFFFFFF),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: Text(l10n.back),
                  ),
                ),
                const SizedBox(height: 12),
                _buildShipSection(l10n),
                const SizedBox(height: 28),
                _buildTugSection(l10n),
                const SizedBox(height: 28),
                _buildMooringSection(l10n),
                const SizedBox(height: 28),
                _buildFormActions(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShipSection(AppLocalizations l10n) {
    return _buildFormSection(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(l10n.shipName),
        const SizedBox(height: 6),
        RawAutocomplete<ManeuverShipOption>(
          textEditingController: _shipNameController,
          focusNode: _shipNameFocusNode,
          displayStringForOption: (ship) => ship.name.toUpperCase(),
          optionsBuilder: (value) {
            final query = value.text.trim().toUpperCase();
            if (query.isEmpty) {
              return const Iterable<ManeuverShipOption>.empty();
            }
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
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: _inputDecoration(
                hint: _loadingShips
                    ? l10n.maneuverLoadingShips
                    : l10n.maneuverSearchShip,
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
                  constraints: const BoxConstraints(
                    maxWidth: 564,
                    maxHeight: 260,
                  ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
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
        ),
      ],
    );
  }

  Widget _buildMooringSection(AppLocalizations l10n) {
    return _buildFormSection(
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
          const SizedBox(height: 10),
          _buildMediaControls(l10n, ManeuverMediaSection.mooring),
        ],
      ),
    );
  }

  Widget _buildFormSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _amber, size: 18),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: _amber,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0x33FFB74D)),
        const SizedBox(height: 13),
        child,
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: keyboardType,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _inputDecoration(hint: hint),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xB3FFFFFF),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x2EFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x99FFB74D)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
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
        _buildFieldLabel(label),
        const SizedBox(height: 7),
        Row(
          children: [
            for (final (index, entry) in options.entries.indexed) ...[
              if (index > 0) const SizedBox(width: 6),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final selected = value == entry.key;
                    return Semantics(
                      button: true,
                      selected: selected,
                      child: Material(
                        color: selected
                            ? _amber.withValues(alpha: 0.13)
                            : const Color(0x08FFFFFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: BorderSide(
                            color: selected
                                ? _amber.withValues(alpha: 0.55)
                                : const Color(0x2EFFFFFF),
                          ),
                        ),
                        child: InkWell(
                          onTap: _saving
                              ? null
                              : () => onChanged(selected ? null : entry.key),
                          borderRadius: BorderRadius.circular(7),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              entry.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected
                                    ? _amber
                                    : const Color(0xE6FFFFFF),
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
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTugSection(AppLocalizations l10n) {
    return _buildFormSection(
      icon: Icons.assistant_direction,
      title: l10n.maneuverApproach,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 10),
          _buildMediaControls(l10n, ManeuverMediaSection.approach),
        ],
      ),
    );
  }

  Widget _buildMediaControls(
    AppLocalizations l10n,
    ManeuverMediaSection section,
  ) {
    final media = section == ManeuverMediaSection.approach
        ? _approachMedia
        : _mooringMedia;
    final atLimit = media.length >= ManeuverMediaService.maxMediaPerSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (media.isNotEmpty) ...[
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: media.indexed.map((entry) {
              final index = entry.$1;
              final item = entry.$2;
              return InputChip(
                avatar: Icon(
                  item.type == ManeuverMediaType.photo
                      ? Icons.photo_outlined
                      : Icons.videocam_outlined,
                  color: _amber,
                  size: 15,
                ),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    item.file.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                backgroundColor: const Color(0x0DFFFFFF),
                side: const BorderSide(color: Color(0x2EFFFFFF)),
                deleteIconColor: const Color(0xB3FFFFFF),
                onDeleted: _saving
                    ? null
                    : () => setState(() => media.removeAt(index)),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            _buildMediaButton(
              icon: Icons.photo_camera_outlined,
              label: l10n.photo,
              onPressed: atLimit ? null : () => _pickPhoto(section),
            ),
            const SizedBox(width: 8),
            _buildMediaButton(
              icon: Icons.videocam_outlined,
              label: l10n.video,
              onPressed: atLimit ? null : () => _pickVideo(section),
            ),
          ],
        ),
        if (atLimit) ...[
          const SizedBox(height: 5),
          Text(
            l10n.maneuverMediaLimit,
            style: const TextStyle(color: _muted, fontSize: 9),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _saving ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x2EFFFFFF)),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, color: _amber, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Future<void> _pickPhoto(ManeuverMediaSection section) async {
    final source = kIsWeb ? ImagePickSource.gallery : await _choosePhotoSource();
    if (source == null) return;
    try {
      final media = await _mediaService.pickPhoto(source);
      if (media != null) _addMedia(section, media);
    } catch (_) {
      _showMediaError(AppLocalizations.of(context)!.maneuverMediaInvalid);
    }
  }

  Future<void> _pickVideo(ManeuverMediaSection section) async {
    try {
      final media = await _mediaService.pickVideo();
      if (media != null) _addMedia(section, media);
    } catch (_) {
      _showMediaError(AppLocalizations.of(context)!.maneuverMediaInvalid);
    }
  }

  void _addMedia(
    ManeuverMediaSection section,
    PendingManeuverMedia item,
  ) {
    if (!mounted) return;
    final media = section == ManeuverMediaSection.approach
        ? _approachMedia
        : _mooringMedia;
    final l10n = AppLocalizations.of(context)!;
    if (media.length >= ManeuverMediaService.maxMediaPerSection) {
      _showMediaError(l10n.maneuverMediaLimit);
      return;
    }
    setState(() => media.add(item));
  }

  Future<ImagePickSource?> _choosePhotoSource() {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<ImagePickSource>(
      context: context,
      backgroundColor: _bgMid,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _amber),
              title: Text(
                l10n.camera,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _amber),
              title: Text(
                l10n.gallery,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, ImagePickSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          dropdownColor: _bgMid,
          iconEnabledColor: const Color(0x99FFFFFF),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: _inputDecoration(),
          hint: Text(
            tugs.isEmpty ? l10n.maneuverNoTugs : l10n.maneuverSelectTug,
            style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
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
        ),
      ],
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

  Widget _buildFormActions(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _saveReport,
            style: FilledButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: _bgDark,
              disabledBackgroundColor: _amber.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _bgDark,
                    ),
                  )
                : Text(
                    l10n.maneuverSaveReport,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xCCFFFFFF),
              side: const BorderSide(color: Color(0x40FFFFFF)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.cancel),
          ),
        ),
      ],
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

    final userId = _reportService.currentUserId;
    if (userId == null) {
      _showMediaError(l10n.maneuverReportSignedOut);
      return;
    }

    setState(() => _saving = true);
    final reportId = _reportService.createReportId();
    final uploadedPaths = <String>[];
    var reportSaved = false;
    try {
      final approachMedia = await _mediaService.uploadSection(
        media: _approachMedia,
        userId: userId,
        reportId: reportId,
        section: ManeuverMediaSection.approach,
      );
      uploadedPaths.addAll(approachMedia.map((item) => item.path));
      final mooringMedia = await _mediaService.uploadSection(
        media: _mooringMedia,
        userId: userId,
        reportId: reportId,
        section: ManeuverMediaSection.mooring,
      );
      uploadedPaths.addAll(mooringMedia.map((item) => item.path));

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
        approachMedia: approachMedia,
        mooringMedia: mooringMedia,
      );
      await _reportService.saveReport(draft, reportId: reportId);
      reportSaved = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maneuverReportSaved),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
      Navigator.pop(context, true);
    } on ManeuverMediaException {
      if (!mounted) return;
      _showMediaError(l10n.maneuverMediaUploadError);
    } on ManeuverReportException catch (error) {
      if (!mounted) return;
      final message = error.code == ManeuverReportError.signedOut
          ? l10n.maneuverReportSignedOut
          : l10n.maneuverReportSaveError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
      );
    } catch (_) {
      if (!mounted) return;
      _showMediaError(l10n.maneuverReportSaveError);
    } finally {
      if (!reportSaved && uploadedPaths.isNotEmpty) {
        await _mediaService.deleteMedia(uploadedPaths);
      }
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
  static const _amber = Color(0xFFFFB74D);
  static const _muted = Color(0x99FFFFFF);

  final _nameController = TextEditingController();
  final _bollardPullController = TextEditingController();
  ManeuverTugType _type = ManeuverTugType.azimuthal;
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
          12,
          12,
          12,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF13263A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x2EFFFFFF)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    l10n.maneuverAddTugTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildLabel(l10n.maneuverTugName),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    _UpperCaseTextFormatter(),
                  ],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration(
                    hint: l10n.maneuverTugNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.maneuverTugBollardPull),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _bollardPullController,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]'),
                              ),
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: _inputDecoration(
                              hint: l10n.maneuverTugBollardPullHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.maneuverTugType),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton(
                                  label: l10n.maneuverTugTypeAzimuthal,
                                  value: ManeuverTugType.azimuthal,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildTypeButton(
                                  label: l10n.maneuverTugTypeConventional,
                                  value: ManeuverTugType.conventional,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFEF9A9A),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: const Color(0xFF0A1628),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _muted,
                          side: const BorderSide(color: Color(0x40FFFFFF)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xB3FFFFFF),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required ManeuverTugType value,
  }) {
    final selected = _type == value;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? _amber.withValues(alpha: 0.13)
            : const Color(0x08FFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(
            color: selected
                ? _amber.withValues(alpha: 0.55)
                : const Color(0x2EFFFFFF),
          ),
        ),
        child: InkWell(
          onTap: _saving ? null : () => setState(() => _type = value),
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _amber : const Color(0xE6FFFFFF),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
      counterText: '',
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x2EFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x99FFB74D)),
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
