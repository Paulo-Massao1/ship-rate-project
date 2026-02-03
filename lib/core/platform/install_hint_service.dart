/// Abstract interface for PWA installation hint detection.
///
/// This abstraction supports multiple platforms through conditional imports.
///
/// Implementations:
/// - Web: Returns `true` to suggest PWA installation
/// - Mobile (Android/iOS): Returns `false` (app is already native/installed)
///
/// Usage:
/// ```dart
/// final hintService = getInstallHintService();
/// if (hintService.shouldShowInstallHint()) {
///   showInstallBanner();
/// }
/// ```
abstract class InstallHintService {
  /// Determines if the app should show an installation hint.
  ///
  /// Returns:
  /// - `true`: Suggest showing "Add to Home Screen" banner
  /// - `false`: Don't show installation hint
  bool shouldShowInstallHint();
}