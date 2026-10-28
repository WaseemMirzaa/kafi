import 'dart:async';

import 'package:flutter/widgets.dart';
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
class SubscriptionController extends GetxController with WidgetsBindingObserver {
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
  ///   - An expired plan re-locks EVERY nanny (prior free unlocks / paid period
  ///     do not carry over), except a nanny with a **live** trial (accepted /
  ///     running active) — contacts + chat stay until the trial period ends.
  ///   - An active plan (paid/trial/grace/cancelled-but-in-period) unlocks
  ///     every nanny.
  ///   - Free tier (never subscribed): unlocked only for nannies already in
  ///     [viewedNannyIds] — i.e. one of the family's 3 one-time free unlocks
  ///     was already spent on this nanny.
  /// General profile browsing (photos, nationality, experience, skills,
  /// languages, salary, visa status, etc.) is never gated by this — every
  /// nanny's general profile is always free to view.
  bool isNannyLocked(String nannyId) {
    if (isExpired) return !_hasLiveTrialWith(nannyId);
    if (hasActiveAccess) return false;
    return !viewedNannyIds.contains(nannyId);
  }

  /// Live trial with [nannyId] (accepted / active, endDate not past) — the only
  /// contact/chat bypass while the family's plan is expired (C14 / S15).
  bool _hasLiveTrialWith(String nannyId) {
    if (nannyId.isEmpty || !Get.isRegistered<TrialController>()) return false;
    return Get.find<TrialController>().all.any(
          (t) => t.nannyId == nannyId && t.isLiveTrial,
        );
  }

  StreamSubscription<void>? _entitlementSub;
  bool _refreshing = false;
  bool _refreshQueued = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Identify / clear RevenueCat when the signed-in family changes.
    ever(_auth.currentUser, (user) async {
      if (user != null && user.type == UserType.family) {
        await _bindFamily(user.id);
      } else if (user == null) {
        await _unbindFamily();
        await _subs.onUserSignedOut();
        state.value = SubscriptionState.free;
        freeViewsUsed.value = 0;
        viewedNannyIds.clear();
        activePlanId.value = null;
        isLocked.value = false;
      }
    });
    final existing = _auth.currentUser.value;
    if (existing != null && existing.type == UserType.family) {
      unawaited(_bindFamily(existing.id));
    } else {
      refreshAndEnforce();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _entitlementSub?.cancel();
    super.onClose();
  }

  /// Opening or returning to the app re-verifies the plan against the store and
  /// refreshes every gate, so a purchase, expiry, refund or restore made while
  /// the app was backgrounded (or on another device) shows up straight away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) return;
    final user = _auth.currentUser.value;
    if (user == null || user.type != UserType.family) return;
    unawaited(() async {
      await _subs.syncWithServer(user.id);
      await _refreshCoalesced();
    }());
  }

  /// Binds the store identity, asks the server to re-verify, loads state, then
  /// keeps it live by listening to the family document.
  Future<void> _bindFamily(String familyId) async {
    await _subs.onUserSignedIn(familyId);
    await _subs.syncWithServer(familyId);
    await refreshAndEnforce();
    await _entitlementSub?.cancel();
    // The first emission is the current state we just loaded; skip it.
    _entitlementSub = _subs.watchEntitlement(familyId).skip(1).listen(
          (_) => unawaited(_refreshCoalesced()),
          onError: (Object e) => debugPrint('Subscription listener: $e'),
        );
  }

  Future<void> _unbindFamily() async {
    await _entitlementSub?.cancel();
    _entitlementSub = null;
  }

  /// Runs [refreshAndEnforce] but never concurrently: a burst of document
  /// changes collapses into one in-flight refresh plus at most one follow-up.
  Future<void> _refreshCoalesced() async {
    if (_refreshing) {
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await refreshAndEnforce();
      } while (_refreshQueued);
    } finally {
      _refreshing = false;
    }
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
    // Firestore chat rules read `families.viewedProfiles` — wait briefly for
    // onProfileViewed so createThread is not permission-denied on a cold unlock.
    await _waitForViewedProfilesPersist(id, nannyId);
    return true;
  }

  /// Polls the family doc until [nannyId] appears in `viewedProfiles` (or timeout).
  Future<void> _waitForViewedProfilesPersist(String familyId, String nannyId) async {
    for (var i = 0; i < 15; i++) {
      try {
        final ids = await _subs.viewedNannyIds(familyId);
        if (ids.contains(nannyId)) return;
      } catch (_) {
        // Best-effort — chat may still succeed if rules see a prior unlock.
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
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
      debugPrint('Subscribe failed for plan $planId: $msg');
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
