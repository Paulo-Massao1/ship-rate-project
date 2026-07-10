// lib/shared/widgets/milestone_overlay.dart

import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

/// Full-screen celebratory overlay shown when the community reaches a
/// milestone. Renders a semi-transparent scrim with a centered card that
/// fades in smoothly.
class MilestoneOverlay extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const MilestoneOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.95,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        color: const Color(0xCC000000),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1628),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x3364B5F6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0x1F64B5F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x3364B5F6)),
                        ),
                        child: const Icon(
                          Icons.directions_boat_filled,
                          color: Color(0xFF64B5F6),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: widget.onClose,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF64B5F6),
                            foregroundColor: const Color(0xFF0A1628),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.close,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
