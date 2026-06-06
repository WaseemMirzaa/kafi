import 'package:kafi_app/models/user_model.dart';

abstract class IAuthService {
  Future<void> sendOtp(String phone, String countryCode);
  Future<void> verifyOtp(String code);
  /// Completes signup after phone OTP (family: no password screen).
  Future<void> finalizePhoneRegistration();
  Future<void> createPassword(String password);
  Future<UserModel?> loginWithPassword(String phone, String password);
  Future<UserModel?> getCurrentUser();
  Future<void> setUserRole(UserType type);
  Future<void> logout();
  Future<void> deleteAccount(String reason);
  Future<void> sendPasswordResetOtp(String phone, String countryCode);
  Future<void> verifyPasswordResetOtp(String otp);
  Future<void> resetPassword(String otp, String newPassword);
}
