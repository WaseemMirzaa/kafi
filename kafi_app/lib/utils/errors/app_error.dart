import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';

/// Base error class per Technical Architecture §13.1
abstract class AppError implements Exception {
  final String code;
  final String message;
  final String? technical;
  final dynamic originalError;

  AppError({
    required this.code,
    required this.message,
    this.technical,
    this.originalError,
  });

  @override
  String toString() => '[$code] $message';
}

class UnknownError extends AppError {
  UnknownError({
    required super.code,
    required super.message,
    super.originalError,
  });
}

class PermissionDeniedError extends AppError {
  PermissionDeniedError()
      : super(code: 'perm/denied', message: AppStrings.errPermissionDenied.tr);
}

class RateLimitError extends AppError {
  RateLimitError()
      : super(code: 'rate/limit', message: AppStrings.errRateLimitMessage.tr);
}

/// Auth errors per §13.1
class AuthError extends AppError {
  AuthError({
    required super.code,
    required super.message,
    super.technical,
    super.originalError,
  });

  factory AuthError.invalidPhone() => AuthError(
        code: 'auth/invalid-phone',
        message: AppStrings.authPhoneInvalid.tr,
      );

  factory AuthError.otpExpired() => AuthError(
        code: 'auth/otp-expired',
        message: AppStrings.otpExpiredMessage.tr,
      );

  factory AuthError.otpIncorrect(int remaining) => AuthError(
        code: 'auth/otp-incorrect',
        message: AppStrings.errAuthOtpIncorrectAttempts
            .trParams({'remaining': '$remaining'}),
      );

  factory AuthError.rateLimited() => AuthError(
        code: 'auth/rate-limited',
        message: AppStrings.authOtpRateLimited.tr,
      );

  factory AuthError.accountSuspended() => AuthError(
        code: 'auth/suspended',
        message: AppStrings.errAuthAccountSuspended.tr,
      );

  factory AuthError.sessionExpired() => AuthError(
        code: 'auth/session-expired',
        message: AppStrings.errAuthSessionExpiredMessage.tr,
      );

  factory AuthError.accountDeleted() => AuthError(
        code: 'auth/deleted',
        message: AppStrings.accountDeletedMessage.tr,
      );

  factory AuthError.weakPassword() => AuthError(
        code: 'auth/weak-password',
        message: AppStrings.errAuthWeakPasswordMessage.tr,
      );

  factory AuthError.wrongPassword() => AuthError(
        code: 'auth/wrong-password',
        message: AppStrings.authWrongPassword.tr,
      );

  factory AuthError.keychain() => AuthError(
        code: 'auth/keychain-error',
        message: AppStrings.authKeychainError.tr,
      );
}

/// Permission errors per §13.1
class PermissionError extends AppError {
  final Permission permission;
  final bool isPermanent;

  PermissionError({
    required this.permission,
    required this.isPermanent,
    required super.code,
    required super.message,
  });

  factory PermissionError.denied(Permission perm) => PermissionError(
        permission: perm,
        isPermanent: false,
        code: 'perm/denied',
        message: AppStrings.errPermissionDenied.tr,
      );

  factory PermissionError.permanentlyDenied(Permission perm) => PermissionError(
        permission: perm,
        isPermanent: true,
        code: 'perm/permanent',
        message: AppStrings.permissionPermanentlyDeniedBody.tr,
      );
}

/// Upload errors per §13.1
class UploadError extends AppError {
  UploadError._({required super.code, required super.message});

  factory UploadError.fileTooLarge(int maxMB) => UploadError._(
        code: 'upload/too-large',
        message: AppStrings.errUploadFileTooLarge
            .trParams({'maxMB': '$maxMB'}),
      );

  factory UploadError.invalidFormat() => UploadError._(
        code: 'upload/invalid-format',
        message: AppStrings.errUploadInvalidFormat.tr,
      );

  factory UploadError.videoTooLong() => UploadError._(
        code: 'upload/video-too-long',
        message: AppStrings.nannyVideoTooLong.tr,
      );

  factory UploadError.networkFailure() => UploadError._(
        code: 'upload/network',
        message: AppStrings.errUploadNetworkFailure.tr,
      );

  factory UploadError.quota() => UploadError._(
        code: 'upload/quota',
        message: AppStrings.errUploadQuotaExceeded.tr,
      );
}

/// Trial errors per §13.1
class TrialError extends AppError {
  TrialError._({required super.code, required super.message});

  factory TrialError.notSubscribed() => TrialError._(
        code: 'trial/not-subscribed',
        message: AppStrings.trialOfferSubRequired.tr,
      );

  factory TrialError.nannyOnAnotherTrial() => TrialError._(
        code: 'trial/nanny-busy',
        message: AppStrings.trialOfferNannyOnTrial.tr,
      );

  factory TrialError.startDatePassed() => TrialError._(
        code: 'trial/start-passed',
        message: AppStrings.trialOfferStartPast.tr,
      );

  factory TrialError.alreadyOffered() => TrialError._(
        code: 'trial/already-offered',
        message: AppStrings.trialAlreadyActive.tr,
      );

  factory TrialError.expired() => TrialError._(
        code: 'trial/expired',
        message: AppStrings.errTrialOfferExpiredMessage.tr,
      );
}

/// Subscription errors per §13.1
class SubscriptionError extends AppError {
  SubscriptionError._({required super.code, required super.message});

  factory SubscriptionError.paymentDeclined() => SubscriptionError._(
        code: 'sub/declined',
        message: AppStrings.errSubPaymentDeclined.tr,
      );

  factory SubscriptionError.contactsExhausted() => SubscriptionError._(
        code: 'sub/contacts-exhausted',
        message: AppStrings.noFreeViewsLeft.tr,
      );

  factory SubscriptionError.restoreFailed() => SubscriptionError._(
        code: 'sub/restore-failed',
        message: AppStrings.errSubRestoreFailed.tr,
      );

  factory SubscriptionError.expired() => SubscriptionError._(
        code: 'sub/expired',
        message: AppStrings.subscriptionExpiredMessage.tr,
      );

  factory SubscriptionError.featureLocked() => SubscriptionError._(
        code: 'sub/feature-locked',
        message: AppStrings.subscribeToAccess.tr,
      );
}

/// Network errors per §13.1
class NetworkError extends AppError {
  NetworkError._({required super.code, required super.message});

  factory NetworkError.noConnection() => NetworkError._(
        code: 'net/no-connection',
        message: AppStrings.errNetNoConnectionMessage.tr,
      );

  factory NetworkError.timeout() => NetworkError._(
        code: 'net/timeout',
        message: AppStrings.errNetTimeoutMessage.tr,
      );

  factory NetworkError.serverDown() => NetworkError._(
        code: 'net/server-down',
        message: AppStrings.errNetServerDownMessage.tr,
      );
}

/// Validation errors (field-level) per §13.1
class ValidationError extends AppError {
  final String field;

  ValidationError({
    required this.field,
    required super.code,
    required super.message,
  });

  factory ValidationError.required(String field) => ValidationError(
        field: field,
        code: 'validation/required',
        message: AppStrings.errValRequiredField.trParams({'field': field}),
      );

  factory ValidationError.invalid(String field, String hint) => ValidationError(
        field: field,
        code: 'validation/invalid',
        message: hint,
      );

  factory ValidationError.length(String field, int min, int max) =>
      ValidationError(
        field: field,
        code: 'validation/length',
        message: AppStrings.errValLengthField.trParams({
          'field': field,
          'min': '$min',
          'max': '$max',
        }),
      );
}
