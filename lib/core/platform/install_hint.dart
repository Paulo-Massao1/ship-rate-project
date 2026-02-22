// Conditional export: selects platform-specific implementation automatically.
// Platforms WITHOUT dart:html → install_hint_mobile.dart
// Platforms WITH dart:html (Web) → install_hint_web.dart
export 'install_hint_mobile.dart' if (dart.library.html) 'install_hint_web.dart';