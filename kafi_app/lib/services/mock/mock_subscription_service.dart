import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';

class MockSubscriptionService implements ISubscriptionService {
  final Map<String, SubscriptionState> _states = {};
  final Map<String, String> _activePlan = {};
  final Map<String, Set<String>> _viewed = {
    MockDemoIds.family: {'n2', 'n3', 'n5'},
  };

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return SubscriptionConstants.plans;
  }

  @override
  Future<SubscriptionState> getState(String familyId) async {
    // Mock demo: active subscription so family flows (browse, chat, profiles) work.
    return _states[familyId] ?? SubscriptionState.active;
  }

  @override
  Future<int> freeViewsUsed(String familyId) async => _viewed[familyId]?.length ?? 0;

  @override
  Future<void> recordView(String familyId, String nannyId) async {
    _viewed.putIfAbsent(familyId, () => {}).add(nannyId);
  }

  @override
  Future<void> subscribe(String familyId, String planId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _states[familyId] = SubscriptionState.active;
    _activePlan[familyId] = planId;
  }

  @override
  Future<void> setState(String familyId, SubscriptionState state) async {
    _states[familyId] = state;
    if (state == SubscriptionState.free || state == SubscriptionState.expired) {
      _activePlan.remove(familyId);
    }
  }

  @override
  Future<String?> getActivePlanId(String familyId) async => _activePlan[familyId];
}
