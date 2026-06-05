import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

import '../../app/auth_gate.dart';
import '../../controllers/crossing_controller.dart';
import '../../controllers/nav_safety_controller.dart';
import '../../controllers/rating_controller.dart';
import '../../data/services/notification_service.dart';

/// Settings page with notification preference toggles.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _pushNavSafetyEnabled = true;
  bool _pushRatingsEnabled = true;
  bool _emailEnabled = true;
  bool _loading = true;
  bool _permissionGranted = true;
  bool _deletingAccount = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // ===========================================================================
  // METHODS
  // ===========================================================================

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final results = await Future.wait([
      FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      NotificationService.isPermissionGranted(),
    ]);

    if (!mounted) return;

    final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final granted = results[1] as bool;
    final data = doc.data();

    final pushNotifications = data?['pushNotifications'] ?? true;
    final pushNavSafety = data?['pushNavSafety'] ?? pushNotifications;
    final emailEnabled = data?['emailNotifications'] ?? true;

    if (data != null && !data.containsKey('pushNavSafety') && doc.exists) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
          {'pushNavSafety': pushNotifications},
          SetOptions(merge: true),
        );
      }
    }

    setState(() {
      _pushNavSafetyEnabled = pushNavSafety as bool;
      _pushRatingsEnabled = pushNotifications as bool;
      _emailEnabled = emailEnabled as bool;
      _permissionGranted = granted;
      _loading = false;
    });
  }

  Future<bool> _ensurePermission() async {
    if (_permissionGranted) return true;

    final granted = await NotificationService.requestPermissionAndEnable();
    if (!mounted) return false;

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.permissionDeniedSettings,
          ),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    setState(() => _permissionGranted = true);
    return true;
  }

  Future<void> _togglePushNavSafety(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (value && !await _ensurePermission()) return;

    setState(() => _pushNavSafetyEnabled = value);

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'pushNavSafety': value},
      SetOptions(merge: true),
    );
  }

  Future<void> _togglePushRatings(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (value && !await _ensurePermission()) return;

    setState(() => _pushRatingsEnabled = value);

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'pushNotifications': value},
      SetOptions(merge: true),
    );
  }

  Future<void> _toggleEmail(bool value) async {
    setState(() => _emailEnabled = value);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
      {'emailNotifications': value},
      SetOptions(merge: true),
    );
  }

  Future<void> _handleEnableNotifications() async {
    final granted = await NotificationService.requestPermissionAndEnable();
    if (!mounted) return;

    if (granted) {
      setState(() => _permissionGranted = true);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      setState(() {
        _pushNavSafetyEnabled = true;
        _pushRatingsEnabled = true;
      });
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        {'pushNotifications': true, 'pushNavSafety': true},
        SetOptions(merge: true),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.permissionDeniedSettings,
          ),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAccountTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.deleteAccountBody,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.deleteAccountCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final isEmailProvider = user?.providerData.any(
          (info) => info.providerId == 'password',
        ) ??
        false;

    if (isEmailProvider) {
      await _requestPasswordForDeletion();
    } else {
      await _requestTypeDeleteConfirmation();
    }
  }

  Future<void> _requestPasswordForDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAccountTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteAccountPassword,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              autofocus: true,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.deleteAccountPasswordHint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0x1AFFFFFF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEF5350)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.deleteAccountCancel),
          ),
          FilledButton(
            onPressed: () {
              final password = passwordController.text;
              if (password.isNotEmpty) Navigator.pop(dialogContext, password);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    passwordController.dispose();
    if (password == null || password.isEmpty || !mounted) return;
    await _deleteAccount(password: password);
  }

  Future<void> _requestTypeDeleteConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAccountTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteAccountTypeConfirm,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.trim().toUpperCase() == 'DELETE') {
                  Navigator.pop(dialogContext, true);
                }
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.deleteAccountTypeHint,
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0x1AFFFFFF),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEF5350)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.deleteAccountCancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                Navigator.pop(dialogContext, true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );

    controller.dispose();
    if (confirmed != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount({String? password}) async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showDeleteAccountError(l10n.deleteAccountError);
      return;
    }

    setState(() => _deletingAccount = true);

    try {
      if (password != null) {
        final email = user.email;
        if (email == null || email.isEmpty) {
          _showDeleteAccountError(l10n.deleteAccountError);
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid);
      final userDoc = await userDocRef.get();
      final backupData = userDoc.data();

      await userDocRef.delete();

      try {
        await user.delete();
      } catch (_) {
        if (backupData != null) {
          await userDocRef.set(backupData);
        }
        rethrow;
      }

      NavSafetyController.clearAllCaches();
      CrossingController.clearCache();
      RatingController.clearAllCaches();

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.deleteAccountSuccess),
          backgroundColor: const Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-login-credentials' =>
          l10n.deleteAccountWrongPassword,
        'network-request-failed' => l10n.deleteAccountNetworkError,
        _ => l10n.deleteAccountError,
      };
      _showDeleteAccountError(message);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      final message = error.code == 'unavailable'
          ? l10n.deleteAccountNetworkError
          : l10n.deleteAccountError;
      _showDeleteAccountError(message);
    } catch (_) {
      if (!mounted) return;
      _showDeleteAccountError(l10n.deleteAccountError);
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  void _showDeleteAccountError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!_permissionGranted) _buildNotificationBanner(),
                  _buildSectionHeader(
                    icon: Icons.notifications_active,
                    label: l10n.pushNotifications,
                  ),
                  const SizedBox(height: 8),
                  _buildToggleTile(
                    icon: Icons.sailing_outlined,
                    label: l10n.pushNavSafetyLabel,
                    value: _pushNavSafetyEnabled,
                    onChanged: _togglePushNavSafety,
                  ),
                  const SizedBox(height: 8),
                  _buildToggleTile(
                    icon: Icons.star_outline,
                    label: l10n.pushRatingsLabel,
                    value: _pushRatingsEnabled,
                    onChanged: _togglePushRatings,
                  ),
                  const SizedBox(height: 16),
                  _buildToggleTile(
                    icon: Icons.email_outlined,
                    label: l10n.emailNotifications,
                    value: _emailEnabled,
                    onChanged: _toggleEmail,
                  ),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0x1AFFFFFF)),
                  const SizedBox(height: 16),
                  _buildDeleteAccountButton(l10n),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.settings,
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

  Widget _buildNotificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A26A69A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4026A69A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF26A69A),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.enableNotificationsDepthPrompt,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleEnableNotifications,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF26A69A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.enableNotificationsButtonLabel,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64B5F6), size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64B5F6),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A64B5F6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF26A69A),
            activeTrackColor: const Color(0x6626A69A),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton(AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: _deletingAccount ? null : _confirmDeleteAccount,
      icon: _deletingAccount
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFEF5350),
              ),
            )
          : const Icon(Icons.delete_outline),
      label: Text(l10n.deleteAccount),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF5350),
        disabledForegroundColor: const Color(0x80EF5350),
        side: const BorderSide(color: Color(0x66EF5350)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
