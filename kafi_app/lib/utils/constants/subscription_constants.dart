import 'package:kafi_app/models/subscription_plan.dart';

/// Subscription business constants (System spec §8).
class SubscriptionConstants {
  static const freeProfileViewLimit = 5;
  static const vatRate = 0.05;

  static const planWeekly = 'weekly';
  static const planMonthly = 'monthly';
  static const planBimonthly = 'bimonthly';

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
}
