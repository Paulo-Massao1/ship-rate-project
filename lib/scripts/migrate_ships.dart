import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

/// Migration script to merge duplicate ships (same name, different case).
/// Run with: flutter run -d chrome -t lib/scripts/migrate_ships.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MigrateApp());
}

class MigrateApp extends StatelessWidget {
  const MigrateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate Migration',
      theme: ThemeData.dark(useMaterial3: true),
      home: const MigratePage(),
    );
  }
}

// MODELS

class _ShipData {
  final String id;
  final String name;
  final Map<String, dynamic> data;
  final List<_RatingData> ratings;
  DateTime? get earliestRating => ratings.isEmpty
      ? null
      : ratings
          .map((r) => r.createdAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (prev, d) => prev == null || d.isBefore(prev) ? d : prev);

  _ShipData({
    required this.id,
    required this.name,
    required this.data,
    required this.ratings,
  });
}

class _RatingData {
  final String id;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  _RatingData({required this.id, required this.data, required this.createdAt});
}

class _DuplicateGroup {
  final String normalizedName;
  final _ShipData primary;
  final List<_ShipData> duplicates;

  int get totalRatings =>
      primary.ratings.length +
      duplicates.fold(0, (total, s) => total + s.ratings.length);

  int get ratingsToMove =>
      duplicates.fold(0, (total, s) => total + s.ratings.length);

  _DuplicateGroup({
    required this.normalizedName,
    required this.primary,
    required this.duplicates,
  });
}

// PAGE

class MigratePage extends StatefulWidget {
  const MigratePage({super.key});

  @override
  State<MigratePage> createState() => _MigratePageState();
}

class _MigratePageState extends State<MigratePage> {
  // AUTH STATE
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  // MIGRATION STATE
  final _logs = <String>[];
  bool _scanning = false;
  bool _executing = false;
  bool _confirmExecute = false;
  List<_DuplicateGroup> _groups = [];

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

  // SCAN METHODS

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _logs.clear();
      _groups = [];
      _confirmExecute = false;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('[DRY RUN] Scanning Firestore for duplicate ships...');
      _log('Logged in as: ${_user?.email}');
      _log('');

      // Load all ships with their ratings
      final shipsSnapshot = await firestore.collection('navios').get();
      _log('Total ships in database: ${shipsSnapshot.docs.length}');
      _log('');

      final allShips = <_ShipData>[];

      for (final shipDoc in shipsSnapshot.docs) {
        final shipData = shipDoc.data();

        // Skip already-merged ships
        if (shipData['merged'] == true) continue;

        final ratingsSnapshot = await firestore
            .collection('navios')
            .doc(shipDoc.id)
            .collection('avaliacoes')
            .get();

        final ratings = ratingsSnapshot.docs.map((rDoc) {
          final rData = rDoc.data();
          DateTime? createdAt;
          if (rData['createdAt'] is Timestamp) {
            createdAt = (rData['createdAt'] as Timestamp).toDate();
          }
          return _RatingData(id: rDoc.id, data: rData, createdAt: createdAt);
        }).toList();

        allShips.add(_ShipData(
          id: shipDoc.id,
          name: shipData['nome'] as String? ?? '',
          data: shipData,
          ratings: ratings,
        ));
      }

      // Group by normalized name (no spaces, uppercase) to catch
      // variants like "LOG IN POLARIS" vs "LOGIN POLARIS"
      final grouped = <String, List<_ShipData>>{};
      for (final ship in allShips) {
        final key = ship.name.toUpperCase().replaceAll(RegExp(r'\s+'), '');
        grouped.putIfAbsent(key, () => []).add(ship);
      }

      // Filter to only groups with duplicates
      final duplicateGroups = grouped.entries
          .where((e) => e.value.length > 1)
          .map((e) {
        final ships = e.value;

        // Sort: oldest first (by earliest rating date, then by ID as tiebreaker)
        ships.sort((a, b) {
          final aDate = a.earliestRating;
          final bDate = b.earliestRating;
          if (aDate == null && bDate == null) return a.id.compareTo(b.id);
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        });

        // Use the primary ship's name uppercased + clean whitespace as final name
        final cleanName = ships.first.name
            .toUpperCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return _DuplicateGroup(
          normalizedName: cleanName,
          primary: ships.first,
          duplicates: ships.sublist(1),
        );
      }).toList();

