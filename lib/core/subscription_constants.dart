/// Constants for the ShipRate Pro subscription plans (RevenueCat).
///
/// Product IDs, entitlement IDs and the API key are placeholders until the
/// real values are created in App Store Connect and in the RevenueCat
/// dashboard.
class SubscriptionConstants {
  SubscriptionConstants._();

  /// Value [revenueCatApiKey] holds while the real key is not configured yet.
  static const String placeholderApiKey = 'PLACEHOLDER_API_KEY';

  // Store product IDs (App Store Connect).
  static const String plusMonthly = 'shiprate_plus_monthly';
  static const String premiumMonthly = 'shiprate_premium_monthly';

  // RevenueCat entitlement IDs.
  static const String plusEntitlement = 'plus';
  static const String premiumEntitlement = 'premium';

  // RevenueCat public SDK key.
  static const String revenueCatApiKey = placeholderApiKey;

  // Plan values stored in `usuarios/{uid}.subscription.plan`.
  static const String planNone = 'none';
  static const String planPlus = 'plus';
  static const String planPremium = 'premium';

  /// False while [revenueCatApiKey] still holds [placeholderApiKey].
  static bool get isApiKeyConfigured =>
      revenueCatApiKey.isNotEmpty && revenueCatApiKey != placeholderApiKey;
}
