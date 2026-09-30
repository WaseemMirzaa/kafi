import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';

/// Subscription controller per Technical Architecture §3.8
/// Manages subscription states and lockdown enforcement.
class SubscriptionController extends GetxController {
  final ISubscriptionService _subs = Get.find<ISubscriptionService>();
  final AuthController _auth = Get.find<AuthController>();
  final IUserService _users = Get.find<IUserService>();

  final RxList<SubscriptionPlan> plans = <SubscriptionPlan>[].obs;
  final Rx<SubscriptionState> state = SubscriptionState.free.obs;
  final RxInt freeViewsUsed = 0.obs;
  final RxBool isLocked = false.obs;

  /// Id of the plan the family is currently subscribed to (null if none).
  final RxnString activePlanId = RxnString();

  int get freeUnlocksRemaining =>
      (SubscriptionConstants.freeNannyUnlockLimit - freeViewsUsed.value).clamp(0, 999);

  /// Per docs §3.8: hasActiveAccess covers ACTIVE, TRIAL, CANCELLED-in-period, GRACE.
  /// Grace period maintains access while payment retry is in progress.
  bool get hasActiveAccess =>
      state.value == SubscriptionState.active ||
      state.value == SubscriptionState.trial ||
      state.value == SubscriptionState.cancelledInPeriod ||
      state.value == SubscriptionState.paymentGrace;

  /// Legacy alias
  bool get isSubscribed => hasActiveAccess;

  /// Per docs: only expired triggers full lockdown (grace keeps access).
  bool get isExpired => state.value == SubscriptionState.expired;

  /// Grace period: access still granted but warn user.
  bool get isInGrace => state.value == SubscriptionState.paymentGrace;

  /// Derived: contacts should be hidden (blurred phone, no call/whatsapp)
  bool get contactsHidden => isExpired;

  /// Derived: chat list should be locked behind paywall
  bool get chatLocked => isExpired;

  /// The single gate for a nanny's premium content — intro video, phone/CV
  /// reveal, and starting or reopening a chat. Per the family-access spec:
  ///   - An expired plan re-locks EVERY nanny, even ones unlocked earlier
  ///     (via a free unlock or a past paid plan) — no exceptions.
  ///   - An active plan (paid/trial/grace/cancelled-but-in-period) unlocks
  ///     every nanny.
  ///   - Free tier (never subscribed): unlocked only for nannies already in
  ///     [viewedNannyIds] — i.e. one of the family's 3 one-time free unlocks
  ///     was already spent on this nanny.
  /// General profile browsing (photos, nationality, experience, skills,
  /// languages, salary, visa status, etc.) is never gated by this — every
  /// nanny's general profile is always free to view.
  bool isNannyLocked(String nannyId) {
    if (isExpired) return true;
    if (hasActiveAccess) return false;
    return !viewedNannyIds.contains(nannyId);
  }

  @override
  void onInit() {
    super.onInit();
    // Identify / clear RevenueCat when the signed-in family changes.
    ever(_auth.currentUser, (user) async {
      if (user != null && user.type == UserType.family) {
        await _subs.onUserSignedIn(user.id);
        await refreshAndEnforce();
      } else if (user == null) {
        await _subs.onUserSignedOut();
      }
    });
    final existing = _auth.currentUser.value;
    if (existing != null && existing.type == UserType.family) {
      _subs.onUserSignedIn(existing.id);
    }
    refreshAndEnforce();
  }

  /// Called on app start, foreground resume, and Cloud Function trigger.
  /// Updates subscription state and applies lockdown if expired.
  Future<void> refreshAndEnforce() async {
    plans.value = await _subs.getPlans();
    final id = currentFamilyId(_auth);
    if (id == null) return;
    state.value = await _subs.getState(id);
    activePlanId.value = hasActiveAccess ? await _subs.getActivePlanId(id) : null;
    if (AppConfig.subscriptionUsesMock) {
      viewedNannyIds.assignAll(await _subs.viewedNannyIds(id));
      freeViewsUsed.value = viewedNannyIds.length;
      if (_subs is MockSubscriptionService) {
        await (_subs as MockSubscriptionService).syncEntitlementsToFirestore(id);
      }
    } else {
      freeViewsUsed.value = await _subs.freeViewsUsed(id);
      final fam = await _users.getFamily(id);
      if (fam != null) {
        viewedNannyIds.assignAll(fam.viewedProfiles);
      }
    }
    if (isExpired) {
      _applyLockdown();
    } else {
      _removeLockdown();
    }
  }

