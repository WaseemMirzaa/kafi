import 'dart:async';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/utils/constants/mock_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline phone-only auth used when [AppConfig.useMock] is true. Mirrors the
/// Firebase phone-OTP flow (no passwords) using SharedPreferences.
class MockAuthService implements IAuthService {
  static const _keyUser = 'mock_current_user';
  static const _keyPendingPhone = 'mock_pending_phone';
  static const _keyPendingRole = 'mock_pending_role';

  UserModel? _memoryUser;
  String? _pendingPhone;
  UserType? _pendingRole;

  @override
  Future<void> sendOtp(String phone, String countryCode) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _pendingPhone = '$countryCode$phone'.replaceAll(RegExp(r'\s+'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingPhone, _pendingPhone!);
  }

  @override
  Future<void> verifyOtp(String code) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    if (code != MockConstants.otp) {
      throw Exception('invalid_otp');
    }
  }

  @override
  Future<void> finalizePhoneRegistration() async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final phone = _pendingPhone ?? prefs.getString(_keyPendingPhone) ?? '+971502345678';
    final roleIndex = prefs.getInt(_keyPendingRole) ?? _pendingRole?.index ?? 0;
    final role = UserType.values[roleIndex];

    _memoryUser = UserModel(
      id: 'mock_${role.name}_1',
      phone: phone,
      type: role,
    );
    await prefs.setString(_keyUser, '${_memoryUser!.id}|$phone|${role.index}');
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_memoryUser != null) return _memoryUser;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    _memoryUser = UserModel(
      id: parts[0],
      phone: parts[1],
      type: UserType.values[int.parse(parts[2])],
    );
    return _memoryUser;
  }

  @override
  Future<void> setUserRole(UserType type) async {
    _pendingRole = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPendingRole, type.index);
  }

  @override
  Future<void> logout() async {
    _memoryUser = null;
    _pendingPhone = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  @override
  Future<void> deleteAccount(String reason) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _memoryUser = null;
    _pendingPhone = null;
    _pendingRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyPendingPhone);
    await prefs.remove(_keyPendingRole);
  }
}
