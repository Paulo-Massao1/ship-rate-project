import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../controllers/crossing_controller.dart';
import '../../core/constants.dart';
import '../../data/services/url_launcher_service.dart';

class CrossingFormPage extends StatefulWidget {
  final Map<String, dynamic>? crossing;

  const CrossingFormPage({
    super.key,
    this.crossing,
  });

  @override
  State<CrossingFormPage> createState() => _CrossingFormPageState();
}

class _CrossingFormPageState extends State<CrossingFormPage> {
  static const _amber = Color(0xFFFFB74D);
  static const _amberLight = Color(0x1FFFB74D);
  static const _bgDark = Color(0xFF0A1628);
  static const _bgMid = Color(0xFF0D2137);
  static const _fieldBg = Color(0xFF1A2E45);
  static const _fieldBorder = Color(0x33FFB74D);
  static const _inputBorder = Color(0x33FFB74D);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xD9FFFFFF);
  static const _textMuted = Color(0x99FFFFFF);
  static const _otherLocationValue = '__other__';
  static const _presetLocations = [
    'Patacho Sul',
    'Boca do Trombetas',
    'Ponta do Jari',
    'Cajari',
    'Mocambo - Ponta de cima',
    'Furo do Santa Rita',
  ];

  final CrossingController _controller = CrossingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _shipNameController = TextEditingController();
  final TextEditingController _pilotsToContactController =
      TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  DateTime _selectedBrasiliaDateTime = _currentBrasiliaMinute();
  String? _selectedLocation;
  String? _selectedDraft;
  String? _direction;
  DateTime? _originalBrasiliaDateTime;
  bool _isSaving = false;
  bool get _isEditing => widget.crossing != null;
  String get _docId => (widget.crossing?['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadCrossingForEdit();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _shipNameController.dispose();
    _pilotsToContactController.dispose();
    _observationsController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Returns the current wall-clock minute in Brasilia time.
  static DateTime _currentBrasiliaMinute() {
    final brasiliaNow = DateTime.now().toUtc().subtract(
          const Duration(hours: 3),
        );
    return DateTime(
      brasiliaNow.year,
      brasiliaNow.month,
      brasiliaNow.day,
      brasiliaNow.hour,
      brasiliaNow.minute,
    );
  }

  /// Stores the user-selected Brasilia wall-clock time as an absolute UTC value.
  static DateTime _toStoredUtc(DateTime brasiliaDateTime) {
    return DateTime.utc(
      brasiliaDateTime.year,
      brasiliaDateTime.month,
      brasiliaDateTime.day,
      brasiliaDateTime.hour,
      brasiliaDateTime.minute,
    ).add(const Duration(hours: 3));
  }

  void _loadCrossingForEdit() {
    final crossing = widget.crossing;
    if (crossing == null) return;

    final location = (crossing['local'] ?? '').toString().trim();
    if (_presetLocations.contains(location)) {
      _selectedLocation = location;
    } else if (location.isNotEmpty) {
      _selectedLocation = _otherLocationValue;
      _locationController.text = location;
    }

    _shipNameController.text = (crossing['nomeNavio'] ?? '').toString().trim();
    _pilotsToContactController.text =
        (crossing['praticosContato'] ?? '').toString().trim();
    _observationsController.text =
        (crossing['observacoes'] ?? '').toString().trim();
    _direction = crossing['direcao']?.toString();
    _selectedDraft = crossing['calado']?.toString();

    final existingDateTime = _timestampToBrasilia(crossing['dataHora']);
    if (existingDateTime != null) {
      _selectedBrasiliaDateTime = existingDateTime;
      _originalBrasiliaDateTime = existingDateTime;
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBrasiliaDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _amber,
              surface: _bgMid,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedBrasiliaDateTime),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _amber,
              surface: _bgMid,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedBrasiliaDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final location = _selectedLocation == _otherLocationValue
        ? _locationController.text.trim()
        : (_selectedLocation ?? '').trim();
    final shipName = _shipNameController.text.trim();
    final pilotsToContact = _pilotsToContactController.text.trim();
    final observations = _observationsController.text.trim();

    if (location.isEmpty ||
        shipName.isEmpty ||
        _direction == null ||
        _selectedDraft == null) {
      _showSnackBar(l10n.fillRequiredFields, isError: true);
      return;
    }

    final timeWasChanged = !_isEditing ||
        _originalBrasiliaDateTime == null ||
        _selectedBrasiliaDateTime != _originalBrasiliaDateTime;
    if (timeWasChanged &&
        !_selectedBrasiliaDateTime.isAfter(_currentBrasiliaMinute())) {
      _showSnackBar(l10n.crossingTimeMustBeFuture, isError: true);
      return;
    }

    final crossingDateTimeUtc = _toStoredUtc(_selectedBrasiliaDateTime);

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'local': location,
        'dataHora': Timestamp.fromDate(crossingDateTimeUtc),
        'nomeNavio': shipName,
        'direcao': _direction,
        'calado': _selectedDraft,
      };

      if (pilotsToContact.isNotEmpty) {
        data['praticosContato'] = pilotsToContact;
      } else if (_isEditing) {
        data['praticosContato'] = FieldValue.delete();
      }

      if (observations.isNotEmpty) {
        data['observacoes'] = observations;
      } else if (_isEditing) {
        data['observacoes'] = FieldValue.delete();
      }

      if (_isEditing) {
        await _controller.updateCrossing(_docId, data);
        if (!mounted) return;

        Navigator.pop(context, true);
        return;
      }

      final savedCrossing = await _controller.addCrossing(data);
      if (!mounted) return;

      await _showShareDialog(savedCrossing, l10n);
      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(l10n.errorSaving(e.toString()), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showShareDialog(
    Map<String, dynamic> crossing,
    AppLocalizations l10n,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF132D4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: _amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.crossingSaved,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.shareCrossingPrompt,
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.noThanks,
              style: const TextStyle(color: _textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _shareCrossing(crossing, l10n);
            },
            child: Text(
              l10n.shareCrossing,
              style: const TextStyle(
                color: _amber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareCrossing(Map<String, dynamic> crossing, AppLocalizations l10n) {
    final location = (crossing['local'] ?? '').toString().trim();
    final shipName = (crossing['nomeNavio'] ?? '').toString().trim();
    final direction = _directionLabel(crossing['direcao']?.toString(), l10n);
    final draft = _draftLabel(crossing['calado']?.toString(), l10n);
    final pilotsToContact =
        (crossing['praticosContato'] ?? '').toString().trim();
    final formattedTime = _formatBrasiliaDateTime(
      _timestampToBrasilia(crossing['dataHora']),
    );
    final contactLine = pilotsToContact.isEmpty
        ? ''
        : '\n\u{1F4DE} ${l10n.pilotsToContact}: $pilotsToContact';

    final shareText =
        '\u2693 ${l10n.cruzamentoModule}\n'
        '\u{1F4CD} ${l10n.crossingLocation}: $location\n'
        '\u{1F550} ${l10n.crossingTime}: $formattedTime\n'
        '\u{1F6A2} ${l10n.crossingShipName}: $shipName\n'
        '\u2693 ${l10n.draftLabel}: $draft\n'
        '\u2195\uFE0F $direction'
        '$contactLine\n\n'
        '${l10n.shareMoreInfo} '
        '${AppConstants.appUrl}';

    UrlLauncherService.openWhatsAppShare(shareText);
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade800 : const Color(0xFF1B5E20),
      ),
    );
  }

  DateTime? _timestampToBrasilia(dynamic value) {
    DateTime? utcValue;
    if (value is Timestamp) {
      utcValue = value.toDate().toUtc();
    }

    if (value is DateTime) {
      utcValue = value.toUtc();
    }

    if (utcValue == null) return null;

    final brasilia = utcValue.subtract(const Duration(hours: 3));
    return DateTime(
      brasilia.year,
      brasilia.month,
      brasilia.day,
      brasilia.hour,
      brasilia.minute,
    );
  }

  String _formatBrasiliaDateTime(DateTime? value) {
    if (value == null) return '';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _directionLabel(String? value, AppLocalizations l10n) {
    switch (value?.toLowerCase()) {
      case 'subindo':
        return l10n.directionUp;
      case 'baixando':
        return l10n.directionDown;
      default:
        return l10n.notAvailable;
    }
  }

  String _draftLabel(String? value, AppLocalizations l10n) {
    switch (value) {
      case 'ate_6_5':
        return l10n.draftUpTo65;
      case '6_5_a_9_5':
        return l10n.draft65To95;
      case 'acima_9_5':
        return l10n.draftAbove95;
      default:
        return l10n.notAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.updateCrossing : l10n.newCrossing,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black54,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
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
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      icon: Icons.compare_arrows,
                      title: _isEditing ? l10n.updateCrossing : l10n.newCrossing,
                      children: [
                        _buildLocationSelector(l10n),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _shipNameController,
                          label: l10n.crossingShipName,
                          icon: Icons.directions_boat_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildDraftSelector(l10n),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      icon: Icons.schedule,
                      title: l10n.crossingTime,
                      children: [
                        GestureDetector(
                          onTap: _pickDateTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _fieldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _inputBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit_calendar_outlined,
                                  color: _amber,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _formatBrasiliaDateTime(
                                      _selectedBrasiliaDateTime,
                                    ),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: _textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.direction,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildToggleButton(
                              label: l10n.directionUp,
                              isActive: _direction == 'subindo',
                              onTap: () => setState(() => _direction = 'subindo'),
                            ),
                            const SizedBox(width: 10),
                            _buildToggleButton(
                              label: l10n.directionDown,
                              isActive: _direction == 'baixando',
                              onTap: () =>
                                  setState(() => _direction = 'baixando'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      icon: Icons.notes_outlined,
                      title: l10n.observations,
                      children: [
                        _buildTextField(
                          controller: _pilotsToContactController,
                          label: '${l10n.pilotsToContact} (${l10n.optional})',
                          icon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _observationsController,
                          label:
                              '${l10n.crossingObservations} (${l10n.optional})',
                          icon: Icons.sticky_note_2_outlined,
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isSaving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFC978), _amber],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4DFFB74D),
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
                                  _isEditing
                                      ? l10n.updateCrossing
                                      : l10n.registerCrossing,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                  color: _amberLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _amber, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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

  Widget _buildLocationSelector(AppLocalizations l10n) {
    final options = [..._presetLocations, _otherLocationValue];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.crossingLocation,
          style: const TextStyle(color: _textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final label = option == _otherLocationValue
                ? l10n.otherLocation
                : option;
            return _buildChoiceChip(
              label: label,
              isActive: _selectedLocation == option,
              onTap: () => setState(() => _selectedLocation = option),
            );
          }).toList(),
        ),
        if (_selectedLocation == _otherLocationValue) ...[
          const SizedBox(height: 14),
          _buildTextField(
            controller: _locationController,
            label: l10n.crossingLocation,
            icon: Icons.place_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildDraftSelector(AppLocalizations l10n) {
    final options = [
      ('ate_6_5', l10n.draftUpTo65),
      ('6_5_a_9_5', l10n.draft65To95),
      ('acima_9_5', l10n.draftAbove95),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.draftLabel,
          style: const TextStyle(color: _textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return _buildChoiceChip(
              label: option.$2,
              isActive: _selectedDraft == option.$1,
              onTap: () => setState(() => _selectedDraft = option.$1),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _amberLight : _fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _amber : _fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _amber : _textMuted,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _inputBorder),
          ),
          child: TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            cursorColor: _amber,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldBg,
              prefixIcon: Icon(icon, color: _amber, size: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
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
            color: isActive ? _amberLight : _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? _amber : _fieldBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? _amber : _textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
