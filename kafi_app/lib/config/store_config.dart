import 'dart:io' show Platform;

/// Store identifiers and listing URLs used by the "rate the app" prompt.
///
/// The Android package id is final. The iOS App Store numeric id is only known
/// once the app is published, so [appleAppId] starts empty — set it before the
/// iOS release. Until then [storeListingUrl] returns an empty string on iOS and
/// the rate prompt degrades gracefully (it thanks the user without opening a
/// broken link).
abstract class StoreConfig {
  StoreConfig._();

  /// Android applicationId — see `android/app/build.gradle.kts`.
  static const String androidPackage = 'com.kafi.kafi_app';

  /// Apple App Store numeric id (e.g. `'1234567890'`). Empty until published.
  static const String appleAppId = '';

  static const String _playUrl =
      'https://play.google.com/store/apps/details?id=$androidPackage';

  static String get _appStoreUrl =>
      appleAppId.isEmpty ? '' : 'https://apps.apple.com/app/id$appleAppId';

  /// The store-listing URL for the current platform, or `''` when unavailable
  /// (iOS before [appleAppId] is set, or a non-mobile platform).
  static String get storeListingUrl {
    if (Platform.isAndroid) return _playUrl;
    if (Platform.isIOS) return _appStoreUrl;
    return '';
  }
}
