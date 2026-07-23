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

  /// Set just before a deliberate, user-initiated sign-out (logout / account
  /// deletion). The resulting `authStateChanges(null)` is then an EXPECTED
  /// sign-out, not a dropped session — without this it fired the alarming
  /// "Session expired" snackbar and a second redirect on every normal logout.
  bool _intentionalSignOut = false;

  /// AuthController calls this before signing out / deleting the account.
  void beginIntentionalSignOut() {
    _intentionalSignOut = true;
  }

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

  /// Routes where "no signed-in user" is expected and must NOT be treated as a
  /// dropped session (startup gate, pre-auth welcome, and the blocked screen).
  static const _noUserRoutes = {Routes.splash, Routes.welcome, Routes.blocked};

  void _onAuthStateChanged(User? user) {
    if (user == null) {
      // A deliberate logout/deletion manages its own navigation — consume the
      // flag and stay silent instead of flashing "Session expired".
      if (_intentionalSignOut) {
        _intentionalSignOut = false;
        return;
      }
      if (!_noUserRoutes.contains(Get.currentRoute)) {
        _handleSessionExpired();
      }
    } else {
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
