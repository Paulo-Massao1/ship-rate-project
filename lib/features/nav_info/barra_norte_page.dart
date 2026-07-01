import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

class BarraNortePage extends StatefulWidget {
  const BarraNortePage({super.key});

  @override
  State<BarraNortePage> createState() => _BarraNortePageState();
}

class _BarraNortePageState extends State<BarraNortePage> {
  static const _orange = Color(0xFFFFB74D);
  static const _red = Color(0xFFEF5350);

  bool get _isCspam {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.toLowerCase().endsWith('@cspam.com.br');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _BarraNorteText.fromLocale(l10n.localeName);

    return Scaffold(
      appBar: _buildAppBar(l10n.barraNorteTitle, l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: _isCspam
            ? _buildBlockedState(l10n)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    children: [
                      _buildSection(
                        title: text.schedulePobs,
                        children: [
                          _buildPdfTile(
                            title: text.instruction,
                            document: _BarraNorteDocument.pdf1(text),
                          ),
                          _buildPdfTile(
                            title: text.calendar,
                            document: _BarraNorteDocument.pdf11(text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSection(
                        title: text.onePilotProcedure,
                        children: [
                          _buildPdfTile(
                            title: text.entry,
                            document: _BarraNorteDocument.pdf2(text),
                          ),
                          _buildPdfTile(
                            title: text.exit,
                            document: _BarraNorteDocument.pdf3(text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSection(
                        title: text.twoPilotsProcedure,
                        children: [
                          _buildGroup(
                            title: text.entry,
                            children: [
                              _buildPdfTile(
                                title: text.draftGreater,
                                document: _BarraNorteDocument.pdf4(text),
                              ),
                              _buildPdfTile(
                                title: text.draftLessOrEqual,
                                document: _BarraNorteDocument.pdf5(text),
                              ),
                            ],
                          ),
                          _buildGroup(
                            title: text.exit,
                            children: [
                              _buildPdfTile(
                                title: text.draftGreater,
                                document: _BarraNorteDocument.pdf6(text),
                              ),
                              _buildPdfTile(
                                title: text.draftLessOrEqual,
                                document: _BarraNorteDocument.pdf7(text),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildSection(
                        title: text.shipWaypoints,
                        children: [
                          _buildPdfTile(
                            title: text.barraNorte,
                            document: _BarraNorteDocument.pdf8(text),
                          ),
                          _buildGroup(
                            title: text.amazonRiver,
                            children: [
                              _buildPdfTile(
                                title: text.entry,
                                document: _BarraNorteDocument.pdf9(text),
                              ),
                              _buildPdfTile(
                                title: text.exit,
                                document: _BarraNorteDocument.pdf10(text),
                              ),
                            ],
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

  PreferredSizeWidget _buildAppBar(
    String title,
    AppLocalizations l10n, {
    List<Widget>? actions,
  }) {
    return AppBar(
      leadingWidth: 96,
      leading: _buildBarraNorteBackButton(
        label: l10n.back,
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      actions: actions,
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

  Widget _buildBlockedState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0x1AEF5350),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66EF5350)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: _red, size: 36),
              const SizedBox(height: 14),
              Text(
                l10n.barraNorteBlocked,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFB74D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x55FFB74D)),
                ),
                child: const Icon(Icons.folder_open, color: _orange, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0x08FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPdfTile({
    required String title,
    required _BarraNorteDocument document,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDocument(document),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: _orange,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PDF ${document.number}',
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDocument(_BarraNorteDocument document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BarraNortePdfPage(document: document),
      ),
    );
  }
}

class _BarraNortePdfPage extends StatefulWidget {
  final _BarraNorteDocument document;

  const _BarraNortePdfPage({required this.document});

  @override
  State<_BarraNortePdfPage> createState() => _BarraNortePdfPageState();
}

class _BarraNortePdfPageState extends State<_BarraNortePdfPage> {
  late final Future<Uint8List> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _loadPdfBytes();
  }

  Future<Uint8List> _loadPdfBytes() async {
    final data = await rootBundle.load(widget.document.assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _sharePdf() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final bytes = await _pdfBytesFuture;
      await Printing.sharePdf(bytes: bytes, filename: widget.document.fileName);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _BarraNorteText.fromLocale(l10n.localeName);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 96,
        leading: _buildBarraNorteBackButton(
          label: l10n.back,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: text.sharePdf,
            onPressed: _sharePdf,
          ),
        ],
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
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: FutureBuilder<Uint8List>(
          future: _pdfBytesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.errorLoadingData(snapshot.error.toString()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
              );
            }

            final bytes = snapshot.data!;

            return PdfPreview(
              build: (_) async => bytes,
              allowPrinting: false,
              allowSharing: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              useActions: false,
              pdfFileName: widget.document.fileName,
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
              ),
              actionBarTheme: const PdfActionBarTheme(
                backgroundColor: Color(0xFF0A1628),
                iconColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildBarraNorteBackButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      padding: const EdgeInsets.only(left: 8, right: 6),
      minimumSize: const Size(0, kToolbarHeight),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: const Icon(Icons.arrow_back_ios_new, size: 15),
    label: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _BarraNorteDocument {
  final int number;
  final String title;
  final String assetPath;

  const _BarraNorteDocument({
    required this.number,
    required this.title,
    required this.assetPath,
  });

  String get fileName => assetPath.split('/').last;

  static _BarraNorteDocument pdf1(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 1,
        title: text.instruction,
        assetPath:
            'assets/documents/barra_norte/PDF 1 - Instruc\u0327a\u0303o .pdf',
      );

  static _BarraNorteDocument pdf2(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 2,
        title: '${text.onePilotProcedure} - ${text.entry}',
        assetPath: 'assets/documents/barra_norte/PDF 2 - Entrada.pdf',
      );

  static _BarraNorteDocument pdf3(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 3,
        title: '${text.onePilotProcedure} - ${text.exit}',
        assetPath: 'assets/documents/barra_norte/PDF 3 - Entrada.pdf',
      );

  static _BarraNorteDocument pdf4(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 4,
        title: '${text.twoPilotsProcedure} - ${text.entry} - '
            '${text.draftGreater}',
        assetPath:
            'assets/documents/barra_norte/PDF 4 - Entrada  11,50m .pdf',
      );

  static _BarraNorteDocument pdf5(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 5,
        title: '${text.twoPilotsProcedure} - ${text.entry} - '
            '${text.draftLessOrEqual}',
        assetPath:
            'assets/documents/barra_norte/PDF  5 - Entrada = 11,50m .pdf',
      );

  static _BarraNorteDocument pdf6(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 6,
        title: '${text.twoPilotsProcedure} - ${text.exit} - '
            '${text.draftGreater}',
        assetPath:
            'assets/documents/barra_norte/PDF  6 - Sai\u0301da  11,50m .pdf',
      );

  static _BarraNorteDocument pdf7(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 7,
        title: '${text.twoPilotsProcedure} - ${text.exit} - '
            '${text.draftLessOrEqual}',
        assetPath:
            'assets/documents/barra_norte/PDF  7 - Sai\u0301da = 11,50m .pdf',
      );

  static _BarraNorteDocument pdf8(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 8,
        title: '${text.shipWaypoints} - ${text.barraNorte}',
        assetPath: 'assets/documents/barra_norte/PDF 8 - BARRA NORTE.pdf',
      );

  static _BarraNorteDocument pdf9(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 9,
        title: '${text.amazonRiver} - ${text.entry}',
        assetPath: 'assets/documents/barra_norte/PDF 9 - ENTRADA.pdf',
      );

  static _BarraNorteDocument pdf10(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 10,
        title: '${text.amazonRiver} - ${text.exit}',
        assetPath:
            'assets/documents/barra_norte/PDF 10 - SAI\u0301DA .pdf',
      );

  static _BarraNorteDocument pdf11(_BarraNorteText text) =>
      _BarraNorteDocument(
        number: 11,
        title: text.calendar,
        assetPath:
            'assets/documents/barra_norte/PDF 11 - Calenda\u0301rio 2026 .pdf',
      );
}

class _BarraNorteText {
  final bool isPortuguese;

  const _BarraNorteText._(this.isPortuguese);

  factory _BarraNorteText.fromLocale(String localeName) {
    return _BarraNorteText._(localeName.toLowerCase().startsWith('pt'));
  }

  String get schedulePobs =>
      isPortuguese ? "A. Agendamento de POB's" : "A. POB's Scheduling";
  String get instruction => isPortuguese ? 'Instrução' : 'Instruction';
  String get calendar => isPortuguese ? 'Calendário' : 'Calendar';
  String get onePilotProcedure => isPortuguese
      ? 'B. Procedimento com 1 Prático'
      : 'B. Procedure with 1 Pilot';
  String get twoPilotsProcedure => isPortuguese
      ? 'C. Procedimento com 2 Práticos'
      : 'C. Procedure with 2 Pilots';
  String get shipWaypoints => isPortuguese
      ? 'D. Waypoints para Navios'
      : 'D. Waypoints for Ships';
  String get entry => isPortuguese ? 'Entrada' : 'Entry';
  String get exit => isPortuguese ? 'Saída' : 'Exit';
  String get draftGreater => isPortuguese
      ? 'Calado > 11,50m'
      : 'Draft > 11.50m';
  String get draftLessOrEqual => isPortuguese
      ? 'Calado ≤ 11,50m'
      : 'Draft ≤ 11.50m';
  String get barraNorte => 'Barra Norte';
  String get amazonRiver => isPortuguese ? 'Rio Amazonas' : 'Amazon River';
  String get sharePdf => isPortuguese ? 'Compartilhar PDF' : 'Share PDF';
}
