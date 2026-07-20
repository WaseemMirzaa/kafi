// Live Firebase options for project yhgc-testing (Kafi).
// Native configs: ios/Runner/GoogleService-Info.plist, android/app/google-services.json
// (gitignored). Regenerate with `flutterfire configure` if the project changes.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    appId: '1:944877885594:ios:87503ec30e8d8fb8c52723',
    messagingSenderId: '944877885594',
    projectId: 'yhgc-testing',
    storageBucket: 'yhgc-testing.firebasestorage.app',
    iosBundleId: 'com.codetivelab.kafiApp',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB40D-2gDlAXn0LkppxqyJ8dYt213g9Nn8',
    appId: '1:944877885594:web:ab0043548cbc808dc52723',
    messagingSenderId: '944877885594',
    projectId: 'yhgc-testing',
    authDomain: 'yhgc-testing.firebaseapp.com',
    storageBucket: 'yhgc-testing.firebasestorage.app',
    measurementId: 'G-02FWJYB01L',
  );
}
