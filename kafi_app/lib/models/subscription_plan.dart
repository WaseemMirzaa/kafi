class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.priceAed,
    required this.durationDays,
    this.savingsLabel,
    this.popular = false,
  });

  final String id;
  final String label;
  final int priceAed;
  final int durationDays;
  final String? savingsLabel;
  final bool popular;
}
