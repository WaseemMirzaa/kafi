import 'package:kafi_app/config/app_config.dart';

/// Mock-mode values (see AppConfig.useMock).
class MockConstants {
  static String get otp => AppConfig.mockOtp;

  /// Auto-approve nanny profile after submit (demo flow).
  static const Duration nannyAutoApproveDelay = Duration(seconds: 30);
}
