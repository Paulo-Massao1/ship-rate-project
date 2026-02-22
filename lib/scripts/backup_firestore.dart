import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../firebase_options.dart';

/// Backup script for all Firestore data (READ-ONLY).
/// Run with: flutter run -d chrome -t lib/scripts/backup_firestore.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BackupApp());
}

class BackupApp extends StatelessWidget {
  const BackupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate Backup',
      theme: ThemeData.dark(useMaterial3: true),
      home: const BackupPage(),
    );
  }
}

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // BACKUP STATE
  final _logs = <String>[];
  bool _running = false;
  bool _done = false;

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

  // BACKUP METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _runBackup() async {
    setState(() {
      _running = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('Starting Firestore backup...');
      _log('Logged in as: ${_user?.email}');
      _log('');

      // Read all ships from "navios" collection
      final shipsSnapshot = await firestore.collection('navios').get();
      final totalShips = shipsSnapshot.docs.length;
      _log('Found $totalShips ships.');

      var totalRatings = 0;
      final shipsList = <Map<String, dynamic>>[];

      for (final shipDoc in shipsSnapshot.docs) {
        // Read all ratings from "avaliacoes" subcollection
        final ratingsSnapshot = await firestore
            .collection('navios')
            .doc(shipDoc.id)
            .collection('avaliacoes')
            .get();

        final ratingsList = ratingsSnapshot.docs.map((ratingDoc) {
          return {
            'id': ratingDoc.id,
            'data': _sanitizeData(ratingDoc.data()),
          };
        }).toList();

        totalRatings += ratingsList.length;

        shipsList.add({
          'id': shipDoc.id,
          'data': _sanitizeData(shipDoc.data()),
          'avaliacoes': ratingsList,
        });

        _log(
          '  ${shipDoc.data()['nome'] ?? shipDoc.id}: '
          '${ratingsList.length} ratings',
        );
      }

      // Build backup object
      final backup = {
        'timestamp': DateTime.now().toIso8601String(),
        'ships': shipsList,
      };

      // Generate filename with timestamp
      final now = DateTime.now();
      final filename = 'backup_'
          '${now.year}${_pad(now.month)}${_pad(now.day)}_'
          '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}'
          '.json';

      // Trigger browser download
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      _log('');
      _log('=== Backup Summary ===');
      _log('Total ships:   $totalShips');
      _log('Total ratings: $totalRatings');
      _log('File:          $filename (downloaded)');
      _log('======================');
    } catch (e) {
      _log('ERROR: $e');
    }

    setState(() {
      _running = false;
      _done = true;
    });
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShipRate - Firestore Backup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user == null ? _buildLoginForm() : _buildBackupPanel(),
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
              'Login to access backup',
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

  Widget _buildBackupPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _running ? null : _runBackup,
          icon: _running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_done ? Icons.refresh : Icons.download),
          label: Text(_running
              ? 'Backing up...'
              : _done
                  ? 'Run Again'
                  : 'Start Backup'),
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
                    ? 'Press "Start Backup" to begin...'
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

/// Pad single digit numbers with leading zero.
String _pad(int value) => value.toString().padLeft(2, '0');

/// Convert Firestore Timestamps to ISO strings for JSON serialization.
Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
  return data.map((key, value) {
    if (value is Timestamp) {
      return MapEntry(key, value.toDate().toIso8601String());
    }
    if (value is Map<String, dynamic>) {
      return MapEntry(key, _sanitizeData(value));
    }
    if (value is List) {
      return MapEntry(
        key,
        value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map<String, dynamic>) return _sanitizeData(item);
          return item;
        }).toList(),
      );
    }
    return MapEntry(key, value);
  });
}
