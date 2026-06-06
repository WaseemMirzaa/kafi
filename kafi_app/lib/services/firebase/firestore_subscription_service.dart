import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';

class FirestoreSubscriptionService implements ISubscriptionService {
  final _families = FirebaseFirestore.instance.collection('families');

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    return SubscriptionConstants.plans;
  }

  @override
  Future<SubscriptionState> getState(String familyId) async {
    final snap = await _families.doc(familyId).get();
    if (!snap.exists) return SubscriptionState.free;

    final data = snap.data();
    final subData = data?['subscription'] as Map<String, dynamic>?;
    if (subData == null) return SubscriptionState.free;

    final status = subData['status'] as String?;
    switch (status) {
      case 'active':
        return SubscriptionState.active;
      case 'cancelled':
        final endDate = (subData['endDate'] as Timestamp?)?.toDate();
        if (endDate != null && endDate.isAfter(DateTime.now())) {
          return SubscriptionState.cancelledInPeriod;
        }
        return SubscriptionState.expired;
      case 'expired':
        return SubscriptionState.expired;
      case 'paymentFailed':
        return SubscriptionState.paymentGrace;
      default:
        return SubscriptionState.free;
    }
  }

  @override
  Future<int> freeViewsUsed(String familyId) async {
    final snap = await _families.doc(familyId).get();
    if (!snap.exists) return 0;
    return (snap.data()?['freeContactsUsed'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> recordView(String familyId, String nannyId) async {
    // Transactional dedupe — `freeContactsUsed` must only increment when the
    // nannyId is genuinely new. The previous `arrayUnion` + `increment(1)`
    // burned a free view every revisit which caused the "out of free views"
    // paywall to fire before the spec'd 3 unique profiles.
    final ref = _families.doc(familyId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final viewed = List<String>.from(
        (snap.data()?['viewedProfiles'] as List?) ?? const [],
      );
      if (viewed.contains(nannyId)) return;
      viewed.add(nannyId);
      tx.set(
        ref,
        {
          'viewedProfiles': viewed,
          'freeContactsUsed': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> subscribe(String familyId, String planId) async {
    final plan = SubscriptionConstants.plans.firstWhere((p) => p.id == planId);
    final now = DateTime.now();
    final endDate = now.add(Duration(days: plan.durationDays));

    await _families.doc(familyId).set({
      'subscription': {
        'status': 'active',
        'plan': planId,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(endDate),
        'autoRenew': true,
        'hasEverSubscribed': true,
        'lastRenewalAt': Timestamp.fromDate(now),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setState(String familyId, SubscriptionState state) async {
    String statusStr;
    switch (state) {
      case SubscriptionState.active:
        statusStr = 'active';
        break;
      case SubscriptionState.cancelledInPeriod:
        statusStr = 'cancelled';
        break;
      case SubscriptionState.expired:
        statusStr = 'expired';
        break;
      case SubscriptionState.paymentGrace:
        statusStr = 'paymentFailed';
        break;
      default:
        statusStr = 'free';
    }

    await _families.doc(familyId).set({
      'subscription': {
        'status': statusStr,
        if (state == SubscriptionState.expired)
          'expiredAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  @override
  Future<String?> getActivePlanId(String familyId) async {
    final snap = await _families.doc(familyId).get();
    final subData = snap.data()?['subscription'] as Map<String, dynamic>?;
    return subData?['plan'] as String?;
  }
}
