/// Central switches for features that are built but not offered yet.
/// Flip a flag to `true` to bring the feature (and its entry points) back;
/// no feature code has been removed.
class FeatureFlags {
  /// Paid subscription (plans, prices, checkout). Hidden for now.
  static const bool subscriptionEnabled = false;

  /// Parts marketplace (browse, cart, seller dashboard, add part, orders)
  /// and the "find a part" shortcuts in the diagnosis result. Hidden for now.
  static const bool marketplaceEnabled = false;
}
