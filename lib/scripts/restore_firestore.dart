import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../firebase_options.dart';

/// Restore script for Firestore data from backup JSON.
/// Run with: flutter run -d chrome -t lib/scripts/restore_firestore.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RestoreApp());
}

class RestoreApp extends StatelessWidget {
  const RestoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate Restore',
      theme: ThemeData.dark(useMaterial3: true),
      home: const RestorePage(),
    );
  }
}

class RestorePage extends StatefulWidget {
  const RestorePage({super.key});

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // RESTORE STATE
  final _logs = <String>[];
  bool _running = false;
  bool _done = false;
  Map<String, dynamic>? _backupData;
  String? _fileName;

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

  // FILE METHODS

  Future<void> _pickFile() async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoadEnd.first;

    try {
      final content = reader.result as String;
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup structure
      if (!data.containsKey('ships') || data['ships'] is! List) {
        setState(() => _logs
          ..clear()
          ..add('ERROR: Invalid backup file. Missing "ships" array.'));
        return;
      }

      final ships = data['ships'] as List;
      var totalRatings = 0;
      for (final ship in ships) {
        final avaliacoes = ship['avaliacoes'] as List? ?? [];
        totalRatings += avaliacoes.length;
      }

      setState(() {
        _backupData = data;
        _fileName = file.name;
        _logs
          ..clear()
          ..add('File loaded: ${file.name}')
          ..add('Backup timestamp: ${data['timestamp'] ?? 'unknown'}')
          ..add('Ships: ${ships.length}')
          ..add('Ratings: $totalRatings')
          ..add('')
          ..add('Press "Restore" to write this data to Firestore.');
      });
    } catch (e) {
      setState(() => _logs
        ..clear()
        ..add('ERROR: Failed to parse JSON file.')
        ..add(e.toString()));
    }
  }

  // RESTORE METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _runRestore() async {
    if (_backupData == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text(
          'This will write all data from "$_fileName" to Firestore, '
          'overwriting any existing documents with the same IDs.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _running = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final ships = _backupData!['ships'] as List;

      _log('Starting Firestore restore...');
      _log('Logged in as: ${_user?.email}');
      _log('Source file: $_fileName');
      _log('');

      var totalShips = 0;
      var totalRatings = 0;

      for (final ship in ships) {
        final shipId = ship['id'] as String;
        final shipData = Map<String, dynamic>.from(ship['data'] as Map);
        final avaliacoes = ship['avaliacoes'] as List? ?? [];

        // Restore ship document with original ID
        await firestore.collection('navios').doc(shipId).set(shipData);
        totalShips++;

        // Restore all ratings in subcollection
        for (final rating in avaliacoes) {
          final ratingId = rating['id'] as String;
          final ratingData = Map<String, dynamic>.from(rating['data'] as Map);

          await firestore
              .collection('navios')
              .doc(shipId)
              .collection('avaliacoes')
              .doc(ratingId)
              .set(ratingData);
          totalRatings++;
        }

        _log(
          '  ${shipData['nome'] ?? shipId}: '
          '${avaliacoes.length} ratings restored',
        );
      }

      _log('');
      _log('=== Restore Summary ===');
      _log('Total ships:   $totalShips');
      _log('Total ratings: $totalRatings');
      _log('Status:        COMPLETE');
      _log('=======================');
    } catch (e) {
      _log('');
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
      appBar: AppBar(
        title: const Text('ShipRate - Firestore Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user == null ? _buildLoginForm() : _buildRestorePanel(),
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
              'Login to access restore',
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

  Widget _buildRestorePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _running ? null : _pickFile,
              icon: const Icon(Icons.file_open),
              label: Text(_backupData != null
                  ? 'Change File'
                  : 'Select Backup File'),
            ),
            const SizedBox(width: 12),
            if (_backupData != null)
              ElevatedButton.icon(
                onPressed: _running ? null : _runRestore,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
                label: Text(_running
                    ? 'Restoring...'
                    : _done
                        ? 'Restore Again'
                        : 'Restore'),
              ),
          ],
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
                    ? 'Select a backup JSON file to begin...'
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
