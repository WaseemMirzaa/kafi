import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// RevenueCat public SDK keys and config (Technical Architecture § subscriptions).
///
/// Pass real keys at build/run time:
/// ```
/// flutter run \
///   --dart-define=REVENUECAT_IOS_API_KEY=appl_xxx \
///   --dart-define=REVENUECAT_ANDROID_API_KEY=goog_xxx
/// ```
/// Leave empty until keys are available; keep [AppConfig.useMockSubscription]
/// true so Pricing still works via the mock path.
class RevenueCatConstants {
  static const iosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );

  static const androidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  /// Public SDK key for the current platform (empty = not configured).
  static String get apiKey {
    if (kIsWeb) return '';
    if (Platform.isIOS) return iosApiKey;
    if (Platform.isAndroid) return androidApiKey;
    return '';
  }

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
