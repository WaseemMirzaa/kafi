/// App environment — toggle [useMock] per Technical Architecture §5.1
///
/// [useMock] is `true` for offline/mock local runs (no Firebase config required).
/// Set to `false` only when platform Firebase config files are present:
///   • android/app/google-services.json
///   • ios/Runner/GoogleService-Info.plist
/// See kafi_app/FIREBASE_SETUP.md.
class AppConfig {
  static const bool useMock = true;
  static const String environment = 'prod';
  static const bool enableLogs = true;

  /// Mock-only OTP (6 digits to mirror a live Firebase SMS code length).
  static const String mockOtp = '123456';
  static const Duration mockDelay = Duration(milliseconds: 500);
}
