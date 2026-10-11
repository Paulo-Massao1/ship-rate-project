import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants.dart';
import '../../core/subscription_constants.dart';

/// Outcome of a purchase flow started by [SubscriptionService.purchasePackage].
enum PurchaseOutcome {
  /// The purchase completed and granted an active entitlement.
  success,

  /// The user dismissed the store sheet, nothing to report.
  cancelled,

  /// The App Store is waiting for an external approval (for example Ask to Buy).
  pending,

  /// Purchases are disabled for the current device or Apple account.
  notAllowed,

  /// The selected store product cannot currently be purchased.
  unavailable,

  /// The purchase failed, or completed without granting an entitlement.
  error,
}

/// Outcome of asking the store to recover purchases made with its current
/// account. Restoring never creates a new charge.
enum RestoreOutcome {
  /// An active ShipRate plan was found and restored.
  restored,

  /// The store request succeeded but no active ShipRate plan was found.
  noActiveSubscription,

  /// RevenueCat or the store could not complete the restore request.
  error,
}

/// Service wrapping the RevenueCat SDK (Plus / Premium subscriptions).
///
/// The SDK is only configured when a real API key is set in
/// [SubscriptionConstants.revenueCatApiKey] and the platform is supported.
/// While it is not configured every method degrades gracefully (false / empty
/// list), so the app keeps working exactly as before.
///
/// Subscription status is mirrored to Firestore (`usuarios/{uid}.subscription`)
/// so Cloud Functions can tell who is a subscriber.
class SubscriptionService {
  SubscriptionService._();

  static bool _configured = false;
  static CustomerInfo? _lastCustomerInfo;

  static final StreamController<CustomerInfo> _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  static StreamSubscription<User?>? _authSubscription;

  // Last plan written to Firestore, used to skip redundant writes.
  static String? _lastSyncedUid;
  static String? _lastSyncedPlan;

  /// True once the RevenueCat SDK has been configured.
  static bool get isConfigured => _configured;

  /// Last [CustomerInfo] received from RevenueCat, if any.
  static CustomerInfo? get lastCustomerInfo => _lastCustomerInfo;

  /// Broadcast stream of subscription status changes.
  static Stream<CustomerInfo> get customerInfoStream =>
      _customerInfoController.stream;

  /// RevenueCat is only configured on the app stores. Web Billing needs a
  /// separate Web Billing API key, which is not set up yet.
  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Configures the RevenueCat SDK. Safe to call more than once.
  static Future<void> init() async {
    if (_configured) return;

    if (!_isSupportedPlatform) {
      debugPrint('SubscriptionService: platform not supported, skipping init');
      return;
    }

    if (!SubscriptionConstants.isApiKeyConfigured) {
      debugPrint(
        'SubscriptionService: RevenueCat API key is still a placeholder, '
        'skipping init',
      );
      return;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final configuration = PurchasesConfiguration(
      SubscriptionConstants.revenueCatApiKey,
    )..appUserID = FirebaseAuth.instance.currentUser?.uid;

    await Purchases.configure(configuration);
    _configured = true;

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _listenAuthChanges();
  }

  /// Whether the user owns a plan that includes the Plus features.
  static Future<bool> isPlusSubscriber() async {
    final customerInfo = await _fetchCustomerInfo();
    if (customerInfo == null) return false;
    return activePlan(customerInfo) != SubscriptionConstants.planNone;
  }

  /// Whether the user owns the Premium plan.
  static Future<bool> isPremiumSubscriber() async {
    final customerInfo = await _fetchCustomerInfo();
    if (customerInfo == null) return false;
    return activePlan(customerInfo) == SubscriptionConstants.planPremium;
  }

  /// Whether the user owns any subscription (plus OR premium).
  static Future<bool> isAnySubscriber() async {
    final customerInfo = await _fetchCustomerInfo();
    if (customerInfo == null) return false;
    return activePlan(customerInfo) != SubscriptionConstants.planNone;
  }

  /// Packages of the current offering configured in RevenueCat.
  static Future<List<Package>> getOfferings() async {
    if (!_configured) return const [];

    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? const [];
    } catch (e) {
      debugPrint('SubscriptionService.getOfferings error: $e');
      return const [];
    }
  }

