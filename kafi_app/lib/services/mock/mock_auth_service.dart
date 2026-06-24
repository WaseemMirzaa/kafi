import 'dart:async';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/utils/constants/mock_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Preserve existing hasPassword for returning users.
    final existing = prefs.getString(_keyUser);
    bool keepHasPassword = false;
    if (existing != null) {
      final parts = existing.split('|');
      if (parts.length >= 4) keepHasPassword = parts[3] == '1';
    }

    _memoryUser = UserModel(
      id: 'mock_${role.name}_1',
      phone: phone,
      type: role,
      hasPassword: keepHasPassword,
    );
    await prefs.setString(
      _keyUser,
      '${_memoryUser!.id}|$phone|${role.index}|${keepHasPassword ? 1 : 0}',
    );
  }

  @override
  Future<void> createPassword(String password) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final prefs = await SharedPreferences.getInstance();
    final phone = _pendingPhone ?? prefs.getString(_keyPendingPhone) ?? '+971502345678';
    final roleIndex = prefs.getInt(_keyPendingRole) ?? _pendingRole?.index ?? 0;
    final role = UserType.values[roleIndex];
    _memoryUser = UserModel(
      id: 'mock_${role.name}_1',
      phone: phone,
      type: role,
      hasPassword: true,
    );
    await prefs.setString(_keyUser, '${_memoryUser!.id}|$phone|${role.index}|1');
  }

  @override
  Future<UserModel?> loginWithPassword(String phone, String password) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final role = _pendingRole ?? UserType.nanny;
    _memoryUser = UserModel(
      id: 'mock_${role.name}_1',
      phone: phone,
      type: role,
      hasPassword: true,
      fullName: role == UserType.nanny ? 'Maria Santos' : 'Al Rashid Family',
    );
    // Persist so a password-login session survives an app restart (matches the
    // OTP-signup path which also writes to SharedPreferences).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, '${_memoryUser!.id}|$phone|${role.index}|1');
    return _memoryUser;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_memoryUser != null) return _memoryUser;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length < 4) return null;
    _memoryUser = UserModel(
      id: parts[0],
      phone: parts[1],
      type: UserType.values[int.parse(parts[2])],
      hasPassword: parts[3] == '1',
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

  @override
  Future<void> sendPasswordResetOtp(String phone, String countryCode) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    // In mock mode we don't need to remember the phone — verifyPasswordResetOtp
    // and resetPassword only check the OTP code matches MockConstants.otp.
    // ignore: unused_local_variable
    final _ = '$countryCode$phone'.replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Future<void> verifyPasswordResetOtp(String otp) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    if (otp != MockConstants.otp) {
      throw Exception('invalid_otp');
    }
  }

  @override
  Future<void> resetPassword(String otp, String newPassword) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    if (otp != MockConstants.otp) {
      throw Exception('invalid_otp');
    }
    if (newPassword.length < 8) {
      throw Exception('password_too_weak');
    }
  }
}
