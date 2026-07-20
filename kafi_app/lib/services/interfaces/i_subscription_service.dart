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
}
