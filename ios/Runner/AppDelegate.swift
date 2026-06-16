import Flutter
import UIKit
import UserNotifications
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerPluginsOnRootFlutterViewControllerIfNeeded()
    return result
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    registerPluginsOnRootFlutterViewControllerIfNeeded()
  }

  private func registerPluginsOnRootFlutterViewControllerIfNeeded() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    // Ensure plugins are registered on the Flutter engine that actually runs Dart.
    if !controller.hasPlugin("FLTFirebaseCorePlugin") {
      GeneratedPluginRegistrant.register(with: controller)
    }
  }
}
