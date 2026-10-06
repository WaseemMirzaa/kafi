class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.priceAed,
    required this.durationDays,
    this.savingsLabel,
    this.popular = false,
    this.storePrice,
  });

  final String id;
  final String label;
  final int priceAed;
  final int durationDays;
  final String? savingsLabel;
  final bool popular;

  /// Localised price string straight from the App Store / Play (via
  /// RevenueCat). Null when offerings weren't fetched — UI falls back to
  /// [priceAed].
  final String? storePrice;

  SubscriptionPlan withStorePrice(String? price) => SubscriptionPlan(
        id: id,
        label: label,
        priceAed: priceAed,
        durationDays: durationDays,
        savingsLabel: savingsLabel,
        popular: popular,
        storePrice: price,
      );
}
