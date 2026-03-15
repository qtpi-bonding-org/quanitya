import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure notification delegate for iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Method channel: exclude a file from iCloud backup
    // Called by BackupExclusionService after DB is opened each app start.
    let backupChannel = FlutterMethodChannel(
      name: "com.quanitya.app/backup",
      binaryMessenger: self.registrar(forPlugin: "backup")!.messenger()
    )
    backupChannel.setMethodCallHandler { call, result in
      if call.method == "excludeFromBackup" {
        guard let args = call.arguments as? [String: String],
              let path = args["path"] else {
          result(FlutterError(
            code: "INVALID_ARGS",
            message: "path argument required",
            details: nil
          ))
          return
        }
        var url = URL(fileURLWithPath: path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(true)
        } catch {
          result(FlutterError(
            code: "BACKUP_EXCLUSION_FAILED",
            message: error.localizedDescription,
            details: nil
          ))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
