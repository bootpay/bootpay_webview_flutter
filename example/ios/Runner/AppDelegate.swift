import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
   
   override func applicationDidBecomeActive(_ application: UIApplication) {
    NotificationCenter.default.post(name: NSNotification.Name("Bootpay_applicationDidBecomeActive"),
                                    object: nil,
                                    userInfo: nil)
   }
}

