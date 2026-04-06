import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

/// Seed script to create navigation safety locations in Firestore.
/// Run with: flutter run -d chrome -t lib/scripts/seed_locations.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SeedLocationsApp());
}

class SeedLocationsApp extends StatelessWidget {
  const SeedLocationsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate - Seed Locations',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SeedLocationsPage(),
    );
  }
}

// CONSTANTS

const _locations = [
  'Arapiri',
  'Balaio',
  'Bicheira',
  'Caldeirão',
  'Ciganas',
  'Cuieiras',
  'Fundeadouro Itacoatiara',
  'Gurupatuba',
  'Juruti/Canal',
  'Mazagão',
  'Mocambo',
  'Oiapoque',
  'Paraná dos Arcos',
  'Parauaquara',
  'Patacho Sul',
  'Peixe Boi',
  'Prainha',
  'Santa Rita',
  'São Raimundo',
  'Serpa',
  'Xibuí',
];

// PAGE

class SeedLocationsPage extends StatefulWidget {
  const SeedLocationsPage({super.key});

  @override
  State<SeedLocationsPage> createState() => _SeedLocationsPageState();
}

class _SeedLocationsPageState extends State<SeedLocationsPage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // SEED STATE
  final _logs = <String>[];
  bool _seeding = false;

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

  // SEED METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _seed() async {
    setState(() {
      _seeding = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('Seeding navigation safety locations...');
      _log('Logged in as: ${_user?.email}');
      _log('');

      // Load existing locations to skip duplicates
      final existing = await firestore.collection('locais').get();
      final existingNames =
          existing.docs.map((d) => d.data()['nome'] as String).toSet();

      _log('Existing locations in database: ${existingNames.length}');
      _log('');

      var created = 0;
      var skipped = 0;

      for (final name in _locations) {
        if (existingNames.contains(name)) {
          _log('  SKIP: $name (already exists)');
          skipped++;
          continue;
        }

        await firestore.collection('locais').add({
          'nome': name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _log('  CREATED: $name');
        created++;
      }

      _log('');
      _log('=' * 40);
      _log('');
      _log('=== Seed Complete ===');
      _log('Created: $created');
      _log('Skipped: $skipped');
      _log('Total locations: ${existingNames.length + created}');
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
      appBar: AppBar(title: const Text('ShipRate - Seed Locations')),
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
              'Login to seed locations',
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
        ElevatedButton.icon(
          onPressed: _seeding ? null : _seed,
          icon: _seeding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_location_alt),
          label: Text(_seeding ? 'Seeding...' : 'Seed Locations'),
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
                    ? 'Press "Seed Locations" to create navigation safety locations...'
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
