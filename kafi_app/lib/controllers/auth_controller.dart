import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/constants/auth_constants.dart';
import 'package:kafi_app/utils/constants/mock_constants.dart';
import 'package:kafi_app/utils/validators.dart';

class AuthController extends GetxController {
  final IAuthService _authService = Get.find<IAuthService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isReturning = false.obs;
  final RxString countryCode = AuthConstants.defaultCountryCode.obs;
  final RxString otpCode = ''.obs;
  final RxDouble passwordStrength = 0.0.obs;
  final RxInt otpSecondsLeft = AuthConstants.otpExpirySeconds.obs;

  /// Inline field errors (already localized). Empty string = no error.
  final RxString phoneError = ''.obs;
  final RxString otpError = ''.obs;

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Timer? _otpTimer;
  UserType _pendingRole = UserType.nanny;

  String get formattedPhone =>
      '${countryCode.value} ${phoneController.text.trim()}';

  String get otpTimerLabel {
    final m = otpSecondsLeft.value ~/ 60;
    final s = otpSecondsLeft.value % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get hasMinLength =>
      newPasswordController.text.length >= AuthConstants.minPasswordLength;
  bool get hasNumber => RegExp(r'\d').hasMatch(newPasswordController.text);
  bool get hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(newPasswordController.text);
  bool get hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPasswordController.text);
  bool get passwordsMatch =>
      newPasswordController.text.isNotEmpty &&
      newPasswordController.text == confirmPasswordController.text;
  bool get canSavePassword => hasMinLength && passwordsMatch;

