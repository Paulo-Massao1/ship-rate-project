import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:ship_rate/core/module_access.dart';
import 'package:ship_rate/features/home/main_screen_page.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

class OperationalRestrictionsPage extends StatefulWidget {
  const OperationalRestrictionsPage({super.key});

  @override
  State<OperationalRestrictionsPage> createState() =>
      _OperationalRestrictionsPageState();
}

class _OperationalRestrictionsPageState
    extends State<OperationalRestrictionsPage> {
  static const _assetPath = 'assets/documents/parametros_operacionais.pdf';
  static const _fileName = 'parametros_operacionais.pdf';

  late final Future<Uint8List> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = ModuleAccess.canAccessRestrictedModules
        ? _loadPdfBytes()
        : Future<Uint8List>.value(Uint8List(0));
  }

  Future<Uint8List> _loadPdfBytes() async {
    final data = await rootBundle.load(_assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _sharePdf() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final bytes = await _pdfBytesFuture;
      await Printing.sharePdf(bytes: bytes, filename: _fileName);
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
    if (!ModuleAccess.canAccessRestrictedModules) {
      return const MainScreen();
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 96,
        leading: _buildBackButton(l10n),
        title: Text(
          l10n.operationalRestrictionsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.shareRecord,
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
              pdfFileName: _fileName,
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

  Widget _buildBackButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () => Navigator.maybePop(context),
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
}