  Future<void> refreshAll() => refreshAndEnforce();

  void _applyLockdown() {
    isLocked.value = true;
  }

  void _removeLockdown() {
    isLocked.value = false;
  }

  /// Used by UI to gate any "premium" action.
  /// Returns true if access granted, false if paywall should be shown.
  bool requireSubscription(String featureName, {String? trialId}) {
    // Exception: active trial bypasses lockdown for trial chat/contacts
    if (trialId != null && _isActiveTrial(trialId)) return true;

    if (hasActiveAccess) return true;

    // Free tier path: caller checks unlockNannyIfAllowed()
    if (state.value == SubscriptionState.free) {
      return false;
    }

    // Expired: show paywall
    Get.toNamed(Routes.pricing, arguments: {'reason': 'expired', 'feature': featureName});
    return false;
  }

  bool _isActiveTrial(String trialId) {
    if (!Get.isRegistered<TrialController>()) return false;
    final trials = Get.find<TrialController>().all;
    return trials.any((t) =>
        t.id == trialId &&
        (t.status == TrialStatus.active || t.status == TrialStatus.accepted));
  }

  /// Cache of viewed nanny IDs to avoid burning duplicate free views.
  final RxSet<String> viewedNannyIds = <String>{}.obs;

  /// Spends one of the family's 3 one-time free nanny unlocks on [nannyId],
  /// if it isn't already unlocked. Call this from the video / contact / chat
  /// trigger points — never from opening a profile, which is always free.
  /// Returns true when the nanny ends up unlocked (already was, subscribed,
  /// or a free slot was just spent) and the caller should proceed; false
  /// means no free slots remain (or the plan is expired) and the caller
  /// should route to the paywall instead.
  Future<bool> unlockNannyIfAllowed(String nannyId) async {
    final id = currentFamilyId(_auth);
    if (id == null) return false;
    if (hasActiveAccess) return true;
    // Expired: full lockdown, even for a previously-unlocked nanny — the
    // family must resubscribe. The one-time 3 free unlocks are never
    // re-granted (see SubscriptionConstants.freeNannyUnlockLimit).
    if (isExpired) return false;
    // Already unlocked → free forever for this nanny, no new slot spent.
    if (viewedNannyIds.contains(nannyId)) return true;
    if (freeUnlocksRemaining <= 0) return false;
    await _subs.recordView(id, nannyId);
    viewedNannyIds.add(nannyId);
    // Count locally from the deduped set — the onProfileViewed function updates
    // the server's freeContactsUsed asynchronously, so re-reading it here would
    // lag and let the gate over-grant. refreshAndEnforce() re-syncs from server.
    freeViewsUsed.value = viewedNannyIds.length;
    return true;
  }

  /// Returns true when the subscription write succeeded, so the caller only
  /// confirms + navigates on success (was previously fire-and-forget with an
  /// unconditional "active" toast).
  Future<bool> subscribe(String planId) async {
    final id = currentFamilyId(_auth);
    if (id == null) return false;
    try {
      await _subs.subscribe(id, planId);
      await refreshAndEnforce();
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled')) {
        return false;
      }
      Get.snackbar(
        AppStrings.errorTitle.tr,
        msg.contains('RevenueCat API key')
            ? AppStrings.errSubNotConfigured.tr
            : AppStrings.errSubPurchaseFailed.tr,
      );
      return false;
    }
  }

  /// Returns true when the restore succeeded so the caller only confirms on
  /// success (was fire-and-forget with an unconditional "restored" toast).
  Future<bool> restorePurchases() async {
    final id = currentFamilyId(_auth);
    if (id == null) return false;
    try {
      final ok = await _subs.restorePurchases(id);
      await refreshAndEnforce();
      if (!ok) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.errSubRestoreFailed.tr);
      }
      return ok;
    } catch (e) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        e.toString().contains('RevenueCat API key')
            ? AppStrings.errSubNotConfigured.tr
            : AppStrings.errSubRestoreFailed.tr,
      );
      return false;
    }
  }

  /// For testing lockdown flow
  Future<void> simulateExpire() async {
    final id = currentFamilyId(_auth);
    if (id == null) return;
    await _subs.setState(id, SubscriptionState.expired);
    state.value = SubscriptionState.expired;
    _applyLockdown();
  }

  /// For testing restore flow
  Future<void> simulateRestore() async {
    final id = currentFamilyId(_auth);
    if (id == null) return;
    await _subs.setState(id, SubscriptionState.active);
    state.value = SubscriptionState.active;
    _removeLockdown();
  }
}
