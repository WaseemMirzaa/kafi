import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/services/firebase/firestore_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/utils/constants/revenuecat_constants.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Live subscription path (Technical Architecture): RevenueCat for StoreKit /
/// Play Billing; Firestore for free-view counters and webhook-synced status.
///
/// Purchase / restore talk to the store via `purchases_flutter`. After a
/// successful purchase we optimistically mirror `active` onto the family doc
/// so UI unlocks immediately; `revenueCatWebhook` remains the long-term
/// source of truth for dates and renewals.
class RevenueCatSubscriptionService implements ISubscriptionService {
  RevenueCatSubscriptionService({FirestoreSubscriptionService? firestore})
      : _firestore = firestore ?? FirestoreSubscriptionService();

  final FirestoreSubscriptionService _firestore;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    if (!RevenueCatConstants.isConfigured) {
      throw StateError(
        'RevenueCat API key missing. Pass REVENUECAT_IOS_API_KEY / '
        'REVENUECAT_ANDROID_API_KEY via --dart-define, or set '
        'AppConfig.useMockSubscription = true for local demo purchases.',
      );
    }
    final config = PurchasesConfiguration(RevenueCatConstants.apiKey);
    await Purchases.configure(config);
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    _configured = true;
  }

  @override
  Future<void> onUserSignedIn(String familyId) async {
    if (!RevenueCatConstants.isConfigured) return;
    try {
      await _ensureConfigured();
      await Purchases.logIn(familyId);
    } catch (e, st) {
      debugPrint('RevenueCat logIn failed: $e\n$st');
    }
  }

  @override
  Future<void> onUserSignedOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e, st) {
      debugPrint('RevenueCat logOut failed: $e\n$st');
    }
  }

  @override
  Future<List<SubscriptionPlan>> getPlans() => _firestore.getPlans();

  @override
  Future<SubscriptionState> getState(String familyId) =>
      _firestore.getState(familyId);

  @override
  Future<int> freeViewsUsed(String familyId) =>
      _firestore.freeViewsUsed(familyId);

  @override
  Future<Set<String>> viewedNannyIds(String familyId) =>
      _firestore.viewedNannyIds(familyId);

  @override
  Future<void> recordView(String familyId, String nannyId) =>
      _firestore.recordView(familyId, nannyId);

  @override
  Future<void> setState(String familyId, SubscriptionState state) =>
      _firestore.setState(familyId, state);

  @override
  Future<String?> getActivePlanId(String familyId) =>
      _firestore.getActivePlanId(familyId);

  @override
  Future<void> subscribe(String familyId, String planId) async {
    await _ensureConfigured();
    await Purchases.logIn(familyId);

    final package = await _packageForPlan(planId);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      if (!_hasPremium(result.customerInfo)) {
        throw StateError('Purchase completed but entitlement is not active yet.');
      }
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw StateError('cancelled');
      }
      rethrow;
    }

    // Optimistic unlock — webhook will reconcile endDate / renewals.
    await _firestore.subscribe(familyId, planId);
  }

  @override
  Future<bool> restorePurchases(String familyId) async {
    await _ensureConfigured();
    await Purchases.logIn(familyId);
    final info = await Purchases.restorePurchases();
    if (!_hasPremium(info)) return false;

    final planId = _planIdFromCustomerInfo(info) ?? SubscriptionConstants.planMonthly;
    await _firestore.subscribe(familyId, planId);
    return true;
  }

  Future<Package> _packageForPlan(String planId) async {
    final offerings = await Purchases.getOfferings();
    Offering? offering = offerings.current;
    if (offering == null &&
        offerings.all.containsKey(SubscriptionConstants.revenueCatOfferingId)) {
      offering = offerings.all[SubscriptionConstants.revenueCatOfferingId];
    }
    if (offering == null || offering.availablePackages.isEmpty) {
      throw StateError(
        'No RevenueCat offerings available. Create an offering with products '
        'kafi_weekly / kafi_monthly / kafi_bimonthly in the dashboard.',
      );
    }

    final productId = SubscriptionConstants.storeProductIdForPlan(planId);
    for (final pkg in offering.availablePackages) {
      if (pkg.storeProduct.identifier == productId) return pkg;
    }

    // Fallback: package type heuristics when product ids differ in sandbox.
    switch (planId) {
      case SubscriptionConstants.planWeekly:
        final weekly = offering.availablePackages.where(
          (p) => p.packageType == PackageType.weekly,
        );
        if (weekly.isNotEmpty) return weekly.first;
        break;
      case SubscriptionConstants.planMonthly:
        final monthly = offering.availablePackages.where(
          (p) => p.packageType == PackageType.monthly,
        );
        if (monthly.isNotEmpty) return monthly.first;
        break;
      case SubscriptionConstants.planBimonthly:
        final twoMonth = offering.availablePackages.where(
          (p) => p.packageType == PackageType.twoMonth,
        );
        if (twoMonth.isNotEmpty) return twoMonth.first;
        break;
    }

    throw StateError(
      'No package for plan "$planId" (product "$productId") in the current offering.',
    );
  }

  bool _hasPremium(CustomerInfo info) {
    final ent = info.entitlements.all[SubscriptionConstants.revenueCatEntitlementId];
    if (ent?.isActive == true) return true;
    // Fallback: any active entitlement if the dashboard id differs slightly.
    return info.entitlements.active.isNotEmpty;
  }

  String? _planIdFromCustomerInfo(CustomerInfo info) {
    final ent = info.entitlements.all[SubscriptionConstants.revenueCatEntitlementId] ??
        (info.entitlements.active.isNotEmpty
            ? info.entitlements.active.values.first
            : null);
    final productId = ent?.productIdentifier;
    if (productId == null) return null;
    return SubscriptionConstants.planIdForStoreProduct(productId);
  }
}
