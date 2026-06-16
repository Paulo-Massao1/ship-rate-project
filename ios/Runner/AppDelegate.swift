import Flutter
import UIKit
import UserNotifications
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var flutterViewController: FlutterViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterViewController = window?.rootViewController as? FlutterViewController

    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func registrar(forPlugin pluginKey: String) -> FlutterPluginRegistrar? {
    if let controller = currentFlutterViewController() {
      return controller.registrar(forPlugin: pluginKey)
    }

    return super.registrar(forPlugin: pluginKey)
  }

  override func hasPlugin(_ pluginKey: String) -> Bool {
    if let controller = currentFlutterViewController() {
      return controller.hasPlugin(pluginKey)
    }

    return super.hasPlugin(pluginKey)
  }

  override func valuePublished(byPlugin pluginKey: String) -> NSObject? {
    if let controller = currentFlutterViewController() {
      return controller.valuePublished(byPlugin: pluginKey)
    }

    return super.valuePublished(byPlugin: pluginKey)
  }

  private func currentFlutterViewController() -> FlutterViewController? {
    if let controller = flutterViewController {
      return controller
    }

    flutterViewController = window?.rootViewController as? FlutterViewController
    return flutterViewController
  }
}
