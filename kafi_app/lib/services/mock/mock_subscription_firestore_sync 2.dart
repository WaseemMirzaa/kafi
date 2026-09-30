import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:kafi_app/models/family_model.dart';

/// Mirrors local mock subscription / profile-view state into Firestore so
/// security rules and Cloud Functions see the same entitlement as the app UI.
class MockSubscriptionFirestoreSync {
  static Future<void> syncProfileView(String familyId, String nannyId) async {
    await FirebaseFirestore.instance
        .collection('profileViews')
        .doc('${familyId}_$nannyId')
        .set({
      'familyId': familyId,
      'nannyId': nannyId,
      'viewedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> syncAllProfileViews(
    String familyId,
    Iterable<String> nannyIds,
  ) async {
    for (final nannyId in nannyIds) {
      try {
        await syncProfileView(familyId, nannyId);
      } catch (e, st) {
        debugPrint('[MockSubscriptionFirestoreSync] profileView $nannyId: $e\n$st');
      }
    }
  }

  /// Writes subscription entitlement via [syncMockSubscription]. Throws on
  /// failure so chat/send can surface the error instead of a silent rules deny.
  static Future<void> syncSubscription(
    String familyId,
    SubscriptionState state, {
    String? planId,
    bool swallowErrors = false,
  }) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('syncMockSubscription').call({
        'state': state.name,
        if (planId != null) 'planId': planId,
      });
    } catch (e, st) {
      debugPrint('[MockSubscriptionFirestoreSync] subscription: $e\n$st');
      if (!swallowErrors) rethrow;
    }
  }
}
