import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// In-app PDF preview whose pages accept pinch-to-zoom immediately.
///
/// The default [PdfPreview] requires a double tap before it enters its zoom
/// mode. This custom page builder keeps document scrolling and gives each page
/// its own [InteractiveViewer], so a two-finger gesture works on first touch.
class PinchZoomPdfPreview extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final Color loadingColor;

  const PinchZoomPdfPreview({
    super.key,
    required this.bytes,
    required this.fileName,
    this.loadingColor = const Color(0xFFFFB74D),
  });

  @override
  Widget build(BuildContext context) {
    return PdfPreview.builder(
      build: (_) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      useActions: false,
      pdfFileName: fileName,
      loadingWidget: Center(
        child: CircularProgressIndicator(color: loadingColor),
      ),
      pagesBuilder: (context, pages) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth - 24;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final page = pages[index];
                final aspectRatio = page.width / page.height;

                return Center(
                  child: SizedBox(
                    width: pageWidth,
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: ClipRect(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 5,
                          panEnabled: true,
                          scaleEnabled: true,
                          child: Image(
                            image: page.image,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
