import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

/// Audit script to compare usuarios against authorized_emails whitelist.
/// READ-ONLY — does NOT modify or delete anything.
/// Run with: flutter run -d chrome -t lib/scripts/audit_usuarios.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AuditUsuariosApp());
}

class AuditUsuariosApp extends StatelessWidget {
  const AuditUsuariosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate - Audit Usuarios',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AuditUsuariosPage(),
    );
  }
}

// PAGE

class AuditUsuariosPage extends StatefulWidget {
  const AuditUsuariosPage({super.key});

  @override
  State<AuditUsuariosPage> createState() => _AuditUsuariosPageState();
}

class _AuditUsuariosPageState extends State<AuditUsuariosPage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // AUDIT STATE
  final _logs = <String>[];
  bool _auditing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // AUTH METHODS

  Future<void> _login() async {
    setState(() {
      _loggingIn = true;
      _loginError = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() => _user = credential.user);
    } on FirebaseAuthException catch (e) {
      setState(() => _loginError = e.message ?? 'Authentication failed.');
    } catch (e) {
      setState(() => _loginError = e.toString());
    }

    setState(() => _loggingIn = false);
  }

  // AUDIT METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _audit() async {
    setState(() {
      _auditing = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('Auditing usuarios vs authorized_emails...');
      _log('Logged in as: ${_user?.email}');
      _log('');

      // Fetch all usuarios
      final usuariosSnap = await firestore.collection('usuarios').get();
      final usuarioEmails = <String>{};
      for (final doc in usuariosSnap.docs) {
        final email = (doc.data()['email'] as String?)?.toLowerCase().trim();
        if (email != null && email.isNotEmpty) {
          usuarioEmails.add(email);
        }
      }

      // Fetch all authorized_emails
      final authSnap = await firestore.collection('authorized_emails').get();
      final authorizedEmails = <String>{};
      for (final doc in authSnap.docs) {
        final email = (doc.data()['email'] as String?)?.toLowerCase().trim();
        if (email != null && email.isNotEmpty) {
          authorizedEmails.add(email);
        }
      }

      _log('Total usuarios: ${usuarioEmails.length}');
      _log('Total authorized_emails: ${authorizedEmails.length}');
      _log('');

      // Compare
      final matched = usuarioEmails.intersection(authorizedEmails);
      final notInWhitelist = usuarioEmails.difference(authorizedEmails);
      final whitelistOnly = authorizedEmails.difference(usuarioEmails);

      const divider = '==================================================';

      // Print MATCHED
      _log(divider);
      _log('MATCHED (${matched.length}) — usuarios in whitelist');
      _log(divider);
      for (final email in matched.toList()..sort()) {
        _log('  $email');
      }
      _log('');

      // Print NOT IN WHITELIST
      _log(divider);
      _log('NOT IN WHITELIST (${notInWhitelist.length}) — review needed');
      _log(divider);
      for (final email in notInWhitelist.toList()..sort()) {
        _log('  $email');
      }
      _log('');

      // Print WHITELIST ONLY
      _log(divider);
      _log('WHITELIST ONLY (${whitelistOnly.length}) — not registered yet');
      _log(divider);
      for (final email in whitelistOnly.toList()..sort()) {
        _log('  $email');
      }
      _log('');

      // Summary
      _log(divider);
      _log('SUMMARY');
      _log(divider);
      _log('  Matched:          ${matched.length}');
      _log('  Not in whitelist: ${notInWhitelist.length}');
      _log('  Whitelist only:   ${whitelistOnly.length}');
      _log(divider);
    } catch (e) {
      _log('');
      _log('ERROR: $e');
    }

    setState(() => _auditing = false);
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShipRate - Audit Usuarios')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user == null ? _buildLoginForm() : _buildAuditPanel(),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Login to audit usuarios',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              onSubmitted: (_) => _login(),
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 12),
              Text(
                _loginError!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loggingIn ? null : _login,
                child: _loggingIn
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _auditing ? null : _audit,
          icon: _auditing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_auditing ? 'Auditing...' : 'Run Audit'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _logs.isEmpty
                    ? 'Press "Run Audit" to compare usuarios vs authorized_emails...'
                    : _logs.join('\n'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
