import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../data/services/subscription_service.dart';

/// Subscription page offering the two ShipRate Pro plans.
///
/// Premium is presented first as the recommended plan, Plus below it. The
/// buttons run the RevenueCat purchase flow through [SubscriptionService] and
/// adapt to the plan the user already owns.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const _premiumColor = Color(0xFF64B5F6);
  static const _plusColor = Color(0xFFFFB74D);
  static const _darkNavy = Color(0xFF0A1628);

  // Prices shown while the store has no package to read the real price from.
  static const _premiumFallbackPrice = 'R\$ 18,99';
  static const _plusFallbackPrice = 'R\$ 15,99';

  StreamSubscription<CustomerInfo>? _customerInfoSubscription;

  List<Package> _packages = const [];
  String _activePlan = SubscriptionConstants.planNone;

  /// Plan whose purchase flow is running, null when no purchase is in flight.
  String? _purchasingPlan;
  bool _restoring = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _customerInfoSubscription =
        SubscriptionService.customerInfoStream.listen(_onCustomerInfoUpdated);
    _loadSubscriptionState();
  }

  @override
  void dispose() {
    _customerInfoSubscription?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // DATA
  // ===========================================================================

  Future<void> _loadSubscriptionState() async {
    final packages = await SubscriptionService.getOfferings();
    final plan = await _fetchActivePlan();
    if (!mounted) return;

    setState(() {
      _packages = packages;
      _activePlan = plan;
      _loading = false;
    });
  }

  /// Highest plan currently granted to the user, refreshed from RevenueCat.
  Future<String> _fetchActivePlan() async {
    await SubscriptionService.isAnySubscriber();
    final customerInfo = SubscriptionService.lastCustomerInfo;
    if (customerInfo == null) return SubscriptionConstants.planNone;
    return SubscriptionService.activePlan(customerInfo);
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    if (!mounted) return;
    setState(() => _activePlan = SubscriptionService.activePlan(customerInfo));
  }

  /// Package of the current offering that sells [plan], when the store
  /// returned it.
  Package? _packageFor(String plan) {
    final productId = plan == SubscriptionConstants.planPremium
        ? SubscriptionConstants.premiumMonthly
        : SubscriptionConstants.plusMonthly;

    for (final package in _packages) {
      final identifier = package.storeProduct.identifier;
      // Google Play appends the base plan id to the product id.
      if (identifier == productId || identifier.startsWith('$productId:')) {
        return package;
      }
    }
    return null;
  }

  /// Store price for [plan], falling back to the catalogue price.
  String _priceFor(String plan) {
    final package = _packageFor(plan);
    if (package != null) return package.storeProduct.priceString;

    return plan == SubscriptionConstants.planPremium
        ? _premiumFallbackPrice
        : _plusFallbackPrice;
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _subscribe(String plan) async {
    if (_loading || _restoring || _purchasingPlan != null) return;

    final l10n = AppLocalizations.of(context)!;
    final package = _packageFor(plan);
    if (package == null) {
      _showSnackBar(l10n.subscriptionError, isError: true);
      return;
    }

    setState(() => _purchasingPlan = plan);
    final purchased = await SubscriptionService.purchasePackage(package);
    if (!mounted) return;
    setState(() => _purchasingPlan = null);

    if (!purchased) {
      _showSnackBar(l10n.subscriptionError, isError: true);
      return;
    }

    _showSnackBar(l10n.subscriptionSuccess);
    Navigator.pop(context);
  }

  Future<void> _restorePurchases() async {
    if (_restoring || _purchasingPlan != null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _restoring = true);
    final restored = await SubscriptionService.restorePurchases();
    if (!mounted) return;

    final customerInfo = SubscriptionService.lastCustomerInfo;
    setState(() {
      _restoring = false;
      if (customerInfo != null) {
        _activePlan = SubscriptionService.activePlan(customerInfo);
      }
    });

    _showSnackBar(
      restored ? l10n.subscriptionSuccess : l10n.subscriptionError,
      isError: !restored,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(
                    20, Navigator.canPop(context) ? 68 : 24, 20, 32,
                  ),
                  children: [
                    _buildHeaderIcon(),
                    const SizedBox(height: 16),
                    _buildDescription(l10n),
                    const SizedBox(height: 28),
                    _buildPremiumCard(l10n),
                    const SizedBox(height: 16),
                    _buildPlusCard(l10n),
                    const SizedBox(height: 24),
                    _buildFooter(l10n),
                  ],
                ),
                if (Navigator.canPop(context)) _buildPageBackButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        l10n.supportShipRate,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 16,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black54,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0D2137)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildPageBackButton(AppLocalizations l10n) {
    return Positioned(
      top: 8,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xCC0A1628),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 13,
                  color: Color(0xCCFFFFFF),
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.back,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0x1FFFB74D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.star, color: _plusColor, size: 28),
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.subscriptionDescription,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
    );
  }

  // ===========================================================================
  // PLAN CARDS
  // ===========================================================================

  Widget _buildPremiumCard(AppLocalizations l10n) {
    final isActive = _activePlan == SubscriptionConstants.planPremium;
    final isUpgrade = _activePlan == SubscriptionConstants.planPlus;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0F64B5F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x6664B5F6), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecommendedBadge(l10n),
          const SizedBox(height: 14),
          _buildPlanHeader(
            l10n: l10n,
            title: l10n.premiumPlan,
            subtitle: l10n.premiumSubtitle,
            price: _priceFor(SubscriptionConstants.planPremium),
            accentColor: _premiumColor,
            showActiveBadge: isActive,
          ),
          const SizedBox(height: 14),
          const _PlanDivider(color: Color(0x2664B5F6)),
          const SizedBox(height: 14),
          _buildFeature(
            icon: Icons.check,
            color: _premiumColor,
            label: l10n.premiumFeature1,
          ),
          const SizedBox(height: 10),
          _buildFeature(
            icon: Icons.show_chart,
            color: _premiumColor,
            label: l10n.premiumFeature2,
          ),
          const SizedBox(height: 18),
          _buildPlanButton(
            label: isActive
                ? l10n.currentPlan
                : isUpgrade
                    ? l10n.upgradePlan
                    : l10n.subscribePremium,
            enabled: !_loading && !isActive,
            loading: _loading ||
                _purchasingPlan == SubscriptionConstants.planPremium,
            filled: true,
            color: _premiumColor,
            onPressed: () => _subscribe(SubscriptionConstants.planPremium),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusCard(AppLocalizations l10n) {
    final isActive = _activePlan == SubscriptionConstants.planPlus;
    // Premium already includes Plus, so buying Plus on top of it is blocked.
    final isDowngrade = _activePlan == SubscriptionConstants.planPremium;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0AFFB74D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFB74D), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlanHeader(
            l10n: l10n,
            title: l10n.plusPlan,
            price: _priceFor(SubscriptionConstants.planPlus),
            accentColor: _plusColor,
            showActiveBadge: isActive,
          ),
          const SizedBox(height: 14),
          const _PlanDivider(color: Color(0x1FFFB74D)),
          const SizedBox(height: 14),
          _buildFeature(
            icon: Icons.description,
            color: _plusColor,
            label: l10n.plusFeature1,
          ),
          const SizedBox(height: 10),
          _buildFeature(
            icon: Icons.anchor,
            color: _plusColor,
            label: l10n.plusFeature2,
          ),
          const SizedBox(height: 18),
          _buildPlanButton(
            label: isActive ? l10n.currentPlan : l10n.subscribePlus,
            enabled: !_loading && !isActive && !isDowngrade,
            loading:
                _loading || _purchasingPlan == SubscriptionConstants.planPlus,
            filled: false,
            color: _plusColor,
            onPressed: () => _subscribe(SubscriptionConstants.planPlus),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBadge(AppLocalizations l10n) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _premiumColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          l10n.recommended,
          style: const TextStyle(
            color: _darkNavy,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader({
    required AppLocalizations l10n,
    required String title,
    required String price,
    required Color accentColor,
    required bool showActiveBadge,
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showActiveBadge) ...[
                    const SizedBox(width: 8),
                    _buildActiveBadge(l10n, accentColor),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.perMonth,
              style: const TextStyle(
                color: Color(0x66FFFFFF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveBadge(AppLocalizations l10n, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        l10n.activeBadge,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanButton({
    required String label,
    required bool enabled,
    required bool loading,
    required bool filled,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final foreground = filled ? _darkNavy : color;

    return Opacity(
      opacity: enabled || loading ? 1.0 : 0.45,
      child: Material(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled && !loading ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: filled ? null : Border.all(color: color),
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  : Text(
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

  Widget _buildFooter(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.cancelAnytime,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 11),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed:
              _restoring || _purchasingPlan != null ? null : _restorePurchases,
          child: _restoring
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _plusColor,
                  ),
                )
              : Text(
                  l10n.restorePurchases,
                  style: const TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

/// Thin separator used between a plan header and its feature list.
class _PlanDivider extends StatelessWidget {
  final Color color;

  const _PlanDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: color);
  }
}
