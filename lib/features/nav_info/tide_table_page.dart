import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:ship_rate/data/models/tide_entry.dart';
import 'package:ship_rate/data/services/tide_data_service.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

class TideTablePage extends StatefulWidget {
  const TideTablePage({super.key});

  @override
  State<TideTablePage> createState() => _TideTablePageState();
}

class _TideTablePageState extends State<TideTablePage> {
  static const _teal = Color(0xFF26A69A);
  static const _lowTideYellow = Color(0xFFFFB74D);
  static final _firstSelectableDate = DateTime(2026, 1, 2);
  static final _lastSelectableDate = DateTime(2026, 12, 28);
  static const _sourcePdfAssets = {
    'santana':
        'assets/tide_data_source/3 - PORTO DE SANTANA - 19 - 21_260627_151801.pdf',
    'arco_lamoso': 'assets/tide_data_source/PDF.pdf',
    'pem15': 'assets/tide_data_source/PDF (1).pdf',
    'curua':
        'assets/tide_data_source/2 -IGARAPÉ GRANDE DO CURUÁ - 2026 - 16 - 18_260627_151844.pdf',
    'breves':
        'assets/tide_data_source/9 - ATRACADOURO DE BREVES 37 - 39_260627_182000.pdf',
  };

  late DateTime _selectedDate;
  late DateTime _pendingDate;
  _TideLocationOption? _selectedLocation;
  TideLocation? _tideLocation;
  List<TideDay> _tideDays = const [];
  bool _loading = false;
  Object? _error;

