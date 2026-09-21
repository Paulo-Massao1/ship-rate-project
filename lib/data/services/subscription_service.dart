import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/constants.dart';
import '../../core/subscription_constants.dart';

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

    final configuration =
        PurchasesConfiguration(SubscriptionConstants.revenueCatApiKey)
          ..appUserID = FirebaseAuth.instance.currentUser?.uid;

    await Purchases.configure(configuration);
    _configured = true;

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _listenAuthChanges();
  }

  /// Whether the user owns the `plus` entitlement.
  static Future<bool> isPlusSubscriber() =>
      _hasEntitlement(SubscriptionConstants.plusEntitlement);

  /// Whether the user owns the `premium` entitlement.
  static Future<bool> isPremiumSubscriber() =>
      _hasEntitlement(SubscriptionConstants.premiumEntitlement);

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
  /// Returns true when the purchase granted an active entitlement, false when
  /// the user cancels or the purchase fails.
  static Future<bool> purchasePackage(Package package) async {
    if (!_configured) return false;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _lastCustomerInfo = result.customerInfo;
      await _syncSubscriptionToFirestore(result.customerInfo);
      return activePlan(result.customerInfo) != SubscriptionConstants.planNone;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) !=
          PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('SubscriptionService.purchasePackage error: $e');
      }
      return false;
    } catch (e) {
      debugPrint('SubscriptionService.purchasePackage error: $e');
      return false;
    }
  }

  /// Restores previous purchases for the current store account.
  ///
  /// Returns true when an active entitlement was restored.
  static Future<bool> restorePurchases() async {
    if (!_configured) return false;

    try {
      final customerInfo = await Purchases.restorePurchases();
      _lastCustomerInfo = customerInfo;
      await _syncSubscriptionToFirestore(customerInfo);
      return activePlan(customerInfo) != SubscriptionConstants.planNone;
    } catch (e) {
      debugPrint('SubscriptionService.restorePurchases error: $e');
      return false;
    }
  }

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

  /// Highest plan granted by the active entitlements of [customerInfo].
  static String activePlan(CustomerInfo customerInfo) {
    final active = customerInfo.entitlements.active;

    if (active.containsKey(SubscriptionConstants.premiumEntitlement)) {
      return SubscriptionConstants.planPremium;
    }
    if (active.containsKey(SubscriptionConstants.plusEntitlement)) {
      return SubscriptionConstants.planPlus;
    }
    return SubscriptionConstants.planNone;
  }

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

  static Future<bool> _hasEntitlement(String entitlementId) async {
    final customerInfo = await _fetchCustomerInfo();
    return customerInfo?.entitlements.active.containsKey(entitlementId) ??
        false;
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
          .set(
        {
          'subscription': {
            'plan': plan,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
      _lastSyncedUid = uid;
      _lastSyncedPlan = plan;
    } catch (e) {
      debugPrint('SubscriptionService.syncSubscription error: $e');
    }
  }
}
