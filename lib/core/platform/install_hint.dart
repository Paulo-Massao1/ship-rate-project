/// Conditional export for automatic platform-specific implementation.
///
/// This mechanism uses Dart's **Conditional Imports/Exports** feature
/// to select the appropriate file based on the execution environment.
///
/// Resolution:
/// - Platforms WITHOUT `dart:html` → exports `install_hint_mobile.dart`
/// - Platforms WITH `dart:html` (Web) → exports `install_hint_web.dart`
///
/// Usage:
/// ```dart
/// import 'install_hint.dart';
///
/// final service = getInstallHintService();
/// if (service.shouldShowInstallHint()) {
///   showInstallBanner();
/// }
/// ```
///
/// Benefits:
/// - Avoids `kIsWeb` checks in widgets
/// - Separates platform responsibilities
/// - Reduces code duplication
/// - Maintains clean, scalable design
export 'install_hint_mobile.dart' if (dart.library.html) 'install_hint_web.dart';