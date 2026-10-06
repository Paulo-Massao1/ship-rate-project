import 'package:flutter/material.dart';

/// Shared visual identity for modules that appear in more than one surface.
class ModuleVisuals {
  ModuleVisuals._();

  /// A route changing direction represents a vessel maneuver without reusing
  /// the anchor from Depths or the bidirectional arrows from Crossings.
  static const maneuverIcon = Icons.alt_route;
  static const maneuverColor = Color(0xFFFF8A65);
  static const maneuverSurface = Color(0x0FFF8A65);
  static const maneuverBackground = Color(0x1FFF8A65);
  static const maneuverBorder = Color(0x40FF8A65);
  static const maneuverCardBorder = Color(0x33FF8A65);
}
