import '../../core/platform/install_hint.dart';

/// Controller responsible for MainScreen business logic.
///
/// Responsibilities:
/// - Check if PWA installation hint should be displayed
/// - Centralize home screen actions (logout, checks, etc.)
/// - Separate business logic from presentation layer
///
/// PWA Install Hint:
/// Uses platform-specific implementation via conditional imports:
/// - Mobile (Android/iOS): Always returns `false` (app is native/installed)
/// - Web (PWA): Checks `matchMedia('(display-mode: standalone)')`
///
/// Future enhancements:
/// - App version verification
/// - Initial data loading
/// - Global home state management
/// - Offline data synchronization
class MainScreenController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final _installHintService = getInstallHintService();

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Checks if PWA installation hint should be displayed.
  ///
  /// Behavior by platform:
  /// - Web (browser mode): Returns `true` - PWA not installed yet
  /// - Web (standalone/installed): Returns `false` - PWA already installed
  /// - Mobile (Android/iOS): Always returns `false` - native app
  ///
  /// Returns:
  /// - `true`: Should display installation hint banner
  /// - `false`: Should not display installation hint
  ///
  /// Example:
  /// ```dart
  /// if (controller.shouldShowInstallHint()) {
  ///   showInstallBanner(context);
  /// }
  /// ```
  bool shouldShowInstallHint() {
    return _installHintService.shouldShowInstallHint();
  }

  /// Logs out the current user.
  ///
  /// Note: This is a placeholder method. The actual logout implementation
  /// is delegated to [AuthController]. This method exists to maintain
  /// separation of concerns - UI doesn't interact with Firebase directly.
  ///
  /// Implementation:
  /// ```dart
  /// final authController = AuthController();
  /// await authController.logout();
  /// ```
  Future<void> logout() async {
    // Delegated to AuthController in the UI layer
    // Kept here for future enhancements (cleanup, analytics, etc.)
  }
}