/// App environment — toggle [useMock] per Technical Architecture §5.1
///
/// [useMock] is `false` so the app runs against live Firebase (Auth + Firestore +
/// Storage + FCM). This requires the platform Firebase config files to be present:
///   • android/app/google-services.json
///   • ios/Runner/GoogleService-Info.plist
/// See kafi_app/FIREBASE_SETUP.md. Flip back to `true` for offline/mock dev.
class AppConfig {
  static const bool useMock = false;
  static const String environment = 'prod';
  static const bool enableLogs = true;

  /// Mock-only OTP (6 digits to mirror a live Firebase SMS code length).
  static const String mockOtp = '123456';
  static const Duration mockDelay = Duration(milliseconds: 500);
}