      if (duplicateGroups.isEmpty) {
        _log('No duplicate ships found. Database is clean.');
        setState(() => _scanning = false);
        return;
      }

      _log('Found ${duplicateGroups.length} duplicate group(s):');
      _log('=' * 60);
      _log('');

      var totalShipsAffected = 0;
      var totalRatingsToMove = 0;

      for (final group in duplicateGroups) {
        // Build the merge description line
        final parts = <String>[];
        parts.add('${group.primary.name} (${group.primary.ratings.length} ratings)');
        for (final dup in group.duplicates) {
          parts.add('${dup.name} (${dup.ratings.length} ratings)');
        }
        final mergedName = group.normalizedName;
        final totalRatings = group.totalRatings;

        _log(parts.join(' + '));
        _log('  -> $mergedName ($totalRatings ratings)');
        _log('  Primary: ${group.primary.id} (${group.primary.name})');
        for (final dup in group.duplicates) {
          _log('  Merge:   ${dup.id} (${dup.name}) '
              '- ${dup.ratings.length} ratings to move');
        }
        _log('');

        totalShipsAffected += 1 + group.duplicates.length;
        totalRatingsToMove += group.ratingsToMove;
      }

      _log('=' * 60);
      _log('');
      _log('=== Dry Run Summary ===');
      _log('Duplicate groups:  ${duplicateGroups.length}');
      _log('Ships affected:    $totalShipsAffected');
      _log('Ratings to move:   $totalRatingsToMove');
      _log('=======================');
      _log('');
      _log('Check the "I understand" box and press "Execute Migration" to apply.');

