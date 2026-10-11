import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ship_rate/core/subscription_constants.dart';
import 'package:ship_rate/data/services/subscription_service.dart';

void main() {
  group('SubscriptionService.activePlan', () {
    test(
      'uses the active Premium store product as an entitlement fallback',
      () {
        final info = _customerInfo([SubscriptionConstants.premiumMonthly]);

        expect(
          SubscriptionService.activePlan(info),
          SubscriptionConstants.planPremium,
        );
      },
    );

    test('uses the active Plus store product as an entitlement fallback', () {
      final info = _customerInfo([SubscriptionConstants.plusMonthly]);

      expect(
        SubscriptionService.activePlan(info),
        SubscriptionConstants.planPlus,
      );
    });

    test('active Plus product takes priority over a Premium entitlement', () {
      final premiumEntitlement = _entitlement(
        SubscriptionConstants.premiumEntitlement,
        SubscriptionConstants.plusMonthly,
      );
      final info = _customerInfo(
        [SubscriptionConstants.plusMonthly],
        activeEntitlements: {
          SubscriptionConstants.premiumEntitlement: premiumEntitlement,
        },
      );

      expect(
        SubscriptionService.activePlan(info),
        SubscriptionConstants.planPlus,
      );
    });

    test('uses the entitlement source product before its identifier', () {
      final premiumEntitlement = _entitlement(
        SubscriptionConstants.premiumEntitlement,
        SubscriptionConstants.plusMonthly,
      );
      final info = _customerInfo(
        const [],
        activeEntitlements: {
          SubscriptionConstants.premiumEntitlement: premiumEntitlement,
        },
      );

      expect(
        SubscriptionService.activePlan(info),
        SubscriptionConstants.planPlus,
      );
    });

    test('accepts a Google Play base-plan suffix', () {
      final info = _customerInfo([
        '${SubscriptionConstants.premiumMonthly}:monthly',
      ]);

      expect(
        SubscriptionService.activePlan(info),
        SubscriptionConstants.planPremium,
      );
    });

    test('returns none when there is no active entitlement or product', () {
      expect(
        SubscriptionService.activePlan(_customerInfo(const [])),
        SubscriptionConstants.planNone,
      );
    });
  });

  test('restore reports an error when RevenueCat is not configured', () async {
    expect(
      await SubscriptionService.restorePurchasesDetailed(),
      RestoreOutcome.error,
    );
  });
}

CustomerInfo _customerInfo(
  List<String> activeSubscriptions, {
  Map<String, EntitlementInfo> activeEntitlements = const {},
}) {
  return CustomerInfo(
    EntitlementInfos(activeEntitlements, activeEntitlements),
    const {},
    activeSubscriptions,
    const [],
    const [],
    '2026-01-01T00:00:00Z',
    'test-user',
    const {},
    '2026-01-01T00:00:00Z',
  );
}

EntitlementInfo _entitlement(String identifier, String productIdentifier) {
  return EntitlementInfo(
    identifier,
    true,
    true,
    '2026-01-01T00:00:00Z',
    '2026-01-01T00:00:00Z',
    productIdentifier,
    true,
  );
}
