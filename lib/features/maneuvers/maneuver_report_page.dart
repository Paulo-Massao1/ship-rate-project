import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../data/models/maneuver_tug.dart';
import '../../data/services/maneuver_tug_service.dart';

class ManeuverReportPage extends StatefulWidget {
  const ManeuverReportPage({
    super.key,
    required this.portName,
    required this.portCode,
    required this.terminalName,
  });

  final String portName;
  final String portCode;
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

  late final ManeuverTugService _tugService;
  late final Stream<List<ManeuverTug>> _tugsStream;
  String? _forwardTugId;
  String? _aftTugId;

  @override
  void initState() {
    super.initState();
    _tugService = ManeuverTugService();
    _tugsStream = _tugService.watchTugsForPort(
      widget.portCode,
      terminalName: widget.terminalName,
    );
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
                _buildTugSection(l10n),
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
              final official = _tugService.officialTugsForPort(
                widget.portCode,
                terminalName: widget.terminalName,
              );
              final tugs = snapshot.data ?? official;

              return Column(
                children: [
                  _buildTugDropdown(
                    l10n: l10n,
                    label: l10n.maneuverTugForward,
                    value: _forwardTugId,
                    tugs: tugs,
                    onChanged: (value) {
                      setState(() {
                        _forwardTugId = value;
                        if (_aftTugId == value) _aftTugId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTugDropdown(
                    l10n: l10n,
                    label: l10n.maneuverTugAft,
                    value: _aftTugId,
                    tugs: tugs,
                    onChanged: (value) {
                      setState(() {
                        _aftTugId = value;
                        if (_forwardTugId == value) _forwardTugId = null;
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
              onPressed: () => _showAddTugSheet(l10n),
              icon: const Icon(Icons.add, size: 17),
              label: Text(l10n.maneuverAddTug),
              style: TextButton.styleFrom(foregroundColor: _blue),
            ),
          ),
        ],
      ),
    );
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
