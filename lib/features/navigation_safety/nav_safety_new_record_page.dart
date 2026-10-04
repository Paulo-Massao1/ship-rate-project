import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../controllers/nav_safety_controller.dart';
import '../../data/services/depth_reference_service.dart';
import '../../data/services/image_upload_service.dart';
import '../../data/services/url_launcher_service.dart';

/// Form screen for registering a new depth/passage record,
/// or editing an existing one when [editLocationId] and [editRecordId] are provided.
class NavSafetyNewRecordPage extends StatefulWidget {
  final String? editLocationId;
  final String? editRecordId;
  final Map<String, dynamic>? editData;

  const NavSafetyNewRecordPage({
    super.key,
    this.editLocationId,
    this.editRecordId,
    this.editData,
  });

  bool get isEditing => editRecordId != null && editLocationId != null;

  @override
  State<NavSafetyNewRecordPage> createState() =>
      _NavSafetyNewRecordPageState();
}

enum _AttachmentType { photo, file }

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
  static const _fieldBg = Color(0xFF1A2E45);
  static const _fieldBorder = Color(0x1F64B5F6);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xD9FFFFFF);
  static const _textMuted = Color(0x66FFFFFF);
  static const _textLabel = Color(0x99FFFFFF);
  static const _inputBg = Color(0xFF1A2E45);
  static const _inputBorder = Color(0x3326A69A);
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
  final _squatController = TextEditingController();
  final _speedController = TextEditingController();
  String? _sonarPosition; // 'proa' or 'popa'

  // Location reference
  DepthReference? _depthReference;
  SantanaTideWindow? _santanaTideWindow;
  bool _isLoadingTide = false;
  bool _suspendDepthCalculation = false;
  int _tideRequestId = 0;

  // LAT/LONG
  bool _latLongExpanded = false;
  late AnimationController _arrowAnimController;
  late Animation<double> _arrowAnim;
  final _latDegController = TextEditingController();
  final _latMinController = TextEditingController();
  String _latHemisphere = 'S';
  final _lonDegController = TextEditingController();
  final _lonMinController = TextEditingController();
  String _lonHemisphere = 'W';

  // Observations
  final _observationsController = TextEditingController();

  // Images
  final List<PendingImageUpload> _selectedImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToDelete = [];

  // Generic file attachments (any type besides photos)
  final List<PendingImageUpload> _selectedFiles = [];
  List<Map<String, dynamic>> _existingFileAttachments = [];
  final List<String> _filesToDelete = [];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _maxDraftController.addListener(_onDepthComponentChanged);
    _ukcController.addListener(_onDepthComponentChanged);
    _squatController.addListener(_onDepthComponentChanged);
    _arrowAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowAnimController, curve: Curves.easeInOut),
    );
    _loadLocations().then((_) {
      _prefillIfEditing();
      _refreshDepthReference();
    });
  }

  void _prefillIfEditing() {
    if (!widget.isEditing || widget.editData == null) return;
    final d = widget.editData!;

    _suspendDepthCalculation = true;
    setState(() {
      _selectedLocationId = widget.editLocationId;
      // Find location name from loaded locations
      final loc = _locations.where((l) => l.id == widget.editLocationId);
      if (loc.isNotEmpty) _selectedLocationName = loc.first.name;

      // Depth
      if (d['profundidadeTotal'] != null) {
        _depthController.text = d['profundidadeTotal'].toString();
      }
      // Max draft
      if (d['caladoMax'] != null) {
        _maxDraftController.text = d['caladoMax'].toString();
      }
      // UKC
      if (d['ukc'] != null) {
        _ukcController.text = d['ukc'].toString();
      }
      // Direction
      _direction = d['direcao'] as String?;
      // Sonar position
      _sonarPosition = d['posicaoSonda'] as String?;
      // Ship name
      if (d['nomeNavio'] != null) {
        _shipNameController.text = d['nomeNavio'].toString();
      }
      // Date
      final dataField = d['data'];
      if (dataField is Timestamp) {
        _selectedDate = dataField.toDate();
      }
      // Speed
      if (d['velocidade'] != null) {
        _speedController.text = d['velocidade'].toString();
      }
      // Squat value. Legacy records only stored a boolean and therefore do
      // not have a numeric amount that can be restored safely.
      if (d['squat'] != null) {
        _squatController.text = d['squat'].toString();
      }
      // Point
      if (d['ponto'] != null) {
        _selectedPoint = d['ponto'] as int?;
      }
      // Latitude
      if (d['latitude'] is Map) {
        final lat = d['latitude'] as Map;
        _latDegController.text = (lat['graus'] ?? '').toString();
        final latMin = (lat['minutos'] is num) ? (lat['minutos'] as num).toDouble() : (double.tryParse(lat['minutos']?.toString() ?? '') ?? 0.0);
        final latSec = double.tryParse(lat['segundos']?.toString() ?? '') ?? 0.0;
        final latDecimalMin = latSec > 0 ? latMin + (latSec / 60.0) : latMin;
        _latMinController.text = latDecimalMin == latDecimalMin.truncateToDouble()
            ? latDecimalMin.toInt().toString()
            : latDecimalMin.toStringAsFixed(1);
        _latHemisphere = (lat['hemisferio'] ?? 'S').toString();
      }
      // Longitude
      if (d['longitude'] is Map) {
        final lon = d['longitude'] as Map;
        _lonDegController.text = (lon['graus'] ?? '').toString();
        final lonMin = (lon['minutos'] is num) ? (lon['minutos'] as num).toDouble() : (double.tryParse(lon['minutos']?.toString() ?? '') ?? 0.0);
        final lonSec = double.tryParse(lon['segundos']?.toString() ?? '') ?? 0.0;
        final lonDecimalMin = lonSec > 0 ? lonMin + (lonSec / 60.0) : lonMin;
        _lonMinController.text = lonDecimalMin == lonDecimalMin.truncateToDouble()
            ? lonDecimalMin.toInt().toString()
            : lonDecimalMin.toStringAsFixed(1);
        _lonHemisphere = (lon['hemisferio'] ?? 'W').toString();
      }
      // Observations
      if (d['observacoes'] != null) {
        _observationsController.text = d['observacoes'].toString();
      }
      // Images
      if (d['imageUrls'] is List) {
        _existingImageUrls = List<String>.from(d['imageUrls']);
      }
      // File attachments
      if (d['fileAttachments'] is List) {
        _existingFileAttachments = (d['fileAttachments'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    });
    _suspendDepthCalculation = false;
    _recalculateDepth();
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    _newLocationController.dispose();
    _shipNameController.dispose();
    _depthController.dispose();
    _maxDraftController.dispose();
    _ukcController.dispose();
    _squatController.dispose();
    _speedController.dispose();
    _latDegController.dispose();
    _latMinController.dispose();
    _lonDegController.dispose();
    _lonMinController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  Future<void> _loadLocations() async {
    try {
      final locs = await _controller.getCachedLocations();

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

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double? get _calculatedDepth {
    final maxDraft = _parseDecimal(_maxDraftController.text);
    final ukc = _parseDecimal(_ukcController.text);
    if (maxDraft == null || ukc == null) return null;

    final squatText = _squatController.text.trim();
    final squat = squatText.isEmpty ? 0.0 : _parseDecimal(squatText);
    if (squat == null) return null;
    return maxDraft + ukc + squat;
  }

  void _onDepthComponentChanged() {
    if (_suspendDepthCalculation) return;
    _recalculateDepth();
  }

  void _recalculateDepth() {
    final total = _calculatedDepth;
    final value = total == null ? '' : total.toStringAsFixed(2);
    if (_depthController.text != value) _depthController.text = value;
    if (mounted) setState(() {});
  }

  Future<void> _refreshDepthReference() async {
    final reference = DepthReferenceService.resolve(_selectedLocationName);
    final requestId = ++_tideRequestId;

    if (reference?.type != DepthReferenceType.santanaTide) {
      if (!mounted) return;
      setState(() {
        _depthReference = reference;
        _santanaTideWindow = null;
        _isLoadingTide = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _depthReference = reference;
        _santanaTideWindow = null;
        _isLoadingTide = true;
      });
    }

    try {
      final window =
          await DepthReferenceService.loadSantanaTideWindow(_selectedDate);
      if (!mounted || requestId != _tideRequestId) return;
      setState(() {
        _santanaTideWindow = window;
        _isLoadingTide = false;
      });
    } catch (error) {
      debugPrint('[NavSafety] Error loading Santana tide reference: $error');
      if (!mounted || requestId != _tideRequestId) return;
      setState(() {
        _santanaTideWindow = null;
        _isLoadingTide = false;
      });
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
    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
    await _refreshDepthReference();
  }

  Future<void> _pickMeasurementTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
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
    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );
    });
    await _refreshDepthReference();
  }

  bool get _isItacoatiara {
    if (_selectedLocationName == null) return false;
    return _selectedLocationName!
        .toLowerCase()
        .contains('fundeadouro itacoatiara');
  }

  String? _validate() {
    final l10n = AppLocalizations.of(context)!;
    final hasPendingNewLocation = _newLocationController.text.trim().isNotEmpty;
    if (widget.isEditing) {
      if (_selectedLocationId == null) return l10n.locationRequired;
    } else if (_selectedLocationId == null &&
        (_selectedLocationName == null || _selectedLocationName!.trim().isEmpty) &&
        !hasPendingNewLocation) {
      return l10n.locationRequired;
    }
    if (_maxDraftController.text.trim().isEmpty) return l10n.draftRequired;
    if (_ukcController.text.trim().isEmpty) return l10n.ukcRequired;
    if (_calculatedDepth == null) return l10n.depthRequired;
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      _showSnackBar(error, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    String? createdLocationId;
    var recordPersisted = false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final pendingLocationName = _newLocationController.text.trim().isNotEmpty
          ? _newLocationController.text.trim()
          : _selectedLocationName?.trim();

      // Fetch nomeGuerra from Firestore usuarios collection
      String nomeGuerra = '';
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        nomeGuerra = (userDoc.data()?['nomeGuerra'] ?? '').toString();
      }

      final calculatedDepth = _calculatedDepth!;
      final data = <String, dynamic>{
        'profundidadeTotal': calculatedDepth,
        'data': Timestamp.fromDate(_selectedDate),
        'pilotId': user?.uid ?? '',
        'email': user?.email ?? '',
        'nomeGuerra': nomeGuerra,
      };

      final caladoMax = _parseDecimal(_maxDraftController.text);
      if (caladoMax != null) data['caladoMax'] = caladoMax;

      final ukc = _parseDecimal(_ukcController.text);
      if (ukc != null) data['ukc'] = ukc;

      final squat = _parseDecimal(_squatController.text);
      if (squat != null) data['squat'] = squat;
      data['squatConsiderado'] = squat != null && squat > 0;

      final reference = _depthReference;
      if (reference != null) {
        final referenceData = <String, dynamic>{
          'type': reference.type == DepthReferenceType.ruler
              ? 'ruler'
              : 'santanaTide',
          'name': reference.name,
          if (reference.code != null) 'code': reference.code,
        };

        final tideWindow = _santanaTideWindow;
        if (reference.type == DepthReferenceType.santanaTide) {
          referenceData['measurementTime'] = Timestamp.fromDate(_selectedDate);
          if (tideWindow != null) {
            final previousLowTide = tideWindow.previousLowTide;
            if (previousLowTide != null) {
              referenceData['previousLowTide'] = {
                'dateTime': Timestamp.fromDate(previousLowTide.dateTime),
                'height': previousLowTide.height,
              };
            }
            final nextHighTide = tideWindow.nextHighTide;
            if (nextHighTide != null) {
              referenceData['nextHighTide'] = {
                'dateTime': Timestamp.fromDate(nextHighTide.dateTime),
                'height': nextHighTide.height,
              };
            }
          }
        }

        data['depthReference'] = referenceData;
      }

      // Optional fields
      if (_direction != null) data['direcao'] = _direction;
      if (_sonarPosition != null) data['posicaoSonda'] = _sonarPosition;

      final shipName = _shipNameController.text.trim();
      if (shipName.isNotEmpty) data['nomeNavio'] = shipName;

      final speed = _parseDecimal(_speedController.text);
      if (speed != null) data['velocidade'] = speed;

      if (_isItacoatiara && _selectedPoint != null) {
        data['ponto'] = _selectedPoint;
      }

      // LAT/LONG
      if (_latDegController.text.isNotEmpty ||
          _lonDegController.text.isNotEmpty) {
        data['latitude'] = {
          'graus': int.tryParse(_latDegController.text) ?? 0,
          'minutos': double.tryParse(_latMinController.text) ?? 0.0,
          'hemisferio': _latHemisphere,
        };
        data['longitude'] = {
          'graus': int.tryParse(_lonDegController.text) ?? 0,
          'minutos': double.tryParse(_lonMinController.text) ?? 0.0,
          'hemisferio': _lonHemisphere,
        };
      }

      final obs = _observationsController.text.trim();
      if (obs.isNotEmpty) data['observacoes'] = obs;

      var locationId = _selectedLocationId;
      debugPrint(
        'NavSafetyNewRecordPage._save start: '
        'isEditing=${widget.isEditing}, selectedImages=${_selectedImages.length}, '
        'locationId=$locationId, editRecordId=${widget.editRecordId}',
      );

      if (!widget.isEditing &&
          locationId == null &&
          pendingLocationName != null &&
          pendingLocationName.isNotEmpty) {
        locationId = await _controller.addLocation(
          pendingLocationName,
          createdBy: user?.uid,
        );
        createdLocationId = locationId;
      }

      if (locationId == null) {
        throw StateError('Location ID is required to save the record.');
      }

      if (widget.isEditing) {
        final preservedImageUrls = List<String>.from(_existingImageUrls);
        final newUrls = _selectedImages.isEmpty
            ? const <String>[]
            : await ImageUploadService.uploadImages(
                _selectedImages,
                _selectedLocationId!,
                widget.editRecordId!,
              );

        List<String> newFileUrls = const <String>[];
        try {
          newFileUrls = _selectedFiles.isEmpty
              ? const <String>[]
              : await ImageUploadService.uploadFiles(
                  _selectedFiles,
                  _selectedLocationId!,
                  widget.editRecordId!,
                );
        } catch (e) {
          await ImageUploadService.deleteImages(newUrls);
          rethrow;
        }

        data['imageUrls'] = <String>[
          ...preservedImageUrls,
          ...newUrls,
        ];
        data['fileAttachments'] = <Map<String, dynamic>>[
          ..._existingFileAttachments,
          ..._buildFileAttachmentMaps(newFileUrls),
        ];

        try {
          await _controller.updateRecord(
            _selectedLocationId!,
            widget.editRecordId!,
            data,
          );
          recordPersisted = true;
        } catch (e, stackTrace) {
          debugPrint(
            'NavSafetyNewRecordPage._save failed after uploading edit images: $e',
          );
          debugPrint('$stackTrace');
          await ImageUploadService.deleteImages([...newUrls, ...newFileUrls]);
          rethrow;
        }

        if (_imagesToDelete.isNotEmpty || _filesToDelete.isNotEmpty) {
          await ImageUploadService.deleteImages(
            [..._imagesToDelete, ..._filesToDelete],
          );
        }
      } else {
        final recordRef = FirebaseFirestore.instance
            .collection('locais')
            .doc(locationId)
            .collection('registros')
            .doc();

        final newUrls = _selectedImages.isEmpty
            ? const <String>[]
            : await ImageUploadService.uploadImages(
                _selectedImages,
                locationId,
                recordRef.id,
              );

        List<String> newFileUrls = const <String>[];
        try {
          newFileUrls = _selectedFiles.isEmpty
              ? const <String>[]
              : await ImageUploadService.uploadFiles(
                  _selectedFiles,
                  locationId,
                  recordRef.id,
                );
        } catch (e) {
          await ImageUploadService.deleteImages(newUrls);
          rethrow;
        }

        if (newUrls.isNotEmpty) {
          data['imageUrls'] = newUrls;
        }

        if (newFileUrls.isNotEmpty) {
          data['fileAttachments'] = _buildFileAttachmentMaps(newFileUrls);
        }

        try {
          await recordRef.set(data);
          recordPersisted = true;
        } catch (e, stackTrace) {
          debugPrint(
            'NavSafetyNewRecordPage._save failed after uploading new record images: $e',
          );
          debugPrint('$stackTrace');
          await ImageUploadService.deleteImages([...newUrls, ...newFileUrls]);
          rethrow;
        }
      }

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      if (!widget.isEditing) {
        final locationName = pendingLocationName ?? _selectedLocationName ?? '';
        final shipName = _shipNameController.text.trim();
        final depth = _depthController.text.trim();
        final dateStr =
            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

        await _showShareDialog(
          l10n: l10n,
          locationName: locationName,
          shipName: shipName,
          depth: depth,
          nomeGuerra: nomeGuerra,
          dateStr: dateStr,
          referenceLine: _buildReferenceShareLine(l10n),
        );
      } else {
        _showSnackBar(l10n.recordUpdatedSuccess);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ImageUploadException catch (e) {
      _showSnackBar(e.message, isError: true);
    } on FirebaseException catch (e) {
      _showSnackBar(
        e.message ?? 'Nao foi possivel salvar o registro.',
        isError: true,
      );
    } catch (e, stackTrace) {
      debugPrint('NavSafetyNewRecordPage._save unexpected error: $e');
      debugPrint('$stackTrace');
      _showSnackBar(
        'Nao foi possivel salvar o registro. Tente novamente.',
        isError: true,
      );
    } finally {
      if (!recordPersisted && createdLocationId != null) {
        try {
          await _controller.deleteLocationIfEmpty(createdLocationId);
        } catch (e, stackTrace) {
          debugPrint(
            'NavSafetyNewRecordPage._save cleanup location failed: $e',
          );
          debugPrint('$stackTrace');
        }
      }

      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<Map<String, dynamic>> _buildFileAttachmentMaps(List<String> urls) {
    return List<Map<String, dynamic>>.generate(urls.length, (i) {
      final file = _selectedFiles[i];
      return <String, dynamic>{
        'url': urls[i],
        'name': file.originalName,
        'contentType':
            ImageUploadService.contentTypeFromFileName(file.originalName),
      };
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  Future<void> _showShareDialog({
    required AppLocalizations l10n,
    required String locationName,
    required String shipName,
    required String depth,
    required String nomeGuerra,
    required String dateStr,
    required String referenceLine,
  }) async {
    final shareText =
        '⚓ ${l10n.shareDepthTitle}\n'
        '\u{1F4CD} Local: $locationName\n'
        '${shipName.isNotEmpty ? '\u{1F6A2} Navio: $shipName\n' : ''}'
        '\u{1F4CF} Profundidade total: ${depth}m\n'
        '$referenceLine'
        '\u{1F464} Prático: $nomeGuerra\n'
        '\u{1F4C5} Data: $dateStr\n\n'
        '${l10n.shareDepthFooter}\nhttps://apps.apple.com/br/app/shiprate-pro/id6777518989';

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF132D4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: _teal, size: 28),
            const SizedBox(width: 10),
            Text(
              l10n.recordSaved,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.shareRecordPrompt,
          style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.noThanks,
              style: const TextStyle(color: Color(0x99FFFFFF)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              UrlLauncherService.openWhatsAppShare(shareText);
            },
            child: Text(
              l10n.shareRecord,
              style: const TextStyle(
                color: _teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildReferenceShareLine(AppLocalizations l10n) {
    final reference = _depthReference;
    if (reference == null) return '';

    if (reference.type == DepthReferenceType.ruler) {
      return '\u{1F4D0} ${reference.displayName}\n';
    }

    final window = _santanaTideWindow;
    if (window == null || !window.hasData) {
      return '\u{1F30A} ${reference.displayName}\n';
    }

    final low = window.previousLowTide;
    final high = window.nextHighTide;
    final parts = <String>[];
    if (low != null) {
      parts.add(
        '${l10n.previousLowTide} ${_formatMetersValue(low.height)} '
        '(${_formatTime(low.dateTime)})',
      );
    }
    if (high != null) {
      parts.add(
        '${l10n.nextHighTide} ${_formatMetersValue(high.height)} '
        '(${_formatTime(high.dateTime)})',
      );
    }

    return '\u{1F30A} ${reference.displayName}: ${parts.join(' → ')}\n';
  }

  String _formatMetersValue(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')}m';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectNewLocation() async {
    final name = _newLocationController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _selectedLocationId = null;
      _selectedLocationName = name;
      _showNewLocationInput = false;
    });
    await _refreshDepthReference();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A2E45),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Color(0x66FFFFFF)),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF26A69A),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            fillColor: Color(0xFF132D4A),
            filled: true,
          ),
        ),
      ),
      child: Scaffold(
      appBar: _buildAppBar(l10n),
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildSection1PassageData(l10n),
                  const SizedBox(height: 16),
                  _buildSection3ComplementaryData(l10n),
                  const SizedBox(height: 16),
                  _buildSection2TotalDepth(l10n),
                  const SizedBox(height: 16),
                  _buildSection4LatLong(l10n),
                  const SizedBox(height: 16),
                  _buildSection5Observations(l10n),
                  const SizedBox(height: 16),
                  _buildSection6Photos(l10n),
                  _buildSaveButton(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        widget.isEditing ? l10n.editRecord : l10n.newRecord,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDateField(l10n)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                controller: _speedController,
                label: l10n.speedOptional,
                icon: Icons.speed,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: '(${l10n.optional})',
                compact: true,
              ),
            ),
          ],
        ),
        if (_depthReference?.type == DepthReferenceType.santanaTide) ...[
          const SizedBox(height: 14),
          _buildMeasurementTimeField(l10n),
          const SizedBox(height: 8),
          Text(
            l10n.santanaTideReferenceHint,
            style: const TextStyle(color: Color(0x9964B5F6), fontSize: 11),
          ),
        ],
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
                _selectedLocationId == null &&
                        _selectedLocationName != null &&
                        _selectedLocationName!.isNotEmpty
                    ? '\u{1F4CD} ${_selectedLocationName!}'
                    : l10n.selectLocation,
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
                  _showNewLocationInput = false;
                  _newLocationController.clear();
                });
                unawaited(_refreshDepthReference());
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
                onTap: _selectNewLocation,
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
        Row(
          children: [
            Text(
              l10n.anchoragePt,
              style: const TextStyle(color: _textLabel, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Text(
              '(${l10n.optional})',
              style: const TextStyle(color: _textMuted, fontSize: 10),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _inputBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: _teal, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        Row(
          children: [
            Text(
              l10n.direction,
              style: const TextStyle(color: _textLabel, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Text(
              '(${l10n.optional})',
              style: const TextStyle(color: _textMuted, fontSize: 10),
            ),
          ],
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
            l10n.calculatedTotalDepth,
            style: const TextStyle(
              color: _teal,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _calculatedDepth == null
                ? '—'
                : '${_calculatedDepth!.toStringAsFixed(2).replaceAll('.', ',')} m',
            style: const TextStyle(
              color: _teal,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.depthCalculationFormula,
            style: const TextStyle(color: Color(0x9926A69A), fontSize: 11),
          ),
          if (_depthReference != null) ...[
            const SizedBox(height: 14),
            _buildDepthReferenceCard(l10n),
          ],
          const SizedBox(height: 14),
          _buildDirectionToggle(l10n),
        ],
      ),
    );
  }

  Widget _buildDepthReferenceCard(AppLocalizations l10n) {
    final reference = _depthReference!;

    if (reference.type == DepthReferenceType.ruler) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x14FFC107),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33FFC107)),
        ),
        child: Column(
          children: [
            const Icon(Icons.straighten, color: Color(0xFFFFC107), size: 20),
            const SizedBox(height: 5),
            Text(
              reference.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              l10n.rulerValuePendingWebPilot,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1464B5F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3364B5F6)),
      ),
      child: Column(
        children: [
          Text(
            reference.displayName,
            style: const TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingTide)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Color(0xFF64B5F6),
                strokeWidth: 2,
              ),
            )
          else if (_santanaTideWindow == null ||
              !_santanaTideWindow!.hasData)
            Text(
              l10n.tideReferenceUnavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMuted, fontSize: 11),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildTideEvent(
                    label: l10n.previousLowTide,
                    event: _santanaTideWindow!.previousLowTide,
                    alignment: CrossAxisAlignment.start,
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  color: const Color(0x3364B5F6),
                ),
                Expanded(
                  child: _buildTideEvent(
                    label: l10n.nextHighTide,
                    event: _santanaTideWindow!.nextHighTide,
                    alignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTideEvent({
    required String label,
    required TideReferenceEvent? event,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
          style: const TextStyle(color: _textMuted, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          event == null ? '—' : _formatMetersValue(event.height),
          style: const TextStyle(
            color: Color(0xFF90CAF9),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (event != null)
          Text(
            _formatTideDateTime(event.dateTime),
            style: const TextStyle(color: _textSecondary, fontSize: 9),
          ),
      ],
    );
  }

  String _formatTideDateTime(DateTime value) {
    final time = _formatTime(value);
    final isSameDay = value.year == _selectedDate.year &&
        value.month == _selectedDate.month &&
        value.day == _selectedDate.day;
    if (isSameDay) return time;

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month $time';
  }

  // ===========================================================================
  // SECTION 3 — COMPLEMENTARY DATA
  // ===========================================================================

  Widget _buildSection3ComplementaryData(AppLocalizations l10n) {
    return _buildSectionCard(
      icon: Icons.straighten,
      title: l10n.complementaryData,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _maxDraftController,
                label: l10n.maxDraftInput,
                icon: Icons.straighten,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                compact: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                controller: _ukcController,
                label: l10n.ukcInput,
                icon: Icons.straighten,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _squatController,
          label: l10n.squatInput,
          icon: Icons.vertical_align_bottom,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: '(${l10n.optional})',
        ),
        const SizedBox(height: 14),
        _buildSonarToggle(l10n),
      ],
    );
  }

  Widget _buildMeasurementTimeField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.measurementTime,
          style: const TextStyle(color: _textLabel, fontSize: 12),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickMeasurementTime,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _inputBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Color(0xFF64B5F6),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(_selectedDate),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
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

  Widget _buildSonarToggle(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.sonarPosition,
              style: const TextStyle(color: _textLabel, fontSize: 12),
            ),
            const SizedBox(width: 6),
            Text(
              '(${l10n.optional})',
              style: const TextStyle(color: _textMuted, fontSize: 10),
            ),
          ],
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
                  const Divider(color: Color(0x1A64B5F6), height: 1),
                  const SizedBox(height: 14),
                  const Text('Latitude',
                      style: TextStyle(color: _textLabel, fontSize: 12)),
                  const SizedBox(height: 6),
                  _buildCoordRow(
                    degController: _latDegController,
                    minController: _latMinController,
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
        _buildCoordField(minController, 6, 72),
        const Text(" \u2032 ",
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
      title: '${l10n.observations} (${l10n.optional})',
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
  // SECTION 6 — PHOTOS & FILES
  // ===========================================================================

  Future<void> _pickAttachment() async {
    final type = await _chooseAttachmentType();
    if (type == null) return;

    if (type == _AttachmentType.photo) {
      await _pickImage();
    } else {
      await _pickFile();
    }
  }

  Future<_AttachmentType?> _chooseAttachmentType() {
    final l10n = AppLocalizations.of(context)!;

    return showModalBottomSheet<_AttachmentType>(
      context: context,
      backgroundColor: _dropdownBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: _teal),
              title: Text(
                l10n.photo,
                style: const TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext, _AttachmentType.photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: _teal),
              title: Text(
                l10n.file,
                style: const TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext, _AttachmentType.file);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final file = await ImageUploadService.pickFile();
      if (file == null) return;
      _queueSelectedFile(file);
    } catch (e, stackTrace) {
      debugPrint('NavSafetyNewRecordPage._pickFile failed: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context)!.filePickError, isError: true);
    }
  }

  void _queueSelectedFile(PendingImageUpload file) {
    if (!mounted) return;

    final validationError = ImageUploadService.validateSelectedFile(file);
    if (validationError != null) {
      final l10n = AppLocalizations.of(context)!;
      _showSnackBar(
        validationError == 'fileTooLarge'
            ? l10n.fileTooLargeError
            : l10n.fileEmptyError,
        isError: true,
      );
      return;
    }

    setState(() => _selectedFiles.add(file));
  }

  Future<void> _pickImage() async {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    if (totalImages >= ImageUploadService.maxImagesPerRecord) {
      _showSnackBar(
        'Voce pode anexar no maximo ${ImageUploadService.maxImagesPerRecord} fotos.',
        isError: true,
      );
      return;
    }

    final source = kIsWeb
        ? ImagePickSource.gallery
        : await _chooseImageSource();
    if (source == null) return;

    try {
      final image = await ImageUploadService.pickImage(source);
      if (image == null) return;
      _queueSelectedImage(image);
    } catch (e, stackTrace) {
      debugPrint('NavSafetyNewRecordPage._pickImage failed: $e');
      debugPrint('$stackTrace');
      _showSnackBar(
        'Nao foi possivel selecionar a imagem neste dispositivo.',
        isError: true,
      );
    }
  }

  Future<ImagePickSource?> _chooseImageSource() {
    return showModalBottomSheet<ImagePickSource>(
      context: context,
      backgroundColor: _dropdownBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _teal),
              title: const Text(
                'Camera',
                style: TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext, ImagePickSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _teal),
              title: const Text(
                'Photo library',
                style: TextStyle(color: _textPrimary),
              ),
              onTap: () {
                Navigator.pop(sheetContext, ImagePickSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _queueSelectedImage(PendingImageUpload image) {
    final validationError = ImageUploadService.validateSelectedImage(image);

    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _selectedImages.add(image));
  }

  Widget _buildSection6Photos(AppLocalizations l10n) {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    final totalAttachments = totalImages +
        _existingFileAttachments.length +
        _selectedFiles.length;

    return _buildSectionCard(
      icon: Icons.attach_file,
      title: '${l10n.photos} / ${l10n.files} (${l10n.optional})',
      children: [
        if (totalAttachments > 0)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._existingImageUrls.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  child: Image.network(
                    entry.value,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () {
                    setState(() {
                      _imagesToDelete.add(entry.value);
                      _existingImageUrls.removeAt(entry.key);
                    });
                  },
                );
              }),
              ..._selectedImages.asMap().entries.map((entry) {
                return _buildImageThumbnail(
                  child: Image.memory(
                    entry.value.bytes,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () {
                    setState(() {
                      _selectedImages.removeAt(entry.key);
                    });
                  },
                );
              }),
              ..._existingFileAttachments.asMap().entries.map((entry) {
                final name = (entry.value['name'] ?? '').toString();
                return _buildFileThumbnail(
                  name: name.isNotEmpty ? name : l10n.file,
                  onRemove: () {
                    setState(() {
                      final url = (entry.value['url'] ?? '').toString();
                      if (url.isNotEmpty) _filesToDelete.add(url);
                      _existingFileAttachments.removeAt(entry.key);
                    });
                  },
                );
              }),
              ..._selectedFiles.asMap().entries.map((entry) {
                return _buildFileThumbnail(
                  name: entry.value.originalName,
                  onRemove: () {
                    setState(() {
                      _selectedFiles.removeAt(entry.key);
                    });
                  },
                );
              }),
            ],
          ),
        if (totalAttachments > 0) const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickAttachment,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _tealBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_file, color: _teal, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.attachFile,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (totalImages >= ImageUploadService.maxImagesPerRecord) ...[
          const SizedBox(height: 8),
          Text(
            l10n.maxPhotosReached,
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildFileThumbnail({
    required String name,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _fieldBorder),
          ),
          child: Column(
            children: [
              Icon(_fileIconForName(name), color: _teal, size: 26),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecondary, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  IconData _fileIconForName(String name) {
    final contentType = ImageUploadService.contentTypeFromFileName(name);
    if (contentType == 'application/pdf') return Icons.picture_as_pdf;
    if (ImageUploadService.isImageContentType(contentType)) return Icons.image;
    return Icons.insert_drive_file;
  }

  Widget _buildImageThumbnail({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _fieldBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
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
      margin: const EdgeInsets.only(top: 20, bottom: 24),
      child: GestureDetector(
        onTap: _isSaving || _isLoadingTide ? null : _save,
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
            child: _isSaving || _isLoadingTide
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isEditing ? l10n.updatePassage : l10n.registerPassage,
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
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textLabel, fontSize: 12),
              ),
            ),
            if (suffixText != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  suffixText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textMuted, fontSize: 10),
                ),
              ),
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
              prefixIcon: compact ? null : Icon(icon, color: iconColor, size: 20),
              border: InputBorder.none,
              isDense: compact,
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: 12,
              ),
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
