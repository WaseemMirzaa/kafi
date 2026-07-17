import 'package:kafi_app/models/user_model.dart';

/// Phone-only authentication (Firebase default phone/OTP auth).
///
/// There are no passwords: a verified phone number IS the credential, both for
/// first-time registration and for returning sign-ins. See System Spec §6.
abstract class IAuthService {
  Future<void> sendOtp(String phone, String countryCode);
  Future<void> verifyOtp(String code);

  /// Completes registration after a successful phone OTP: persists the phone +
  /// role and creates the role-specific profile skeleton. Idempotent, so a
  /// returning user signing in via OTP never resets an existing profile.
  Future<void> finalizePhoneRegistration();

  Future<UserModel?> getCurrentUser();
  Future<void> setUserRole(UserType type);
  Future<void> logout();
  Future<void> deleteAccount(String reason);
}
