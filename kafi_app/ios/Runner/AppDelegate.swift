import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Cached until the Flutter engine / Auth is ready, then re-forwarded.
  private var apnsDeviceToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    GMSServices.provideAPIKey("AIzaSyDqQUR6ygHdXRDDUmJ7Xr02A2HCMH92Lvk")

    // App Delegate Proxy is OFF (Info.plist): APNs token, notifications and URLs
    // are forwarded to Firebase manually below.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let token = apnsDeviceToken {
      forwardAPNsTokenToFirebase(token)
    }
  }

  // MARK: - APNs token (Firebase Auth Phone + FCM)

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    apnsDeviceToken = deviceToken
    forwardAPNsTokenToFirebase(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  /// `.unknown` → Firebase detects sandbox vs production (debug installs use sandbox).
  private func forwardAPNsTokenToFirebase(_ deviceToken: Data) {
    guard FirebaseApp.app() != nil else { return }
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    Messaging.messaging().apnsToken = deviceToken
  }

  // MARK: - Remote notifications → FIRAuth.canHandleNotification

  /// FlutterAppDelegate answers `responds(to:)` for lifecycle selectors by asking
  /// registered plugins, so with UIScene + implicit engine it can say "no" even
  /// though this class implements the method. Firebase Auth only sends its
  /// forwarding probe (and logs I-AUT000015 / notification-not-forwarded) when
  /// the delegate responds — so answer for it explicitly.
  override func responds(to aSelector: Selector!) -> Bool {
    if aSelector == #selector(
      UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)
    ) {
      return true
    }
    return super.responds(to: aSelector)
  }

  /// Firebase Auth (swizzling off or on) verifies Phone Auth by delivering a
  /// synthetic notification here. Must call `canHandleNotification` or you get:
  /// "remote notifications … need to be forwarded to … canHandleNotification".
  @objc override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }

    Messaging.messaging().appDidReceiveMessage(userInfo)

    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler
    )
  }

  // MARK: - Foreground presentation (UIScene / UNUserNotificationCenter)

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler([])
      return
    }
    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler()
      return
    }
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  // MARK: - URL / reCAPTCHA (non-scene fallback; SceneDelegate handles UIScene)

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
}
