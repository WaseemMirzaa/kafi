/// App environment — toggle [useMock] per Technical Architecture §5.1
class AppConfig {
  static const bool useMock = false;
  static const String environment = 'dev';
  static const bool enableLogs = true;
  static const String mockOtp = '1234';
  static const Duration mockDelay = Duration(milliseconds: 500);
}
