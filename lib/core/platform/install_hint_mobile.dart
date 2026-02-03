import 'install_hint_service.dart';

/// Mobile implementation of the installation hint service.
///
/// On mobile platforms (Android/iOS running as Flutter app or installed PWA),
/// the installation hint is never needed.
///
/// This class implements [InstallHintService] to ensure cross-platform
/// consistency via conditional imports.
class InstallHintMobileService implements InstallHintService {
  /// Always returns `false` on mobile platforms.
  ///
  /// Mobile apps don't need PWA installation prompts since they're
  /// either native apps or already installed PWAs.
  @override
  bool shouldShowInstallHint() => false;
}

/// Factory function for mobile platform.
///
/// Returns the mobile implementation which always reports
/// no installation hint needed.
InstallHintService getInstallHintService() => InstallHintMobileService();