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
}

CustomerInfo _customerInfo(List<String> activeSubscriptions) {
  return CustomerInfo(
    const EntitlementInfos({}, {}),
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
