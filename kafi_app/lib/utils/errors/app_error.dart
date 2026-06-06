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
      : super(code: 'perm/denied', message: 'Permission denied');
}

class RateLimitError extends AppError {
  RateLimitError()
      : super(code: 'rate/limit', message: 'Too many requests. Try later.');
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
        message: 'Please enter a valid phone number',
      );

  factory AuthError.otpExpired() => AuthError(
        code: 'auth/otp-expired',
        message: 'Code expired. Tap resend.',
      );

  factory AuthError.otpIncorrect(int remaining) => AuthError(
        code: 'auth/otp-incorrect',
        message: 'Invalid code. $remaining attempts remaining.',
      );

  factory AuthError.rateLimited() => AuthError(
        code: 'auth/rate-limited',
        message: 'Too many attempts. Try again later.',
      );

  factory AuthError.accountSuspended() => AuthError(
        code: 'auth/suspended',
        message: 'Account suspended. Contact support.',
      );

  factory AuthError.sessionExpired() => AuthError(
        code: 'auth/session-expired',
        message: 'Session expired. Please sign in again.',
      );

  factory AuthError.accountDeleted() => AuthError(
        code: 'auth/deleted',
        message: 'Account has been deleted.',
      );

  factory AuthError.weakPassword() => AuthError(
        code: 'auth/weak-password',
        message: 'Password too weak. Use 8+ characters.',
      );

  factory AuthError.wrongPassword() => AuthError(
        code: 'auth/wrong-password',
        message: 'Incorrect password.',
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
        message: 'Permission denied',
      );

  factory PermissionError.permanentlyDenied(Permission perm) => PermissionError(
        permission: perm,
        isPermanent: true,
        code: 'perm/permanent',
        message: 'Permission permanently denied. Enable in settings.',
      );
}

/// Upload errors per §13.1
class UploadError extends AppError {
  UploadError._({required super.code, required super.message});

  factory UploadError.fileTooLarge(int maxMB) => UploadError._(
        code: 'upload/too-large',
        message: 'File too large. Max ${maxMB}MB.',
      );

  factory UploadError.invalidFormat() => UploadError._(
        code: 'upload/invalid-format',
        message: 'File type not supported',
      );

  factory UploadError.videoTooLong() => UploadError._(
        code: 'upload/video-too-long',
        message: 'Video must be 60 seconds or less',
      );

  factory UploadError.networkFailure() => UploadError._(
        code: 'upload/network',
        message: 'Upload failed. Tap to retry.',
      );

  factory UploadError.quota() => UploadError._(
        code: 'upload/quota',
        message: 'Upload failed. Contact support.',
      );
}

/// Trial errors per §13.1
class TrialError extends AppError {
  TrialError._({required super.code, required super.message});

  factory TrialError.notSubscribed() => TrialError._(
        code: 'trial/not-subscribed',
        message: 'Subscribe to send trial offers',
      );

  factory TrialError.nannyOnAnotherTrial() => TrialError._(
        code: 'trial/nanny-busy',
        message: 'Nanny is currently on another trial',
      );

  factory TrialError.startDatePassed() => TrialError._(
        code: 'trial/start-passed',
        message: 'Start date has passed',
      );

  factory TrialError.alreadyOffered() => TrialError._(
        code: 'trial/already-offered',
        message: 'You already sent a trial offer to this nanny',
      );

  factory TrialError.expired() => TrialError._(
        code: 'trial/expired',
        message: 'Trial offer has expired',
      );
}

/// Subscription errors per §13.1
class SubscriptionError extends AppError {
  SubscriptionError._({required super.code, required super.message});

  factory SubscriptionError.paymentDeclined() => SubscriptionError._(
        code: 'sub/declined',
        message: 'Payment failed. Try another method.',
      );

  factory SubscriptionError.contactsExhausted() => SubscriptionError._(
        code: 'sub/contacts-exhausted',
        message: 'All 5 free views used. Subscribe to continue.',
      );

  factory SubscriptionError.restoreFailed() => SubscriptionError._(
        code: 'sub/restore-failed',
        message: "Couldn't restore. Try again.",
      );

  factory SubscriptionError.expired() => SubscriptionError._(
        code: 'sub/expired',
        message: 'Your subscription has expired.',
      );

  factory SubscriptionError.featureLocked() => SubscriptionError._(
        code: 'sub/feature-locked',
        message: 'Subscribe to access this feature.',
      );
}

/// Network errors per §13.1
class NetworkError extends AppError {
  NetworkError._({required super.code, required super.message});

  factory NetworkError.noConnection() => NetworkError._(
        code: 'net/no-connection',
        message: 'No internet. Check your connection.',
      );

  factory NetworkError.timeout() => NetworkError._(
        code: 'net/timeout',
        message: 'Action took too long. Retry.',
      );

  factory NetworkError.serverDown() => NetworkError._(
        code: 'net/server-down',
        message: "We're experiencing issues. Try again.",
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
        message: '$field is required',
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
        message: '$field must be $min-$max characters',
      );
}
