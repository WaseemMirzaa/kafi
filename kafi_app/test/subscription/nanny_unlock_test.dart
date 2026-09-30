import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/models/family_model.dart' show SubscriptionState;
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/services/mock/mock_user_service.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the family-access spec: 3 one-time free nanny unlocks (video /
/// contact / chat), full re-lockdown on expiry (even for previously-unlocked
/// nannies), and no re-granting of free unlocks after a plan lapses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SubscriptionController controller;
  late AuthController auth;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put<IAuthService>(MockAuthService());
    Get.put<IUserService>(MockUserService());
    Get.put<ISubscriptionService>(MockSubscriptionService());
    auth = Get.put(AuthController());
    auth.currentUser.value = const UserModel(id: 'f1', phone: '+971500000000', type: UserType.family);
    // Construct directly (not via Get.put) so onInit's auto-refresh/listener
    // wiring doesn't race the manual state below.
    controller = SubscriptionController();
  });

  tearDown(Get.reset);

  group('isNannyLocked', () {
    test('free tier: locked until this nanny is unlocked', () {
      controller.state.value = SubscriptionState.free;
      expect(controller.isNannyLocked('n1'), isTrue);
      controller.viewedNannyIds.add('n1');
      expect(controller.isNannyLocked('n1'), isFalse);
      expect(controller.isNannyLocked('n2'), isTrue);
    });

    test('active plan unlocks every nanny, even unvisited ones', () {
      controller.state.value = SubscriptionState.active;
      expect(controller.isNannyLocked('n1'), isFalse);
      expect(controller.isNannyLocked('unseen'), isFalse);
    });

    test('trial and grace period behave like an active plan', () {
      controller.state.value = SubscriptionState.trial;
      expect(controller.isNannyLocked('n1'), isFalse);
      controller.state.value = SubscriptionState.paymentGrace;
      expect(controller.isNannyLocked('n1'), isFalse);
    });

    test('expiry re-locks every nanny, including ones already unlocked', () {
      controller.state.value = SubscriptionState.free;
      controller.viewedNannyIds.addAll({'n1', 'n2'});
      controller.state.value = SubscriptionState.expired;
      expect(controller.isNannyLocked('n1'), isTrue);
      expect(controller.isNannyLocked('n2'), isTrue);
      expect(controller.isNannyLocked('n3'), isTrue);
    });
  });

  group('unlockNannyIfAllowed', () {
    test('spends one of the 3 free unlocks per unique nanny', () async {
      controller.state.value = SubscriptionState.free;
      expect(await controller.unlockNannyIfAllowed('n1'), isTrue);
      expect(await controller.unlockNannyIfAllowed('n2'), isTrue);
      expect(await controller.unlockNannyIfAllowed('n3'), isTrue);
      expect(controller.freeUnlocksRemaining, 0);
      expect(await controller.unlockNannyIfAllowed('n4'), isFalse);
    });

    test('re-unlocking the same nanny is free (no double charge)', () async {
      controller.state.value = SubscriptionState.free;
      expect(await controller.unlockNannyIfAllowed('n1'), isTrue);
      expect(await controller.unlockNannyIfAllowed('n1'), isTrue);
      expect(controller.freeUnlocksRemaining, SubscriptionConstants.freeNannyUnlockLimit - 1);
    });

    test('an active plan never spends a free unlock', () async {
      controller.state.value = SubscriptionState.active;
      expect(await controller.unlockNannyIfAllowed('n1'), isTrue);
      expect(controller.viewedNannyIds.contains('n1'), isFalse);
      expect(controller.freeUnlocksRemaining, SubscriptionConstants.freeNannyUnlockLimit);
    });

    test('expiry blocks new unlocks even with free slots left on paper', () async {
      controller.state.value = SubscriptionState.expired;
      expect(await controller.unlockNannyIfAllowed('n1'), isFalse);
    });

    test('a new plan after expiry does not restore spent free unlocks', () async {
      controller.state.value = SubscriptionState.free;
      await controller.unlockNannyIfAllowed('n1');
      await controller.unlockNannyIfAllowed('n2');
      await controller.unlockNannyIfAllowed('n3');
      controller.state.value = SubscriptionState.expired;
      controller.state.value = SubscriptionState.active; // renews
      controller.state.value = SubscriptionState.expired; // lapses again
      controller.state.value = SubscriptionState.free; // back to free tier
      expect(controller.freeUnlocksRemaining, 0);
      expect(await controller.unlockNannyIfAllowed('n4'), isFalse);
    });
  });
}
