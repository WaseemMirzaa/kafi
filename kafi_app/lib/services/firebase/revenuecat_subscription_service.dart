import 'package:cloud_functions/cloud_functions.dart';
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

  /// Customer info from the on-device RevenueCat SDK, or null if unreachable.
  /// This is the *store's* view for whichever Kafi account is logged in — it is
  /// only a hint that a purchase exists, never what unlocks features.
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

  static bool _grantsAccess(SubscriptionState s) =>
      s == SubscriptionState.active ||
      s == SubscriptionState.cancelledInPeriod ||
      s == SubscriptionState.paymentGrace;

  /// Firestore (`families/{id}.subscription`, written only by the webhook and
  /// the server-side sync) is the single source of truth. The security rules,
  /// the contact gate and every other client read the same document, so the UI
  /// can never show unlocked while the server refuses. The on-device store
  /// entitlement is only used to notice "paid but the server hasn't caught up"
  /// and ask the server to re-verify.
  @override
  Future<SubscriptionState> getState(String familyId) async {
    final server = await _firestore.getState(familyId);
    if (_grantsAccess(server)) return server;
    final info = await _customerInfo();
    if (info != null && _hasPremium(info)) {
      await syncWithServer(familyId);
      return _firestore.getState(familyId);
    }
    return server;
  }

  @override
  Future<void> syncWithServer(String familyId) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('syncSubscription').call();
    } catch (e) {
      // Best effort: the webhook remains the primary path.
      debugPrint('syncSubscription failed: $e');
    }
  }

  @override
  Stream<void> watchEntitlement(String familyId) =>
      _firestore.watchEntitlement(familyId);

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
    final fromServer = await _firestore.getActivePlanId(familyId);
    if (fromServer != null) return fromServer;
    final info = await _customerInfo();
    if (info != null && _hasPremium(info)) return _planIdFromCustomerInfo(info);
    return null;
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
    await _awaitServerEntitlement(familyId);
  }

  /// RevenueCat reports the entitlement the moment the store confirms, but the
  /// Firestore rules and Cloud Functions (chat create, contact reveal) only see
  /// it once `revenueCatWebhook` has written `subscription`. Unlocking the UI
  /// before then lets the first chat/reveal be rejected, so hold the purchase
  /// flow open until the server agrees. Best-effort: on timeout the purchase
  /// still stands (the webhook will land) and we just stop waiting.
  Future<void> _awaitServerEntitlement(String familyId) async {
    const attempts = 16;
    const interval = Duration(milliseconds: 500);
    for (var i = 0; i < attempts; i++) {
      // If the webhook hasn't landed after ~1s, ask the server to check the
      // store itself rather than wait on it alone.
      if (i == 2) await syncWithServer(familyId);
      try {
        final s = await _firestore.getState(familyId);
        if (s == SubscriptionState.active ||
            s == SubscriptionState.cancelledInPeriod) {
          return;
        }
      } catch (e) {
        debugPrint('Waiting for server entitlement: $e');
      }
      await Future<void>.delayed(interval);
    }
    debugPrint('RevenueCat webhook has not updated Firestore yet for $familyId.');
  }

  @override
  Future<bool> restorePurchases(String familyId) async {
    await _ensureConfigured();
    await Purchases.logIn(familyId);
    final info = await Purchases.restorePurchases();
    if (!_hasPremium(info)) return false;

    await syncWithServer(familyId);
    await _awaitServerEntitlement(familyId);
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
