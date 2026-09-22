// lib/features/maneuvers/maneuvers_page.dart

import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../core/subscription_constants.dart';
import '../../shared/widgets/subscription_gate.dart';

/// Placeholder for the Maneuvers module, gated behind the Plus plan.
///
/// The module itself is not implemented yet: the gate is already wired, so the
/// real content only has to replace [_buildPlaceholder].
class ManeuversPage extends StatelessWidget {
  const ManeuversPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
          ),
        ),
        // Plus already unlocks the module, Premium includes Plus.
        child: SubscriptionGate(
          requiredPlan: SubscriptionConstants.planPlus,
          featureDescription: l10n.plusFeature2,
          child: _buildPlaceholder(l10n),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return AppBar(
      leadingWidth: 96,
      leading: _buildBackButton(context, l10n),
      title: Text(
        l10n.maneuvers,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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

  Widget _buildBackButton(BuildContext context, AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () => Navigator.maybePop(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.only(left: 8, right: 6),
        minimumSize: const Size(0, kToolbarHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.arrow_back_ios_new, size: 15),
      label: Text(
        l10n.back,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPlaceholder(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.anchor, color: Color(0xFFFFB74D), size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.plusFeature2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
