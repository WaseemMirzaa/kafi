import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
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

  int get freeViewsRemaining =>
      (SubscriptionConstants.freeProfileViewLimit - freeViewsUsed.value).clamp(0, 999);

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

  @override
  void onInit() {
    super.onInit();
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
    freeViewsUsed.value = await _subs.freeViewsUsed(id);
    final fam = await _users.getFamily(id);
    if (fam != null) {
      viewedNannyIds.assignAll(fam.viewedProfiles);
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

    // Free tier path: caller checks freeViewsRemaining()
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

  Future<bool> recordViewIfAllowed(String nannyId) async {
    final id = currentFamilyId(_auth);
    if (id == null) return false;
    if (isSubscribed) return true;
    // Expired users can still re-open profiles they previously viewed
    // (Screen 16A — Profile Re-Locked); they cannot view NEW profiles.
    if (isExpired) {
      return viewedNannyIds.contains(nannyId);
    }
    // Already viewed → don't consume another free view.
    if (viewedNannyIds.contains(nannyId)) return true;
    if (freeViewsRemaining <= 0) return false;
    await _subs.recordView(id, nannyId);
    viewedNannyIds.add(nannyId);
    // Count locally from the deduped set — the onProfileViewed function updates
    // the server's freeContactsUsed asynchronously, so re-reading it here would
    // lag and let the gate over-grant. refreshAndEnforce() re-syncs from server.
    freeViewsUsed.value = viewedNannyIds.length;
    return true;
  }

  Future<void> subscribe(String planId) async {
    final id = currentFamilyId(_auth);
    if (id == null) return;
    await _subs.subscribe(id, planId);
    await refreshAndEnforce();
  }

  Future<void> restorePurchases() async {
    // Call RevenueCat restore in production
    await refreshAndEnforce();
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
