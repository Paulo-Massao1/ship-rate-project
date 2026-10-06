import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// In-app PDF preview whose pages accept pinch-to-zoom immediately.
///
/// The default [PdfPreview] requires a double tap before it enters its zoom
/// mode. This custom page builder keeps document scrolling and gives each page
/// its own [InteractiveViewer], so a two-finger gesture works on first touch.
class PinchZoomPdfPreview extends StatelessWidget {
  /// The default preview resolution follows the viewport width, which becomes
  /// visibly soft as soon as a rasterized page is enlarged. A fixed print-like
  /// resolution preserves table text while keeping multi-page memory bounded.
  static const double _previewDpi = 240;

  final Uint8List bytes;
  final String fileName;
  final Color loadingColor;
  final String zoomOutTooltip;
  final String resetZoomTooltip;
  final String zoomInTooltip;

  const PinchZoomPdfPreview({
    super.key,
    required this.bytes,
    required this.fileName,
    required this.zoomOutTooltip,
    required this.resetZoomTooltip,
    required this.zoomInTooltip,
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
      dpi: _previewDpi,
      pdfFileName: fileName,
      loadingWidget: Center(
        child: CircularProgressIndicator(color: loadingColor),
      ),
      pagesBuilder: (_, pages) {
        // `printing` may append rendered pages to the same mutable list. Keep
        // an immutable snapshot and recreate the viewer when its length
        // changes so page images and zoom controllers always share indexes.
        final pageSnapshot = List<PdfPreviewPageData>.unmodifiable(pages);
        return _PdfPagesViewer(
          key: ValueKey(pageSnapshot.length),
          pages: pageSnapshot,
          zoomOutTooltip: zoomOutTooltip,
          resetZoomTooltip: resetZoomTooltip,
          zoomInTooltip: zoomInTooltip,
        );
      },
    );
  }
}

class _PdfPagesViewer extends StatefulWidget {
  const _PdfPagesViewer({
    super.key,
    required this.pages,
    required this.zoomOutTooltip,
    required this.resetZoomTooltip,
    required this.zoomInTooltip,
  });

  final List<PdfPreviewPageData> pages;
  final String zoomOutTooltip;
  final String resetZoomTooltip;
  final String zoomInTooltip;

  @override
  State<_PdfPagesViewer> createState() => _PdfPagesViewerState();
}

class _PdfPagesViewerState extends State<_PdfPagesViewer> {
  static const _minScale = 1.0;
  static const _maxScale = 6.0;

  late final PageController _pageController;
  late List<TransformationController> _zoomControllers;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _zoomControllers = _createZoomControllers();
  }

  @override
  void didUpdateWidget(covariant _PdfPagesViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pages.length == widget.pages.length) return;

    for (final controller in _zoomControllers) {
      controller.dispose();
    }
    _zoomControllers = _createZoomControllers();
    _currentPage = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  List<TransformationController> _createZoomControllers() => List.generate(
    widget.pages.length,
    (_) => TransformationController(),
    growable: false,
  );

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _zoomControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setScale(double scale) {
    if (_zoomControllers.isEmpty) return;
    final clampedScale = scale.clamp(_minScale, _maxScale);
    _zoomControllers[_currentPage].value = Matrix4.diagonal3Values(
      clampedScale,
      clampedScale,
      1,
    );
    setState(() {});
  }

  double get _currentScale {
    if (_zoomControllers.isEmpty) return _minScale;
    return _zoomControllers[_currentPage].value.getMaxScaleOnAxis();
  }

  void _changePage(int delta) {
    final nextPage = (_currentPage + delta).clamp(0, widget.pages.length - 1);
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: const Color(0xFF111820),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final page = widget.pages[index];

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 68, 12, 70),
                child: InteractiveViewer(
                  transformationController: _zoomControllers[index],
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(80),
                  onInteractionEnd: (_) => setState(() {}),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: page.width / page.height,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Image(
                          image: page.image,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: _PageNavigation(
                  currentPage: _currentPage,
                  pageCount: widget.pages.length,
                  onPrevious: _currentPage > 0
                      ? () => _changePage(-1)
                      : null,
                  onNext: _currentPage < widget.pages.length - 1
                      ? () => _changePage(1)
                      : null,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _ZoomControls(
                scale: _currentScale,
                zoomOutTooltip: widget.zoomOutTooltip,
                resetZoomTooltip: widget.resetZoomTooltip,
                zoomInTooltip: widget.zoomInTooltip,
                onZoomOut: _currentScale > _minScale
                    ? () => _setScale(_currentScale - 0.5)
                    : null,
                onReset: () => _setScale(_minScale),
                onZoomIn: _currentScale < _maxScale
                    ? () => _setScale(_currentScale + 0.5)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageNavigation extends StatelessWidget {
  const _PageNavigation({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);

    return _PdfControlSurface(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pageCount > 1)
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left, size: 26),
              tooltip: materialL10n.previousPageTooltip,
              visualDensity: VisualDensity.compact,
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: pageCount > 1 ? 0 : 12),
            child: Text(
              '${currentPage + 1} / $pageCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (pageCount > 1)
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, size: 26),
              tooltip: materialL10n.nextPageTooltip,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.scale,
    required this.zoomOutTooltip,
    required this.resetZoomTooltip,
    required this.zoomInTooltip,
    required this.onZoomOut,
    required this.onReset,
    required this.onZoomIn,
  });

  final double scale;
  final String zoomOutTooltip;
  final String resetZoomTooltip;
  final String zoomInTooltip;
  final VoidCallback? onZoomOut;
  final VoidCallback onReset;
  final VoidCallback? onZoomIn;

  @override
  Widget build(BuildContext context) {
    return _PdfControlSurface(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove),
            tooltip: zoomOutTooltip,
            visualDensity: VisualDensity.compact,
          ),
          Tooltip(
            message: resetZoomTooltip,
            child: InkWell(
              onTap: onReset,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  '${(scale * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onZoomIn,
            icon: const Icon(Icons.add),
            tooltip: zoomInTooltip,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _PdfControlSurface extends StatelessWidget {
  const _PdfControlSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE60A1628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      clipBehavior: Clip.antiAlias,
      textStyle: const TextStyle(color: Colors.white),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white, size: 20),
        child: child,
      ),
    );
  }
}