  String get passwordStrengthLabel {
    if (passwordStrength.value >= 0.8) return AppStrings.pwStrong.tr;
    if (passwordStrength.value >= 0.5) return AppStrings.pwGood.tr;
    return AppStrings.pwWeak.tr;
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> _restoreSession() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      currentUser.value = user;
      // A user who verified OTP but abandoned the create-password step is
      // resumed straight back to it — Spec §6.1/§6.2 require a password before
      // the profile can be used.
      if (!user.hasPassword) {
        Get.offAllNamed(Routes.createPassword);
      } else {
        await _navigateHome(user);
      }
    }
  }

  void prepareNannyLogin() {
    isReturning.value = false;
    phoneError.value = '';
    otpError.value = '';
    _pendingRole = UserType.nanny;
    countryCode.value = AuthConstants.defaultCountryCode;
    _authService.setUserRole(UserType.nanny);
  }

  void prepareFamilyLogin() {
    isReturning.value = false;
    phoneError.value = '';
    otpError.value = '';
    _pendingRole = UserType.family;
    countryCode.value = AuthConstants.defaultCountryCode;
    _authService.setUserRole(UserType.family);
  }

  Future<void> sendOtpAndNavigate() async {
    final phoneErr = Validators.phone(phoneController.text);
    if (phoneErr != null) {
      phoneError.value = phoneErr.tr;
      return;
    }
    phoneError.value = '';
    final phone = phoneController.text.replaceAll(RegExp(r'\s+'), '');
    isLoading.value = true;
    bool sent = false;
    try {
      await _authService.sendOtp(phone, countryCode.value);
      _startOtpTimer();
      sent = true;
      Get.snackbar(
        AppStrings.authOtpSentTitle.tr,
        AppConfig.useMock
            ? AppStrings.authOtpSentBody.trParams({'otp': MockConstants.otp})
            : AppStrings.authCodeSent.trParams({'phone': formattedPhone}),
      );
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, _authErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
    if (sent) await Get.toNamed(Routes.otpVerify);
  }

  /// Re-issue OTP from the verify screen. Disabled until timer expires.
  bool get canResendOtp => otpSecondsLeft.value <= 0;

  Future<void> resendOtp() async {
    if (!canResendOtp) return;
    final phone = phoneController.text.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return;
    isLoading.value = true;
    try {
      await _authService.sendOtp(phone, countryCode.value);
      _startOtpTimer();
      otpCode.value = '';
      otpError.value = '';
      Get.snackbar(
        AppStrings.authOtpSentTitle.tr,
        AppConfig.useMock
            ? AppStrings.authOtpSentBody.trParams({'otp': MockConstants.otp})
            : AppStrings.authCodeSent.trParams({'phone': formattedPhone}),
      );
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, _authErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtpAndNavigate() async {
    if (otpCode.value.length < AuthConstants.otpLength) {
      otpError.value = AppStrings.authOtpIncorrect.tr;
      return;
    }
    if (otpSecondsLeft.value <= 0) {
      otpError.value = AppStrings.otpExpiredMessage.tr;
      return;
    }
    isLoading.value = true;
    try {
      await _authService.verifyOtp(otpCode.value);
    } catch (e) {
      otpError.value = _authErrorMessage(e);
      isLoading.value = false;
      return;
    }
    _otpTimer?.cancel();
    otpError.value = '';
    // Persist phone + role and create the profile skeleton immediately. This is
    // an idempotent merge that never resets an existing profile, so even if the
    // user abandons the create-password step their role is already recorded and
    // a resumed session continues correctly.
    try {
      await _authService.finalizePhoneRegistration();
      final user = await _authService.getCurrentUser();
      if (user == null) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authSessionLost.tr);
        return;
      }
      currentUser.value = user;
      if (user.hasPassword) {
        // Returning user who verified via OTP — straight to home/onboarding.
        await _navigateHome(user, isNewFamilyRegistration: false);
      } else {
        // New user — must set a password before continuing (Spec §6.1/§6.2).
        await Get.toNamed(Routes.createPassword);
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, _authErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithPassword() async {
    final phone = phoneController.text.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authMissingFields.tr);
      return;
    }
    isLoading.value = true;
    try {
      final user = await _authService.loginWithPassword(
        '${countryCode.value}$phone',
        passwordController.text,
      );
      if (user == null) return;
      currentUser.value = user;
      await _navigateHome(user, isNewFamilyRegistration: false);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, _authErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> savePasswordAndNavigate() async {
    if (!canSavePassword) return;
    isLoading.value = true;
    try {
      await _authService.createPassword(newPasswordController.text);
      final user = await _authService.getCurrentUser();
      if (user == null) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authSessionLost.tr);
        return;
      }
      currentUser.value = user;
      await _navigateHome(
        user,
        isNewFamilyRegistration: _pendingRole == UserType.family,
      );
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, _authErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  void updatePasswordStrength() {
    var score = 0.0;
    if (hasMinLength) score += 0.25;
    if (hasNumber) score += 0.25;
    if (hasUppercase) score += 0.25;
    if (hasSpecial) score += 0.15;
    if (passwordsMatch) score += 0.1;
    passwordStrength.value = score.clamp(0.0, 1.0);
  }

  /// Maps auth exceptions (Firebase live + mock service) to a localized,
  /// user-facing message per System Spec §14.1.
  String _authErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return AppStrings.authPhoneInvalid.tr;
        case 'invalid-verification-code':
          return AppStrings.authOtpIncorrect.tr;
        case 'invalid-verification-id':
        case 'session-expired':
        case 'code-expired':
          return AppStrings.otpExpiredMessage.tr;
        case 'too-many-requests':
          return AppStrings.authOtpRateLimited.tr;
        case 'quota-exceeded':
          return AppStrings.authQuotaExceeded.tr;
        case 'user-not-found':
          return AppStrings.authNoAccount.tr;
        case 'email-already-in-use':
        case 'account-exists-with-different-credential':
          return AppStrings.authAccountExists.tr;
        case 'wrong-password':
        case 'invalid-credential':
          return AppStrings.authWrongPassword.tr;
        case 'network-request-failed':
          return AppStrings.noInternet.tr;
        case 'requires-recent-login':
          return AppStrings.authReauthRequired.tr;
        default:
          return e.message ?? AppStrings.authOtpSendFailed.tr;
      }
    }
    // Mock service throws Exception('invalid_otp' | 'verification_failed' | …).
    final s = e.toString();
    if (s.contains('invalid_otp')) return AppStrings.authOtpIncorrect.tr;
    if (s.contains('no_verification_id') ||
        s.contains('verification_failed')) {
      return AppStrings.authOtpSendFailed.tr;
    }
    if (s.contains('password_too_weak')) return AppStrings.pwWeak.tr;
    return AppStrings.authOtpSendFailed.tr;
  }

  void _startOtpTimer() {
    otpSecondsLeft.value = AuthConstants.otpExpirySeconds;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (otpSecondsLeft.value <= 0) {
        t.cancel();
      } else {
        otpSecondsLeft.value--;
      }
    });
  }

  Future<void> _navigateHome(UserModel user, {bool isNewFamilyRegistration = false}) async {
    // Admin block enforcement — sign the user out if their doc is blocked.
    if (await Get.find<IUserService>().isUserBlocked(user.id, isNanny: user.isNanny)) {
      await signOut();
      Get.offAllNamed(Routes.welcome);
      Get.snackbar(AppStrings.accountBlocked.tr, AppStrings.accountBlockedSub.tr);
      return;
    }
    if (user.isNanny) {
      final nanny = await Get.find<IUserService>().getNanny(user.id);
      if (nanny?.status == NannyOnboardingStatus.approved) {
        Get.offAllNamed(Routes.nannyHome);
      } else if (nanny?.status == NannyOnboardingStatus.pending) {
        Get.offAllNamed(Routes.nannyPending);
      } else {
        Get.offAllNamed(Routes.nannyInfo);
      }
    } else if (isNewFamilyRegistration) {
      Get.offAllNamed(Routes.familyForm);
    } else {
      Get.offAllNamed(Routes.browse);
    }
  }

  Future<void> signOut() async {
    final uid = currentUser.value?.id;
    if (uid != null && Get.isRegistered<INotificationService>()) {
      final token = await Get.find<INotificationService>().getToken();
      if (token != null) {
        await Get.find<INotificationService>().removeToken(uid, token);
      }
    }
    await _authService.logout();
    currentUser.value = null;
    isReturning.value = false;
    _otpTimer?.cancel();
  }

  Future<void> deleteAccount(String reason) async {
    await _authService.deleteAccount(reason);
    currentUser.value = null;
    _otpTimer?.cancel();
    phoneController.clear();
    passwordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    // The delete-account screen navigates to /welcome via `offAllNamed`, so
    // ephemeral controllers get torn down with their bindings. Permanent
    // controllers (`NotificationController`, `SubscriptionController`,
    // `ChatController`) clear their own caches via `ever(currentUser)`.
  }
}
