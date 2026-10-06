// lib/shared/widgets/subscription_gate.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/constants.dart';
import '../../core/subscription_constants.dart';
import '../../data/services/subscription_service.dart';
import '../../features/subscription/subscription_page.dart';

/// Gates [child] behind a subscription plan.
///
/// Subscribers of [requiredPlan] (or of a plan that includes it) see [child]
/// exactly as if the gate was not there. Everyone else gets a locked
/// placeholder with a button that opens the [SubscriptionPage].
///
/// The gate listens to [SubscriptionService.customerInfoStream], so it opens
/// by itself as soon as a purchase is confirmed.
///
/// Colors follow the dark navy palette used by the gated screens.
class SubscriptionGate extends StatefulWidget {
  /// Plan needed to unlock [child]: [SubscriptionConstants.planPlus] or
  /// [SubscriptionConstants.planPremium].
  final String requiredPlan;

  /// Short sentence describing what the plan offers on this screen.
  final String featureDescription;

  /// Content shown once the user owns the required plan.
  final Widget child;

  const SubscriptionGate({
    super.key,
    required this.requiredPlan,
    required this.featureDescription,
    required this.child,
  });

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  static const _premiumColor = Color(0xFF64B5F6);
  static const _plusColor = Color(0xFFFFB74D);
  static const _darkNavy = Color(0xFF0A1628);

  StreamSubscription<CustomerInfo>? _customerInfoSubscription;

  /// Null while the plan is still being checked.
  bool? _hasAccess;

  bool get _isPremiumFeature =>
      widget.requiredPlan == SubscriptionConstants.planPremium;

  Color get _accentColor => _isPremiumFeature ? _premiumColor : _plusColor;

  /// True for the dev accounts listed in [AppConstants.devBypassUids], which
  /// unlock every gated feature without owning a plan.
  bool get _hasDevBypass {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && AppConstants.devBypassUids.contains(uid);
  }

  @override
  void initState() {
    super.initState();
    // Dev accounts skip the paywall entirely: no plan check, no upsell sheet.
    if (_hasDevBypass) {
      _hasAccess = true;
      return;
    }

    _customerInfoSubscription =
        SubscriptionService.customerInfoStream.listen(_onCustomerInfoUpdated);
    _checkAccess();
  }

  @override
  void dispose() {
    _customerInfoSubscription?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // ACCESS
  // ===========================================================================

  /// Refreshes the plan from RevenueCat before rendering the gated content.
  Future<void> _checkAccess() async {
    // Refreshes the cached CustomerInfo before reading the active plan.
    await SubscriptionService.isAnySubscriber();
    final granted = _grantsAccess(SubscriptionService.lastCustomerInfo);
    if (!mounted) return;

    setState(() => _hasAccess = granted);
  }

  /// True when the plan granted by [customerInfo] includes [requiredPlan].
  /// Premium includes everything Plus unlocks, the opposite is not true.
  bool _grantsAccess(CustomerInfo? customerInfo) {
    if (customerInfo == null) return false;

    final plan = SubscriptionService.activePlan(customerInfo);
    if (plan == SubscriptionConstants.planPremium) return true;

    return plan == SubscriptionConstants.planPlus && !_isPremiumFeature;
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    final granted = _grantsAccess(customerInfo);
    if (!mounted || granted == _hasAccess) return;

    setState(() => _hasAccess = granted);
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Opens the plans page from the locked view.
  Future<void> _openSubscriptionPage() async {
    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );
    if (!mounted) return;

    // Back from the plans page: refresh access without interrupting the user.
    await _checkAccess();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final hasAccess = _hasAccess;

    if (hasAccess == null) {
      return Center(child: CircularProgressIndicator(color: _accentColor));
    }

    return hasAccess ? widget.child : _buildLockedView();
  }

  Widget _buildLockedView() {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LockBadge(color: _accentColor),
                const SizedBox(height: 20),
                Text(
                  l10n.exclusiveFeature,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.featureDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xBFFFFFFF),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.subscriptionRequired(
                    _isPremiumFeature ? l10n.premiumPlan : l10n.plusPlan,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                _ViewPlansButton(
                  label: l10n.viewPlans,
                  color: _accentColor,
                  foreground: _darkNavy,
                  onPressed: _openSubscriptionPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded lock icon shown on the locked view.
class _LockBadge extends StatelessWidget {
  final Color color;

  const _LockBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.lock_outline, color: color, size: 28),
    );
  }
}

/// Filled button that takes the user to the [SubscriptionPage].
class _ViewPlansButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;

  const _ViewPlansButton({
    required this.label,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
