import 'package:flutter/material.dart';

/// Fixed, responsive header shared by every in-app PDF viewer.
class PdfViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PdfViewerAppBar({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    required this.shareTooltip,
    required this.onShare,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;
  final String shareTooltip;
  final VoidCallback onShare;

  static const _height = 68.0;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final titleFontSize = title.length > 36 ? 13.0 : 15.0;

    return AppBar(
      toolbarHeight: _height,
      leadingWidth: 88,
      leading: TextButton.icon(
        onPressed: onBack,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.only(left: 8, right: 4),
          minimumSize: const Size(0, _height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.arrow_back_ios_new, size: 15),
        label: Text(
          backLabel,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      titleSpacing: 4,
      title: Text(
        title,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.fade,
        style: TextStyle(
          color: Colors.white,
          fontSize: titleFontSize,
          height: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        SizedBox(
          width: 48,
          child: IconButton(
            icon: const Icon(Icons.share),
            tooltip: shareTooltip,
            onPressed: onShare,
          ),
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
    );
  }
}