  /// Runs the purchase flow for [package].
  ///
  /// Returns [PurchaseOutcome.success] when the purchase granted an active
  /// entitlement, [PurchaseOutcome.cancelled] when the user dismissed the store
  /// sheet and [PurchaseOutcome.error] on any failure.
  static Future<PurchaseOutcome> purchasePackage(Package package) async {
    if (!_configured) return PurchaseOutcome.error;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _lastCustomerInfo = result.customerInfo;
      await _syncSubscriptionToFirestore(result.customerInfo);
      final purchasedPlan = _planFromProductIds([
        package.storeProduct.identifier,
      ]);
      final activePlanAfterPurchase = activePlan(result.customerInfo);
      return purchasedPlan != SubscriptionConstants.planNone &&
              activePlanAfterPurchase == purchasedPlan
          ? PurchaseOutcome.success
          : PurchaseOutcome.error;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      debugPrint(
        'SubscriptionService.purchasePackage error '
        '(${errorCode.name}): ${e.message}; details=${e.details}',
      );

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          return PurchaseOutcome.cancelled;
        case PurchasesErrorCode.paymentPendingError:
          return PurchaseOutcome.pending;
        case PurchasesErrorCode.purchaseNotAllowedError:
        case PurchasesErrorCode.insufficientPermissionsError:
          return PurchaseOutcome.notAllowed;
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
        case PurchasesErrorCode.purchaseInvalidError:
          return PurchaseOutcome.unavailable;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          // A sandbox reviewer may reuse an Apple account that already owns
          // the product. Restore it instead of presenting a false failure.
          return await restorePurchases()
              ? PurchaseOutcome.success
              : PurchaseOutcome.error;
        default:
          return PurchaseOutcome.error;
      }
    } catch (e) {
      debugPrint('SubscriptionService.purchasePackage error: $e');
      return PurchaseOutcome.error;
    }
  }

  /// Restores previous purchases for the current store account.
  ///
  /// Returns true when an active entitlement was restored.
  static Future<bool> restorePurchases() async {
    return await restorePurchasesDetailed() == RestoreOutcome.restored;
  }

  /// Restores purchases and distinguishes an empty result from a store error.
  static Future<RestoreOutcome> restorePurchasesDetailed() async {
    if (!_configured) return RestoreOutcome.error;

    try {
      final customerInfo = await Purchases.restorePurchases();
      _lastCustomerInfo = customerInfo;
      await _syncSubscriptionToFirestore(customerInfo);
      return activePlan(customerInfo) != SubscriptionConstants.planNone
          ? RestoreOutcome.restored
          : RestoreOutcome.noActiveSubscription;
    } catch (e) {
      debugPrint('SubscriptionService.restorePurchases error: $e');
      return RestoreOutcome.error;
    }
  }

  /// Refreshes the verified RevenueCat state for screens that resume after
  /// visiting the App Store subscription-management page.
  static Future<CustomerInfo?> refreshCustomerInfo() => _fetchCustomerInfo();

  /// Identifies the RevenueCat user with the Firebase [uid].
  static Future<void> logIn(String uid) async {
    if (!_configured) return;

    try {
      final result = await Purchases.logIn(uid);
      _lastCustomerInfo = result.customerInfo;
      await _syncSubscriptionToFirestore(result.customerInfo);
    } catch (e) {
      debugPrint('SubscriptionService.logIn error: $e');
    }
  }

  /// Switches RevenueCat back to an anonymous user.
  static Future<void> logOut() async {
    if (!_configured) return;

    _lastSyncedUid = null;
    _lastSyncedPlan = null;

    try {
      _lastCustomerInfo = await Purchases.logOut();
    } catch (e) {
      debugPrint('SubscriptionService.logOut error: $e');
    }
  }

  /// Active plan verified from the store product that grants access.
  ///
  /// Product identifiers are intentionally checked before entitlement names.
  /// A Premium product normally grants both the Plus and Premium entitlements,
  /// and a dashboard association mistake can also leave an unexpected
  /// entitlement active. The purchased product is therefore the safest source
  /// for deciding which plan name, benefits and confirmation message to show.
  static String activePlan(CustomerInfo customerInfo) {
    final subscriptionPlan = _planFromProductIds(
      customerInfo.activeSubscriptions,
    );
    if (subscriptionPlan != SubscriptionConstants.planNone) {
      return subscriptionPlan;
    }

    final active = customerInfo.entitlements.active;
    final entitlementProductPlan = _planFromProductIds(
      active.values.map((entitlement) => entitlement.productIdentifier),
    );
    if (entitlementProductPlan != SubscriptionConstants.planNone) {
      return entitlementProductPlan;
    }

    if (active.containsKey(SubscriptionConstants.premiumEntitlement)) {
      return SubscriptionConstants.planPremium;
    }
    if (active.containsKey(SubscriptionConstants.plusEntitlement)) {
      return SubscriptionConstants.planPlus;
    }

    return SubscriptionConstants.planNone;
  }

  static String _planFromProductIds(Iterable<String> productIds) {
    var hasPlus = false;

    for (final productId in productIds) {
      if (_matchesProduct(productId, SubscriptionConstants.premiumMonthly)) {
        return SubscriptionConstants.planPremium;
      }
      if (_matchesProduct(productId, SubscriptionConstants.plusMonthly)) {
        hasPlus = true;
      }
    }

    return hasPlus
        ? SubscriptionConstants.planPlus
        : SubscriptionConstants.planNone;
  }

  static bool _matchesProduct(String productId, String expectedId) =>
      productId == expectedId || productId.startsWith('$expectedId:');

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Keeps the RevenueCat app user id in sync with Firebase Auth.
  static void _listenAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == null) {
        unawaited(logOut());
      } else {
        unawaited(logIn(uid));
      }
    });
  }

  static void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _lastCustomerInfo = customerInfo;

    if (!_customerInfoController.isClosed) {
      _customerInfoController.add(customerInfo);
    }

    unawaited(_syncSubscriptionToFirestore(customerInfo));
  }

  static Future<CustomerInfo?> _fetchCustomerInfo() async {
    if (!_configured) return null;

    try {
      _lastCustomerInfo = await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('SubscriptionService.getCustomerInfo error: $e');
    }
    return _lastCustomerInfo;
  }

  /// Mirrors the current plan to `usuarios/{uid}.subscription` so Cloud
  /// Functions can check subscription status on the backend.
  static Future<void> _syncSubscriptionToFirestore(
    CustomerInfo customerInfo,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final plan = activePlan(customerInfo);
    if (_lastSyncedUid == uid && _lastSyncedPlan == plan) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({
            'subscription': {
              'plan': plan,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));
      _lastSyncedUid = uid;
      _lastSyncedPlan = plan;
    } catch (e) {
      debugPrint('SubscriptionService.syncSubscription error: $e');
    }
  }
}
