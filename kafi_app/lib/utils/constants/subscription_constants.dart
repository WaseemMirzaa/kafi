import 'package:kafi_app/models/subscription_plan.dart';

/// Subscription business constants (System spec §8).
class SubscriptionConstants {
  /// One-time free nanny unlocks granted to every new family account (never
  /// re-granted after a paid plan lapses — see SubscriptionController.
  /// isNannyLocked). A nanny is unlocked the moment the family opens her
  /// intro video, reveals her contact details, or starts a chat with her.
  static const freeNannyUnlockLimit = 3;
  static const vatRate = 0.05;

  static const planWeekly = 'weekly';
  static const planMonthly = 'monthly';
  static const planBimonthly = 'bimonthly';

  /// RevenueCat entitlement that unlocks family premium access.
  static const revenueCatEntitlementId = 'family_premium';

  /// Default offering identifier in the RevenueCat dashboard (current offering
  /// is used when this id is missing).
  static const revenueCatOfferingId = 'default';

  /// Store product identifiers registered in App Store Connect / Play Console
  /// and linked in RevenueCat. Override via dart-define if products differ.
  static const revenueCatProductWeekly = String.fromEnvironment(
    'REVENUECAT_PRODUCT_WEEKLY',
    defaultValue: 'kafi_weekly',
  );
  static const revenueCatProductMonthly = String.fromEnvironment(
    'REVENUECAT_PRODUCT_MONTHLY',
    defaultValue: 'kafi_monthly',
  );
  static const revenueCatProductBimonthly = String.fromEnvironment(
    'REVENUECAT_PRODUCT_BIMONTHLY',
    defaultValue: 'kafi_bimonthly',
  );

  /// Entry-tier (weekly) headline price in AED, shown on paywalls so they stay
  /// in sync with the pricing screen instead of hardcoding the number.
  static int get weeklyPriceAed =>
      plans.firstWhere((p) => p.id == planWeekly).priceAed;

  static const plans = [
    SubscriptionPlan(id: planWeekly, label: 'Weekly', priceAed: 89, durationDays: 7),
    SubscriptionPlan(
        id: planMonthly,
        label: 'Monthly',
        priceAed: 239,
        durationDays: 30,
        popular: true,
        savingsLabel: 'Most popular'),
    SubscriptionPlan(
        id: planBimonthly,
        label: '2 Months',
        priceAed: 369,
        durationDays: 60,
        savingsLabel: 'Save 129 AED'),
  ];

  /// Maps Kafi plan id → RevenueCat / store product id.
  static String storeProductIdForPlan(String planId) {
    switch (planId) {
      case planWeekly:
        return revenueCatProductWeekly;
      case planMonthly:
        return revenueCatProductMonthly;
      case planBimonthly:
        return revenueCatProductBimonthly;
      default:
        return planId;
    }
  }

  /// Maps store product id → Kafi plan id (webhook / restore).
  static String? planIdForStoreProduct(String productId) {
    if (productId == revenueCatProductWeekly || productId.endsWith('weekly')) {
      return planWeekly;
    }
    if (productId == revenueCatProductMonthly || productId.endsWith('monthly')) {
      return planMonthly;
    }
    if (productId == revenueCatProductBimonthly ||
        productId.contains('bimonth') ||
        productId.contains('2month') ||
        productId.contains('two_month')) {
      return planBimonthly;
    }
    return null;
  }
}
