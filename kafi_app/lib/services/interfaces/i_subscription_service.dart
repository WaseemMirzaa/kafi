import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';

abstract class ISubscriptionService {
  Future<List<SubscriptionPlan>> getPlans();
  Future<SubscriptionState> getState(String familyId);
  Future<int> freeViewsUsed(String familyId);
  Future<Set<String>> viewedNannyIds(String familyId);
  Future<void> recordView(String familyId, String nannyId);
  Future<void> subscribe(String familyId, String planId);
  Future<void> setState(String familyId, SubscriptionState state);

  /// The id of the plan the family last subscribed to (null if none/free).
  Future<String?> getActivePlanId(String familyId);

  /// Restore App Store / Play purchases and sync entitlement.
  /// Returns true when an active entitlement was restored.
  Future<bool> restorePurchases(String familyId);

  /// Bind RevenueCat app user id after family auth (no-op for mock).
  Future<void> onUserSignedIn(String familyId);

  /// Clear RevenueCat user on logout (no-op for mock).
  Future<void> onUserSignedOut();

  /// Ask the server to re-verify this family against the store and correct
  /// `families/{id}.subscription` (no-op for mock). Best effort: never throws.
  Future<void> syncWithServer(String familyId);

  /// Emits whenever the family's server-side entitlement changes (plan status,
  /// end date, plan, free unlocks) so every screen can react live instead of
  /// waiting for the next manual refresh. Empty for mock.
  Stream<void> watchEntitlement(String familyId);
}
