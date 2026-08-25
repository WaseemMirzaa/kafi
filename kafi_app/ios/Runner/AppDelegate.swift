import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Native Firebase must be ready before plugin registration or APNs token
    // forwarding — Auth.auth() fatals if the default app is not configured yet.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GMSServices.provideAPIKey("AIzaSyDqQUR6ygHdXRDDUmJ7Xr02A2HCMH92Lvk")
    GeneratedPluginRegistrant.register(with: self)

    // Push: UNUserNotificationCenter + remote registration so FCM can bind an
    // APNs device token (required for iOS getToken / delivery).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Phone Auth silent-push + FCM both need the same APNs device token.
    if FirebaseApp.app() != nil {
      #if DEBUG
      Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
      #else
      Auth.auth().setAPNSToken(deviceToken, type: .prod)
      #endif
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Phone-auth reCAPTCHA / silent-APNs callbacks must be handed to FirebaseAuth
  // or the verifyPhoneNumber flow can fail / bounce the Flutter navigator when
  // returning from the captcha sheet.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }
}
