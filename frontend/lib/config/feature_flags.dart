/// Central switches for features that are built but not offered yet.
/// Flip a flag to `true` to bring the feature (and its entry points) back;
/// no feature code has been removed.
class FeatureFlags {
  /// Paid subscription (plans, prices, checkout). Hidden for now.
  static const bool subscriptionEnabled = false;

  /// Parts marketplace (browse, cart, seller dashboard, add part, orders) and the
  /// per-code part search in the OBD screen. Hidden for now.
  static const bool marketplaceEnabled = false;

  /// "Parts that may be related" in the diagnosis result, with a "Find the part"
  /// button per part. Independent of the marketplace. The backend decides which
  /// stores exist (PARTS_GUIDE_ENABLED, off by default); when it answers 404 the
  /// button falls back to a general web search.
  static const bool partsGuideEnabled = true;
}
