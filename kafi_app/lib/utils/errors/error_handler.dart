import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/errors/app_error.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';

/// Central error handler per Technical Architecture §13.2
class ErrorHandler {
  static void handle(dynamic error, {StackTrace? stack, String? context}) {
    final appError = _mapToAppError(error);

    _logError(appError, stack, context);
    _showUserError(appError);
  }

  static AppError _mapToAppError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is fb.FirebaseAuthException) {
      return _mapFirebaseAuthError(error);
    }

    if (error is FirebaseException) {
      return _mapFirebaseError(error);
    }

    if (error is SocketException || error is TimeoutException) {
      return NetworkError.noConnection();
    }

    return UnknownError(
      code: 'unknown',
      message: AppStrings.errUnknownSomethingWrong.tr,
      originalError: error,
    );
  }

  static AppError _mapFirebaseAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return AuthError.invalidPhone();
      case 'too-many-requests':
        return AuthError.rateLimited();
      case 'session-expired':
        return AuthError.otpExpired();
      case 'invalid-verification-code':
        return AuthError.otpIncorrect(0);
      case 'user-disabled':
        return AuthError.accountSuspended();
      case 'network-request-failed':
        return NetworkError.noConnection();
      case 'wrong-password':
        return AuthError.wrongPassword();
      case 'weak-password':
        return AuthError.weakPassword();
      case 'keychain-error':
        return AuthError.keychain();
      default:
        if ((e.message ?? '').toLowerCase().contains('keychain')) {
          return AuthError.keychain();
        }
        return UnknownError(code: e.code, message: AppStrings.errUnknownAuthError.tr);
    }
  }

  static AppError _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return PermissionDeniedError();
      case 'unavailable':
        return NetworkError.serverDown();
      case 'deadline-exceeded':
        return NetworkError.timeout();
      case 'resource-exhausted':
        return RateLimitError();
      default:
        return UnknownError(code: e.code, message: AppStrings.errUnknownServiceError.tr);
    }
  }

  static void _logError(AppError error, StackTrace? stack, String? context) {
    if (AppConfig.enableLogs) {
      // ignore: avoid_print
      print('[$context] ${error.code}: ${error.technical ?? error.message}');
      if (stack != null) {
        // ignore: avoid_print
        print(stack.toString().split('\n').take(5).join('\n'));
      }
    }

    // In production, log to Crashlytics
    // if (!AppConfig.useMock) {
    //   FirebaseCrashlytics.instance.recordError(
    //     error.originalError ?? error,
    //     stack,
    //     reason: context,
    //     fatal: false,
    //   );
    // }
  }

  static void _showUserError(AppError error) {
    Get.snackbar(
      AppStrings.errorTitle.tr,
      error.message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: KafiColors.redL,
      colorText: KafiColors.redD,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );
  }

  /// Wrap an async action with error handling
  static Future<T?> wrap<T>(
    Future<T> Function() action, {
    String? context,
    bool showError = true,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      if (showError) {
        handle(e, stack: stack, context: context);
      } else {
        _logError(_mapToAppError(e), stack, context);
      }
      return null;
    }
  }

  /// Show paywall for subscription-locked features
  static void showPaywall(String feature, {String? reason}) {
    Get.snackbar(
      AppStrings.subscriptionRequired.tr,
      reason == 'subscription_expired'
          ? AppStrings.subscriptionExpiredMessage.tr
          : AppStrings.subscribeToAccess.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: KafiColors.ambL,
      colorText: KafiColors.ambD,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () => Get.toNamed(Routes.pricing),
        child: Text(
          AppStrings.viewPlans.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Show offline banner
  static void showOfflineBanner() {
    Get.snackbar(
      AppStrings.noInternet.tr,
      AppStrings.checkConnection.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: KafiColors.grey,
      colorText: Colors.white,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      isDismissible: false,
    );
  }

  /// Dismiss offline banner
  static void hideOfflineBanner() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }
}
