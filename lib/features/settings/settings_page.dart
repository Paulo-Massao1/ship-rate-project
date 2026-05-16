import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ship_rate/l10n/app_localizations.dart';

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

  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _loading = true;
  bool _permissionGranted = true;

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

    setState(() {
      _pushEnabled = data?['pushNotifications'] ?? true;
      _emailEnabled = data?['emailNotifications'] ?? true;
      _permissionGranted = granted;
      _loading = false;
    });
  }

  Future<void> _togglePush(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (value && !_permissionGranted) {
      final granted = await NotificationService.requestPermissionAndEnable();
      if (!mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissao negada. Ative as notificacoes nas configuracoes do navegador/sistema.',
            ),
            backgroundColor: Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() => _permissionGranted = true);
    }

    setState(() => _pushEnabled = value);

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

      setState(() => _pushEnabled = true);
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set(
        {'pushNotifications': true},
        SetOptions(merge: true),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permissao negada. Ative as notificacoes nas configuracoes do navegador/sistema.',
          ),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  _buildToggleTile(
                    icon: Icons.notifications_active,
                    label: l10n.pushNotifications,
                    value: _pushEnabled,
                    onChanged: _togglePush,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleTile(
                    icon: Icons.email_outlined,
                    label: l10n.emailNotifications,
                    value: _emailEnabled,
                    onChanged: _toggleEmail,
                  ),
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
                  'Ative as notificacoes para receber alertas quando novos '
                  'registros de profundidade forem adicionados.',
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
              child: const Text(
                'Ativar notificacoes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
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
}
