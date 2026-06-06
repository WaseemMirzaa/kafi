// Placeholder Firebase options — replace via `flutterfire configure` for production.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: '1:000000000000:android:mock',
    messagingSenderId: '000000000000',
    projectId: 'kafi-mock',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: '1:000000000000:ios:mock',
    messagingSenderId: '000000000000',
    projectId: 'kafi-mock',
    iosBundleId: 'ae.kafi.app',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: '1:000000000000:web:mock',
    messagingSenderId: '000000000000',
    projectId: 'kafi-mock',
  );
}
