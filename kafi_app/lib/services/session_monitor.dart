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

  /// True once the startup inactivity gate has run. Until then the auth-state
  /// listener must NOT stamp activity: the initial `authStateChanges` emission
  /// would otherwise reset the clock before [enforceInactivityAtStartup] can
  /// read the previous session's stamp, defeating the 90-day logout (NAN-1).
  bool _startupHandled = false;

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
    // The startup activity stamp is intentionally NOT written here. Startup
    // routing (bootstrapStartup) awaits [enforceInactivityAtStartup] BEFORE it
    // reads the current user; that method reads the PREVIOUS session's stamp to
    // enforce the inactivity logout and only then stamps fresh activity. A
    // touch() here would reset the clock on every launch, so the 90-day logout
    // could never fire (NAN-1).
    _inactivityTimer =
        Timer.periodic(const Duration(minutes: 30), (_) => _enforceInactivity());
  }

  /// Startup-time inactivity gate. Reads the activity stamp persisted by the
  /// PREVIOUS session; if it is older than [_maxInactiveDays] the session is
  /// signed out, otherwise fresh activity is stamped for this launch. Returns
  /// true when it signed the user out. [bootstrapStartup] awaits this BEFORE it
  /// reads the current user, so an idle-expired session lands on welcome instead
  /// of silently resuming (NAN-1).
  Future<bool> enforceInactivityAtStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_kLastActivity);
      if (last != null) {
        final ageDays = DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(last))
            .inDays;
        if (ageDays >= _maxInactiveDays) {
          if (!AppConfig.useMock) {
            await FirebaseAuth.instance.signOut();
          }
          await prefs.remove(_kLastActivity); // next session starts a fresh clock
          _startupHandled = true;
          return true;
        }
      }
      await touch(); // valid session (or first-ever launch) — stamp this launch
    } catch (_) {
      // A prefs/sign-out failure must never block startup — fall through as
      // "not expired" and let normal routing proceed.
    }
    _startupHandled = true;
    return false;
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
  /// dropped session (startup, welcome/blocked, and the phone-OTP auth funnel).
  /// Login + OTP are included because Firebase phone auth keeps `currentUser`
  /// null until the code is verified — and returning from the iOS reCAPTCHA
  /// sheet can re-emit `authStateChanges(null)`, which previously force-sent
  /// the user back to welcome right after "OTP sent".
  static const _noUserRoutes = {
    Routes.splash,
    Routes.welcome,
    Routes.blocked,
    Routes.loginNanny,
    Routes.loginFamily,
    Routes.otpVerify,
    Routes.terms,
    Routes.privacy,
  };

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
      // Skip the initial startup emission — enforceInactivityAtStartup() owns
      // the first stamp (and may sign out). Stamp only genuine later re-auths,
      // so the startup emission can't reset the inactivity clock first (NAN-1).
      if (_startupHandled) touch();
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
