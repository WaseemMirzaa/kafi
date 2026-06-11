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
    apiKey: 'AIzaSyDDR_NQKd1myC0rL_ULyQsLs6m2MKngen8',
    appId: '1:944877885594:android:4b3730e255af20e4c52723',
    messagingSenderId: '944877885594',
    projectId: 'yhgc-testing',
    storageBucket: 'yhgc-testing.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIK6A5CWHgngZq_joGf7HkdE2xQ_TQC4Q',
    appId: '1:944877885594:ios:07488188f47c98bac52723',
    messagingSenderId: '944877885594',
    projectId: 'yhgc-testing',
    storageBucket: 'yhgc-testing.firebasestorage.app',
    iosBundleId: 'com.kafi.kafiApp',
  );
  static const FirebaseOptions macos = ios;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'mock-api-key',
    appId: '1:000000000000:web:mock',
    messagingSenderId: '000000000000',
    projectId: 'kafi-mock',
  );
}
