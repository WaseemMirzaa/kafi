import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session monitor per Technical Architecture §13.8
///
/// Responsibilities:
/// 1. Detect Firebase auth-state changes and force re-auth on null user.
/// 2. Track `lastActivityAt` (refreshed on `touch()`) and auto-logout
///    after [_maxInactiveDays] of inactivity (default 90 days per spec §21).
class SessionMonitor extends GetxService {
  StreamSubscription<User?>? _authSub;
  Timer? _inactivityTimer;
  static const _maxInactiveDays = 90;
  static const _kLastActivity = 'kafi.session.lastActivityAt';

  @override
  void onInit() {
    super.onInit();
    if (!AppConfig.useMock) {
      _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    }
    touch();
    _inactivityTimer = Timer.periodic(const Duration(minutes: 30), (_) => _enforceInactivity());
  }

  /// Call on user activity (route changes, taps, controller events).
  Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _enforceInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastActivity);
    if (last == null) {
      await touch();
      return;
    }
    final ageDays = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)).inDays;
    if (ageDays >= _maxInactiveDays) {
      if (!AppConfig.useMock) {
        await FirebaseAuth.instance.signOut();
      }
      _handleSessionExpired();
    }
  }

  void _onAuthStateChanged(User? user) {
    if (user == null && Get.currentRoute != Routes.welcome) {
      _handleSessionExpired();
    } else if (user != null) {
      touch();
    }
  }

  void _handleSessionExpired() {
    // Clear local auth state so the app doesn't think a user is logged in
    // while Firebase has already signed them out (token revoked, etc).
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().currentUser.value = null;
    }
    Get.snackbar(
      AppStrings.sessionExpired.tr,
      AppStrings.pleaseSignInAgain.tr,
      snackPosition: SnackPosition.TOP,
      backgroundColor: KafiColors.ambL,
      colorText: KafiColors.ambD,
      duration: const Duration(seconds: 4),
    );
    Get.offAllNamed(Routes.welcome);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _inactivityTimer?.cancel();
    super.onClose();
  }
}
