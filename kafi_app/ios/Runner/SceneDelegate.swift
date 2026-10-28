import Flutter
import UIKit
import FirebaseAuth

/// UIScene lifecycle host (Xcode 26+/27). Phone Auth reCAPTCHA redirect URLs
/// land here — forward to Firebase Auth regardless of App Delegate Proxy.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let url = userActivity.webpageURL, Auth.auth().canHandle(url) {
      return
    }
    super.scene(scene, continue: userActivity)
  }
}
