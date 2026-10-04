import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:ship_rate/core/module_access.dart';
import 'package:ship_rate/features/home/main_screen_page.dart';
import 'package:ship_rate/l10n/app_localizations.dart';
import 'package:ship_rate/shared/widgets/pdf_viewer_app_bar.dart';
import 'package:ship_rate/shared/widgets/pinch_zoom_pdf_preview.dart';

class MaxDraftsPage extends StatefulWidget {
  const MaxDraftsPage({super.key});

  @override
  State<MaxDraftsPage> createState() => _MaxDraftsPageState();
}

class _MaxDraftsPageState extends State<MaxDraftsPage> {
  static const _assetPath = 'assets/documents/calados_maximos.pdf';
  static const _fileName = 'calados_maximos.pdf';

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
      appBar: PdfViewerAppBar(
        title: l10n.maxDraftsTitle,
        backLabel: l10n.back,
        onBack: () => Navigator.maybePop(context),
        shareTooltip: l10n.shareRecord,
        onShare: _sharePdf,
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

            return PinchZoomPdfPreview(
              bytes: bytes,
              fileName: _fileName,
              zoomOutTooltip: l10n.pdfZoomOutTooltip,
              resetZoomTooltip: l10n.pdfResetZoomTooltip,
              zoomInTooltip: l10n.pdfZoomInTooltip,
            );
          },
        ),
      ),
    );
  }

}
