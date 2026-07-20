import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_firestore_sync.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local subscription store for dev/demo — mirrors [FirestoreSubscriptionService]
/// behaviour without Firestore writes or RevenueCat.
///
/// State persists per family id via [SharedPreferences] so subscribe / expire /
/// free-view limits survive app restarts.
class MockSubscriptionService implements ISubscriptionService {
  static const _statePrefix = 'mock_sub_state_';
  static const _planPrefix = 'mock_sub_plan_';
  static const _viewedPrefix = 'mock_sub_viewed_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return SubscriptionConstants.plans;
  }

  @override
  Future<SubscriptionState> getState(String familyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final p = await _prefs;
    final raw = p.getString('$_statePrefix$familyId');
    if (raw == null) return SubscriptionState.free;
    return SubscriptionState.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SubscriptionState.free,
    );
  }

  @override
  Future<int> freeViewsUsed(String familyId) async {
    return (await viewedNannyIds(familyId)).length;
  }

  @override
  Future<Set<String>> viewedNannyIds(String familyId) async {
    final p = await _prefs;
    return (p.getStringList('$_viewedPrefix$familyId') ?? const []).toSet();
  }

  @override
  Future<void> recordView(String familyId, String nannyId) async {
    final p = await _prefs;
    final key = '$_viewedPrefix$familyId';
    final viewed = p.getStringList(key) ?? [];
    if (!viewed.contains(nannyId)) {
      await p.setStringList(key, [...viewed, nannyId]);
    }
    await MockSubscriptionFirestoreSync.syncProfileView(familyId, nannyId);
  }

  @override
  Future<void> subscribe(String familyId, String planId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final p = await _prefs;
    await p.setString('$_statePrefix$familyId', SubscriptionState.active.name);
    await p.setString('$_planPrefix$familyId', planId);
    await MockSubscriptionFirestoreSync.syncSubscription(
      familyId,
      SubscriptionState.active,
      planId: planId,
    );
    await MockSubscriptionFirestoreSync.syncAllProfileViews(
      familyId,
      await viewedNannyIds(familyId),
    );
  }

  @override
  Future<void> setState(String familyId, SubscriptionState state) async {
    final p = await _prefs;
    await p.setString('$_statePrefix$familyId', state.name);
    if (state == SubscriptionState.free || state == SubscriptionState.expired) {
      await p.remove('$_planPrefix$familyId');
    }
    final planId = await getActivePlanId(familyId);
    await MockSubscriptionFirestoreSync.syncSubscription(
      familyId,
      state,
      planId: planId,
    );
  }

  /// Pushes local viewed-profile ids to Firestore (e.g. after app restart).
  Future<void> syncEntitlementsToFirestore(String familyId) async {
    final state = await getState(familyId);
    final planId = await getActivePlanId(familyId);
    await MockSubscriptionFirestoreSync.syncSubscription(
      familyId,
      state,
      planId: planId,
    );
    await MockSubscriptionFirestoreSync.syncAllProfileViews(
      familyId,
      await viewedNannyIds(familyId),
    );
  }

  @override
  Future<String?> getActivePlanId(String familyId) async {
    final state = await getState(familyId);
    if (state == SubscriptionState.free || state == SubscriptionState.expired) {
      return null;
    }
    final p = await _prefs;
    return p.getString('$_planPrefix$familyId');
  }
}