  bool get _isCspam {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.toLowerCase().endsWith('@cspam.com.br');
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _defaultDate();
    _pendingDate = _selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _TideTableText.fromLocale(l10n.localeName);

    return PopScope(
      canPop: _selectedLocation == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedLocation != null) {
          _returnToLocationSelection();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(l10n),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: _selectedLocation == null
                  ? _buildLocationSelection(text)
                  : _buildDateAndResults(l10n, text),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      leadingWidth: 96,
      leading: _buildBackButton(l10n),
      title: Text(
        l10n.tideTableTitle,
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
    );
  }

  Widget _buildBackButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: _handleBackPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.only(left: 8, right: 6),
        minimumSize: const Size(0, kToolbarHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: 15),
      label: Text(
        l10n.back,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLocationSelection(_TideTableText text) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        _buildLocationSection(
          text.amapa,
          [
            _TideLocationOption(
              key: 'santana',
              name: text.santana,
            ),
          ],
          text,
        ),
        const SizedBox(height: 24),
        _buildLocationSection(
          text.barraNorte,
          [
            _TideLocationOption(
              key: 'arco_lamoso',
              name: text.arcoLamoso,
            ),
            _TideLocationOption(
              key: 'pem15',
              name: text.pem15,
              restricted: true,
            ),
            _TideLocationOption(
              key: 'curua',
              name: text.curua,
            ),
          ],
          text,
        ),
        const SizedBox(height: 24),
        _buildLocationSection(
          text.paraState,
          [
            _TideLocationOption(
              key: 'breves',
              name: text.breves,
            ),
          ],
          text,
        ),
      ],
    );
  }

  Widget _buildLocationSection(
    String title,
    List<_TideLocationOption> locations,
    _TideTableText text,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: _teal,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ),
        ...locations.map(
          (location) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildLocationCard(location, text),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    _TideLocationOption location,
    _TideTableText text,
  ) {
    final borderColor = location.restricted
        ? const Color(0x55EF5350)
        : const Color(0x3326A69A);
    final iconColor = location.restricted ? const Color(0xFFEF5350) : _teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onLocationTap(location),
        borderRadius: BorderRadius.circular(14),
        splashColor: borderColor,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withValues(alpha: 0.28)),
                ),
                child: Icon(Icons.location_on_outlined, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  location.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (location.restricted) ...[
                const SizedBox(width: 8),
                _buildRestrictedBadge(text.restricted),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateAndResults(
    AppLocalizations l10n,
    _TideTableText text,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        if (_tideLocation != null) _buildLocationInfo(_tideLocation!, text),
        const SizedBox(height: 16),
        _buildDateSelector(text),
        const SizedBox(height: 18),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: CircularProgressIndicator(color: _teal),
            ),
          )
        else if (_error != null)
          _buildErrorCard(l10n)
        else if (_tideDays.isNotEmpty) ...[
          _buildLegend(text),
          const SizedBox(height: 12),
          ..._tideDays.map(
            (day) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDayCard(day, text),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationInfo(TideLocation location, _TideTableText text) {
    final hasCoordinates =
        location.latitude.isNotEmpty && location.longitude.isNotEmpty;
    final sourcePdfAsset = _selectedSourcePdfAsset;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3326A69A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (hasCoordinates)
            Text(
              '${location.latitude} - ${location.longitude}',
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
            ),
          if (hasCoordinates) const SizedBox(height: 4),
          Text(
            location.timezone,
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
          ),
          if (sourcePdfAsset != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _shareSourcePdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  side: const BorderSide(color: Color(0x6626A69A)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: Text(
                  text.informationSource,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelector(_TideTableText text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x3326A69A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: _teal,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      text.formatDateField(_pendingDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _consult,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                text.consult,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(_TideTableText text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          _buildLegendItem(Colors.white, text.highTide),
          const SizedBox(width: 18),
          _buildLegendItem(_lowTideYellow, text.lowTide),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(TideDay day, _TideTableText text) {
    final isSelected = _isSameDate(day.date, _selectedDate);
    final isPreviousDay =
        _isSameDate(day.date, _selectedDate.subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _teal : const Color(0x1AFFFFFF),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  text.formatDayHeader(day.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isSelected || isPreviousDay)
                Text(
                  isSelected ? text.selectedDateLabel : text.previousDayLabel,
                  style: TextStyle(
                    color: isSelected ? _teal : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth < 360 ? 1 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: day.entries.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 50,
                ),
                itemBuilder: (context, index) {
                  return _buildTideEntry(day.entries[index], text);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTideEntry(TideEntry entry, _TideTableText text) {
    final color = entry.isHighTide ? Colors.white : _lowTideYellow;
    final background = entry.isHighTide
        ? const Color(0x12FFFFFF)
        : const Color(0x1AFFB74D);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 3, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    entry.time,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    text.formatHeight(entry.height),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x33EF5350),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x66EF5350)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFEF5350),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildErrorCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AEF5350),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66EF5350)),
      ),
      child: Text(
        l10n.errorLoadingData(_error.toString()),
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }

  void _onLocationTap(_TideLocationOption location) {
    if (location.restricted && _isCspam) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.barraNorteBlocked),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = location;
      _selectedDate = _defaultDate();
      _pendingDate = _selectedDate;
      _tideLocation = null;
      _tideDays = const [];
      _error = null;
    });
    _loadTides();
  }

  void _handleBackPressed() {
    if (_selectedLocation == null) {
      Navigator.maybePop(context);
      return;
    }

    _returnToLocationSelection();
  }

  void _returnToLocationSelection() {
    setState(() {
      _selectedLocation = null;
      _tideLocation = null;
      _tideDays = const [];
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pendingDate,
      firstDate: _firstSelectableDate,
      lastDate: _lastSelectableDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _teal,
              onPrimary: Colors.white,
              surface: Color(0xFF102A43),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _pendingDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _consult() {
    setState(() {
      _selectedDate = _pendingDate;
    });
    _loadTides();
  }

  Future<void> _loadTides() async {
    final location = _selectedLocation;
    if (location == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tideLocation = await TideDataService.getLocation(location.key);
      final tideDays = await TideDataService.getTides(
        location.key,
        _selectedDate,
      );
      if (!mounted) return;
      setState(() {
        _tideLocation = tideLocation;
        _tideDays = tideDays;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  String? get _selectedSourcePdfAsset {
    final location = _selectedLocation;
    if (location == null) return null;
    return _sourcePdfAssets[location.key];
  }

  Future<void> _shareSourcePdf() async {
    final sourcePdfAsset = _selectedSourcePdfAsset;
    if (sourcePdfAsset == null) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      final data = await rootBundle.load(sourcePdfAsset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: _assetFileName(sourcePdfAsset),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingData(error.toString())),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _assetFileName(String assetPath) {
    final separatorIndex = assetPath.lastIndexOf('/');
    if (separatorIndex < 0) return assetPath;
    return assetPath.substring(separatorIndex + 1);
  }

  DateTime _defaultDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(_firstSelectableDate)) return _firstSelectableDate;
    if (today.isAfter(_lastSelectableDate)) return _lastSelectableDate;
    return today;
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _TideLocationOption {
  final String key;
  final String name;
  final bool restricted;

  const _TideLocationOption({
    required this.key,
    required this.name,
    this.restricted = false,
  });
}

class _TideTableText {
  final bool isPortuguese;

  const _TideTableText._(this.isPortuguese);

  factory _TideTableText.fromLocale(String localeName) {
    return _TideTableText._(localeName.toLowerCase().startsWith('pt'));
  }

  String get amapa => 'Amapá';
  String get barraNorte => 'Barra Norte';
  String get paraState => 'Pará';
  String get santana => 'Porto de Santana';
  String get arcoLamoso => 'Arco Lamoso';
  String get pem15 => 'PEM 15';
  String get curua => 'Igarapé Grande do Curuá';
  String get breves => 'Atracadouro de Breves';
  String get restricted => isPortuguese ? 'Restrito' : 'Restricted';
  String get consult => isPortuguese ? 'Consultar' : 'Search';
  String get highTide => isPortuguese ? 'Preamar' : 'High tide';
  String get lowTide => isPortuguese ? 'Baixamar' : 'Low tide';
  String get informationSource =>
      isPortuguese ? 'Origem da informação' : 'Information source';
  String get selectedDateLabel =>
      isPortuguese ? '(data selecionada)' : '(selected date)';
  String get previousDayLabel =>
      isPortuguese ? '(dia anterior)' : '(previous day)';

  String formatDateField(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    if (isPortuguese) return '$day/$month/${date.year}';
    return '$month/$day/${date.year}';
  }

  String formatDayHeader(DateTime date) {
    final months = isPortuguese
        ? const [
            'JAN',
            'FEV',
            'MAR',
            'ABR',
            'MAI',
            'JUN',
            'JUL',
            'AGO',
            'SET',
            'OUT',
            'NOV',
            'DEZ',
          ]
        : const [
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MAY',
            'JUN',
            'JUL',
            'AUG',
            'SEP',
            'OCT',
            'NOV',
            'DEC',
          ];
    final weekdays = isPortuguese
        ? const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']
        : const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} - ${weekdays[date.weekday - 1]}';
  }

  String formatHeight(double height) {
    final value = height.toStringAsFixed(2);
    return '${isPortuguese ? value.replaceAll('.', ',') : value} m';
  }
}
