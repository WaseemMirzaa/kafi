// Live Firebase options for project kafi-802c9 (Kafi).
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
    apiKey: 'AIzaSyAkdIrZ7581WyPJUstYFioFDD_cOb9lWj0',
    appId: '1:1020989377749:android:d37018a3e4a23820b4265c',
    messagingSenderId: '1020989377749',
    projectId: 'kafi-802c9',
    storageBucket: 'kafi-802c9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmDORFINjCUt4vwqR6ekwPjEi2GNg3dh8',
    appId: '1:1020989377749:ios:c193b144f0609552b4265c',
    messagingSenderId: '1020989377749',
    projectId: 'kafi-802c9',
    storageBucket: 'kafi-802c9.firebasestorage.app',
    iosBundleId: 'com.codetivelab.kafiApp',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCkgTzsxMR2tHtnQ3eboTOzYgrOyvFISKU',
    appId: '1:1020989377749:web:6bfec89ad5bf6bfbb4265c',
    messagingSenderId: '1020989377749',
    projectId: 'kafi-802c9',
    authDomain: 'kafi-802c9.firebaseapp.com',
    storageBucket: 'kafi-802c9.firebasestorage.app',
  );
}
