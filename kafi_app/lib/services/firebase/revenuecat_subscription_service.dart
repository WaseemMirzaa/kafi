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

  /// Plans with prices fetched from the stores via RevenueCat offerings.
  /// Falls back to the static plan list (no store price) if offerings can't
  /// be loaded, so the screen still renders — but purchase will then surface
  /// the real reason instead of a generic failure.
  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final base = await _firestore.getPlans();
    if (!RevenueCatConstants.isConfigured) return base;
    try {
      await _ensureConfigured();
      final offering = await _currentOffering();
      if (offering == null) {
        debugPrint('RevenueCat: no current offering — check dashboard.');
        return base;
      }
      return [
        for (final plan in base)
          plan.withStorePrice(
            _packageIn(offering, plan.id)?.storeProduct.priceString,
          ),
      ];
    } catch (e, st) {
      debugPrint('RevenueCat getPlans failed: $e\n$st');
      return base;
    }
  }

  Future<Offering?> _currentOffering() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current ??
        offerings.all[SubscriptionConstants.revenueCatOfferingId];
    if (current == null || current.availablePackages.isEmpty) return null;
    return current;
  }

  /// RevenueCat's store-verified entitlement is authoritative for unlocking
  /// the UI. Clients cannot write `families/{id}.subscription` (Firestore
  /// rules), so Firestore — kept in sync by `revenueCatWebhook` — is only the
  /// fallback when RevenueCat is unreachable or reports no active entitlement.
  Future<CustomerInfo?> _customerInfo() async {
    if (!RevenueCatConstants.isConfigured) return null;
    try {
      await _ensureConfigured();
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('RevenueCat getCustomerInfo failed: $e');
      return null;
    }
  }

  @override
  Future<SubscriptionState> getState(String familyId) async {
    final info = await _customerInfo();
    if (info != null && _hasPremium(info)) return SubscriptionState.active;
    return _firestore.getState(familyId);
  }

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
  Future<String?> getActivePlanId(String familyId) async {
    final info = await _customerInfo();
    if (info != null && _hasPremium(info)) {
      final fromStore = _planIdFromCustomerInfo(info);
      if (fromStore != null) return fromStore;
    }
    return _firestore.getActivePlanId(familyId);
  }

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
      debugPrint('RevenueCat purchase failed: code=$code $e');
      rethrow;
    }
    // No Firestore write here: rules forbid clients touching `subscription`.
    // The UI unlocks from the RevenueCat entitlement (see getState) and
    // `revenueCatWebhook` persists it server-side.
  }

  @override
  Future<bool> restorePurchases(String familyId) async {
    await _ensureConfigured();
    await Purchases.logIn(familyId);
    final info = await Purchases.restorePurchases();
    if (!_hasPremium(info)) return false;

    return true;
  }

  Package? _packageIn(Offering offering, String planId) {
    final productId = SubscriptionConstants.storeProductIdForPlan(planId);
    for (final pkg in offering.availablePackages) {
      final id = pkg.storeProduct.identifier;
      // Store ids may carry a suffix (e.g. kafi_weekly_ios) — same plan.
      if (id == productId || id.startsWith('${productId}_')) return pkg;
    }
    // Fallback: package type heuristics when product ids differ in sandbox.
    final type = switch (planId) {
      SubscriptionConstants.planWeekly => PackageType.weekly,
      SubscriptionConstants.planMonthly => PackageType.monthly,
      SubscriptionConstants.planBimonthly => PackageType.twoMonth,
      _ => null,
    };
    if (type == null) return null;
    for (final pkg in offering.availablePackages) {
      if (pkg.packageType == type) return pkg;
    }
    return null;
  }

  Future<Package> _packageForPlan(String planId) async {
    final offering = await _currentOffering();
    if (offering == null) {
      throw StateError(
        'No RevenueCat offerings available. Create an offering with products '
        'kafi_weekly / kafi_monthly / kafi_bimonthly in the dashboard and make '
        'sure the products are approved in App Store Connect / Play Console.',
      );
    }
    final pkg = _packageIn(offering, planId);
    if (pkg == null) {
      throw StateError(
        'No package for plan "$planId" '
        '(product "${SubscriptionConstants.storeProductIdForPlan(planId)}") '
        'in the current offering.',
      );
    }
    return pkg;
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