      setState(() => _groups = duplicateGroups);
    } catch (e) {
      _log('');
      _log('ERROR: $e');
    }

    setState(() => _scanning = false);
  }

  // EXECUTE METHODS

  Future<void> _execute() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Migration'),
        content: Text(
          'This will:\n\n'
          '- Move ratings from duplicate ships to primary ships\n'
          '- Rename primary ships to UPPERCASE\n'
          '- Mark ${_groups.fold(0, (total, g) => total + g.duplicates.length)} '
          'duplicate ship(s) as merged\n'
          '- Recalculate averages for primary ships\n\n'
          'No documents will be deleted. Continue?',
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
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _executing = true;
      _logs.clear();
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('[EXECUTING] Starting migration...');
      _log('Logged in as: ${_user?.email}');
      _log('');

      var totalRatingsMoved = 0;
      var totalShipsMerged = 0;

      for (final group in _groups) {
        _log('Processing: ${group.normalizedName}');

        final primaryRef =
            firestore.collection('navios').doc(group.primary.id);

        // Move ratings from each duplicate to primary
        for (final dup in group.duplicates) {
          for (final rating in dup.ratings) {
            // Copy rating to primary ship's subcollection (keep original ID)
            await primaryRef
                .collection('avaliacoes')
                .doc(rating.id)
                .set(rating.data);

            // Delete rating from duplicate ship
            await firestore
                .collection('navios')
                .doc(dup.id)
                .collection('avaliacoes')
                .doc(rating.id)
                .delete();

            totalRatingsMoved++;
          }

          // Mark duplicate ship as merged (soft delete)
          await firestore.collection('navios').doc(dup.id).update({
            'merged': true,
            'mergedInto': group.primary.id,
            'mergedAt': FieldValue.serverTimestamp(),
          });

          totalShipsMerged++;
          _log('  Merged: ${dup.name} (${dup.id}) '
              '-> ${dup.ratings.length} ratings moved');
        }

        // Update primary ship name to UPPERCASE
        await primaryRef.update({'nome': group.normalizedName});

        // Recalculate averages for primary ship
        await _recalculateAverages(firestore, group.primary.id);

        // Recalculate info for primary ship
        await _recalculateInfo(firestore, group.primary.id);

        _log('  Primary updated: ${group.primary.id} '
            '-> ${group.normalizedName}');
        _log('');
      }

      _log('=' * 60);
      _log('');
      _log('=== Migration Complete ===');
      _log('Ships merged:    $totalShipsMerged');
      _log('Ratings moved:   $totalRatingsMoved');
      _log('Status:          COMPLETE');
      _log('==========================');
    } catch (e) {
      _log('');
      _log('ERROR: $e');
      _log('Migration stopped. Already-processed groups were committed.');
    }

    setState(() => _executing = false);
  }

  /// Recalculate medias (averages) for a ship from all its ratings.
  Future<void> _recalculateAverages(
    FirebaseFirestore firestore,
    String shipId,
  ) async {
    const averageKeyMap = {
      'Dispositivo de Embarque/Desembarque': 'dispositivo',
      'Temperatura da Cabine': 'temp_cabine',
      'Limpeza da Cabine': 'limpeza_cabine',
      'Passadiço – Equipamentos': 'passadico_equip',
      'Passadiço – Temperatura': 'passadico_temp',
      'Comida': 'comida',
      'Relacionamento com comandante/tripulação': 'relacionamento',
    };

    final ratingsSnapshot = await firestore
        .collection('navios')
        .doc(shipId)
        .collection('avaliacoes')
        .get();

    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final doc in ratingsSnapshot.docs) {
      final itens = doc.data()['itens'] as Map<String, dynamic>? ?? {};
      for (final entry in averageKeyMap.entries) {
        final item = itens[entry.key] as Map<String, dynamic>?;
        if (item == null) continue;
        final nota = (item['nota'] as num?)?.toDouble() ?? 0;
        if (nota > 0) {
          sums[entry.value] = (sums[entry.value] ?? 0) + nota;
          counts[entry.value] = (counts[entry.value] ?? 0) + 1;
        }
      }
    }

    final medias = <String, String>{};
    for (final key in averageKeyMap.values) {
      if (counts.containsKey(key) && counts[key]! > 0) {
        medias[key] = (sums[key]! / counts[key]!).toStringAsFixed(1);
      }
    }

    await firestore
        .collection('navios')
        .doc(shipId)
        .update({'medias': medias});
  }

  /// Recalculate consolidated info for a ship from all its ratings.
  Future<void> _recalculateInfo(
    FirebaseFirestore firestore,
    String shipId,
  ) async {
    final ratingsSnapshot = await firestore
        .collection('navios')
        .doc(shipId)
        .collection('avaliacoes')
        .get();

    final info = <String, dynamic>{};

    for (final doc in ratingsSnapshot.docs) {
      final infoNavio = doc.data()['infoNavio'] as Map<String, dynamic>? ?? {};
      for (final entry in infoNavio.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is List) {
          // Merge lists (e.g. nacionalidadeTripulacao) without duplicates
          final existing = (info[key] as List?)?.cast<String>() ?? <String>[];
          final newItems = List<String>.from(value);
          final merged = {...existing, ...newItems}.toList();
          info[key] = merged;
        } else if (value != null) {
          // Last-write-wins for scalar values
          info[key] = value;
        }
      }
    }

    await firestore
        .collection('navios')
        .doc(shipId)
        .update({'info': info});
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShipRate - Merge Duplicate Ships')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _user == null ? _buildLoginForm() : _buildMigratePanel(),
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
              'Login to access migration',
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

  Widget _buildMigratePanel() {
    final busy = _scanning || _executing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action buttons row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: busy ? null : _scan,
              icon: busy && _scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_scanning ? 'Scanning...' : 'Dry Run (Scan)'),
            ),
            if (_groups.isNotEmpty) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _confirmExecute,
                    onChanged: busy
                        ? null
                        : (v) =>
                            setState(() => _confirmExecute = v ?? false),
                  ),
                  const Text('I understand this will modify Firestore data'),
                ],
              ),
              ElevatedButton.icon(
                onPressed: busy || !_confirmExecute ? null : _execute,
                icon: _executing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _confirmExecute ? Colors.red : Colors.grey[700],
                  foregroundColor: Colors.white,
                ),
                label: Text(_executing ? 'Executing...' : 'Execute Migration'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Log output
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
                    ? 'Press "Dry Run (Scan)" to find duplicate ships...'
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
