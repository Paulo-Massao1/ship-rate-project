import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

import '../firebase_options.dart';

/// Seed script to import authorized pilot emails from Excel into Firestore.
/// Run with: flutter run -d chrome -t lib/scripts/seed_authorized_emails.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SeedAuthorizedEmailsApp());
}

class SeedAuthorizedEmailsApp extends StatelessWidget {
  const SeedAuthorizedEmailsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate - Seed Authorized Emails',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SeedAuthorizedEmailsPage(),
    );
  }
}

// PAGE

class SeedAuthorizedEmailsPage extends StatefulWidget {
  const SeedAuthorizedEmailsPage({super.key});

  @override
  State<SeedAuthorizedEmailsPage> createState() =>
      _SeedAuthorizedEmailsPageState();
}

class _SeedAuthorizedEmailsPageState extends State<SeedAuthorizedEmailsPage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // SEED STATE
  final _logs = <String>[];
  bool _seeding = false;
  Uint8List? _fileBytes;
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
    final uploadInput = html.FileUploadInputElement()..accept = '.xlsx,.xls';
    uploadInput.click();

    await uploadInput.onChange.first;

    if (uploadInput.files == null || uploadInput.files!.isEmpty) return;

    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    setState(() {
      _fileBytes = Uint8List.fromList(reader.result as List<int>);
      _fileName = file.name;
    });
  }

  // SEED METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _seed() async {
    if (_fileBytes == null) return;

    setState(() {
      _seeding = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('Seeding authorized emails from: $_fileName');
      _log('Logged in as: ${_user?.email}');
      _log('');

      // Parse Excel file
      final excel = Excel.decodeBytes(_fileBytes!);
      final sheet = excel.tables[excel.tables.keys.first]!;
      final rows = sheet.rows;

      _log('Total rows in Excel (including header): ${rows.length}');
      _log('');

      // Load existing authorized emails to skip duplicates
      final existing =
          await firestore.collection('authorized_emails').get();
      final existingEmails = existing.docs
          .map((d) => (d.data()['email'] as String?)?.toLowerCase())
          .whereType<String>()
          .toSet();

      _log('Existing authorized emails in database: ${existingEmails.length}');
      _log('');

      var created = 0;
      var skipped = 0;
      var skippedEmpty = 0;

      // Skip header row (index 0), process data rows
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Column indices: 0=Sequência, 1=Praticagem, 2=Nome, 3=Nome de Guerra, 4=Email
        final emailCell = row.length > 4 ? row[4] : null;
        final nomeGuerraCell = row.length > 3 ? row[3] : null;

        final emailValue = emailCell?.value?.toString().trim().toLowerCase();
        final nomeGuerraValue = nomeGuerraCell?.value?.toString().trim() ?? '';

        if (emailValue == null || emailValue.isEmpty) {
          skippedEmpty++;
          continue;
        }

        if (existingEmails.contains(emailValue)) {
          _log('  SKIP: $emailValue (already exists)');
          skipped++;
          continue;
        }

        await firestore.collection('authorized_emails').add({
          'email': emailValue,
          'nomeGuerra': nomeGuerraValue,
        });

        _log('  CREATED: $emailValue ($nomeGuerraValue)');
        created++;
        existingEmails.add(emailValue);
      }

      _log('');
      _log('=' * 40);
      _log('');
      _log('=== Seed Complete ===');
      _log('Created: $created');
      _log('Skipped (duplicate): $skipped');
      _log('Skipped (empty email): $skippedEmpty');
      _log('Total authorized emails: ${existingEmails.length}');
      _log('=====================');
    } catch (e) {
      _log('');
      _log('ERROR: $e');
    }

    setState(() => _seeding = false);
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShipRate - Seed Authorized Emails')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user == null ? _buildLoginForm() : _buildSeedPanel(),
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
              'Login to seed authorized emails',
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

  Widget _buildSeedPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _seeding ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(_fileName ?? 'Select Excel File'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _seeding || _fileBytes == null ? null : _seed,
              icon: _seeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_seeding ? 'Seeding...' : 'Seed Emails'),
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
                    ? 'Select an Excel file (.xlsx) and press "Seed Emails" to import authorized pilot emails...'
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
