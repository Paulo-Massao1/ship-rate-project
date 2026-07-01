import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:ship_rate/firebase_options.dart';

/// Audit script to find duplicate ships in the "navios" collection.
/// READ-ONLY — does NOT modify or delete anything.
/// Run with: flutter run -d chrome -t tool/find_duplicate_ships.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FindDuplicateShipsApp());
}

class FindDuplicateShipsApp extends StatelessWidget {
  const FindDuplicateShipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShipRate - Find Duplicate Ships',
      theme: ThemeData.dark(useMaterial3: true),
      home: const FindDuplicateShipsPage(),
    );
  }
}

// ---------- DATA ----------

class ShipRecord {
  final String docId;
  final String nome;
  final String normalized;
  final int ratingCount;

  ShipRecord({
    required this.docId,
    required this.nome,
    required this.normalized,
    required this.ratingCount,
  });
}

// ---------- NORMALIZATION ----------

String normalizeShipName(String name) {
  var n = name.trim().toUpperCase();
  n = n.replaceAll(RegExp(r'\s+'), ' ');
  n = n.replaceAll(RegExp(r'[.\-/]'), '');

  const prefixes = ['MV ', 'M V ', 'MT ', 'M T '];
  for (final prefix in prefixes) {
    if (n.startsWith(prefix)) {
      n = n.substring(prefix.length);
      break;
    }
  }

  return n.trim();
}

// ---------- LEVENSHTEIN ----------

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final matrix = List.generate(
    a.length + 1,
    (i) => List.generate(b.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)),
  );

  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce(min);
    }
  }

  return matrix[a.length][b.length];
}

// ---------- DUPLICATE FINDER ----------

class DuplicateGroup {
  final String reason;
  final List<ShipRecord> ships;

  DuplicateGroup({required this.reason, required this.ships});
}

Set<String> sameWordsSet(String s) => s.split(' ').where((w) => w.isNotEmpty).toSet();

List<DuplicateGroup> findDuplicates(List<ShipRecord> ships) {
  final groups = <String, List<ShipRecord>>{};

  // 1. Exact normalized match
  for (final ship in ships) {
    groups.putIfAbsent(ship.normalized, () => []).add(ship);
  }

  final result = <DuplicateGroup>[];

  for (final entry in groups.entries) {
    if (entry.value.length > 1) {
      entry.value.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
      result.add(DuplicateGroup(
        reason: 'Exact normalized match: "${entry.key}"',
        ships: entry.value,
      ));
    }
  }

  // Track which pairs have already been grouped
  final alreadyGrouped = <String>{};
  for (final g in result) {
    for (final s in g.ships) {
      alreadyGrouped.add(s.docId);
    }
  }

  // 2. Fuzzy matching on remaining ships
  final fuzzyGroups = <DuplicateGroup>[];

  for (var i = 0; i < ships.length; i++) {
    for (var j = i + 1; j < ships.length; j++) {
      final a = ships[i];
      final b = ships[j];

      // Skip if they already share an exact-match group
      final pairKey = '${a.docId}|${b.docId}';

      String? reason;

      final dist = levenshtein(a.normalized, b.normalized);
      if (dist > 0 && dist <= 2) {
        reason = 'Levenshtein distance = $dist';
      } else if (a.normalized != b.normalized &&
          (a.normalized.contains(b.normalized) ||
              b.normalized.contains(a.normalized))) {
        reason = 'One name contains the other';
      } else if (a.normalized != b.normalized &&
          sameWordsSet(a.normalized) == sameWordsSet(b.normalized) &&
          sameWordsSet(a.normalized).length > 1) {
        reason = 'Same words, different order';
      }

      if (reason != null) {
        final pair = [a, b];
        pair.sort((x, y) => y.ratingCount.compareTo(x.ratingCount));
        fuzzyGroups.add(DuplicateGroup(
          reason: '$reason ("${a.normalized}" vs "${b.normalized}")',
          ships: pair,
        ));
      }
    }
  }

  // Remove fuzzy groups that are subsets of exact groups
  for (final fg in fuzzyGroups) {
    final ids = fg.ships.map((s) => s.docId).toSet();
    final alreadyCovered = result.any((eg) {
      final egIds = eg.ships.map((s) => s.docId).toSet();
      return ids.difference(egIds).isEmpty;
    });
    if (!alreadyCovered) {
      result.add(fg);
    }
  }

  return result;
}

// ---------- REPORT ----------

String generateReport(List<ShipRecord> allShips, List<DuplicateGroup> groups) {
  final buf = StringBuffer();
  final now = DateTime.now();

  buf.writeln('=' * 60);
  buf.writeln('SHIPRATE — DUPLICATE SHIPS REPORT');
  buf.writeln('Generated: ${now.toIso8601String()}');
  buf.writeln('Total ships in collection: ${allShips.length}');
  buf.writeln('Duplicate groups found: ${groups.length}');
  buf.writeln('=' * 60);
  buf.writeln();

  // --- Section 1: Exact matches ---
  final exactGroups = groups.where((g) => g.reason.startsWith('Exact')).toList();
  final fuzzyGroups = groups.where((g) => !g.reason.startsWith('Exact')).toList();

  if (exactGroups.isNotEmpty) {
    buf.writeln('-' * 60);
    buf.writeln('SECTION 1: EXACT NORMALIZED MATCHES (${exactGroups.length} groups)');
    buf.writeln('-' * 60);
    buf.writeln();

    for (var i = 0; i < exactGroups.length; i++) {
      final g = exactGroups[i];
      buf.writeln('Group ${i + 1}: ${g.reason}');
      for (var j = 0; j < g.ships.length; j++) {
        final s = g.ships[j];
        final primary = j == 0 ? ' ◀ PRIMARY (most ratings)' : '';
        buf.writeln('  ${j + 1}. "${s.nome}" | ID: ${s.docId} | Ratings: ${s.ratingCount}$primary');
      }
      buf.writeln();
    }
  }

  if (fuzzyGroups.isNotEmpty) {
    buf.writeln('-' * 60);
    buf.writeln('SECTION 2: FUZZY MATCHES (${fuzzyGroups.length} pairs)');
    buf.writeln('-' * 60);
    buf.writeln();

    for (var i = 0; i < fuzzyGroups.length; i++) {
      final g = fuzzyGroups[i];
      buf.writeln('Pair ${i + 1}: ${g.reason}');
      for (var j = 0; j < g.ships.length; j++) {
        final s = g.ships[j];
        final primary = j == 0 ? ' ◀ PRIMARY (most ratings)' : '';
        buf.writeln('  ${j + 1}. "${s.nome}" | ID: ${s.docId} | Ratings: ${s.ratingCount}$primary');
      }
      buf.writeln();
    }
  }

  if (groups.isEmpty) {
    buf.writeln('No duplicates found.');
  }

  buf.writeln('=' * 60);
  buf.writeln('END OF REPORT');
  buf.writeln('=' * 60);

  return buf.toString();
}

// ---------- PAGE ----------

class FindDuplicateShipsPage extends StatefulWidget {
  const FindDuplicateShipsPage({super.key});

  @override
  State<FindDuplicateShipsPage> createState() => _FindDuplicateShipsPageState();
}

class _FindDuplicateShipsPageState extends State<FindDuplicateShipsPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _loginError;
  User? _user;

  final _logs = <String>[];
  bool _auditing = false;
  String? _fullReport;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  void _log(String message) {
    setState(() => _logs.add(message));
  }

  Future<void> _runAudit() async {
    setState(() {
      _auditing = true;
      _logs.clear();
      _fullReport = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      _log('Fetching all ships from "navios" collection...');

      final naviosSnap = await firestore.collection('navios').get();
      _log('Found ${naviosSnap.docs.length} ships.');
      _log('');

      _log('Counting ratings (avaliacoes) for each ship...');

      final ships = <ShipRecord>[];
      var progress = 0;

      for (final doc in naviosSnap.docs) {
        final nome = (doc.data()['nome'] as String?) ?? '';
        final avaliacoesSnap =
            await doc.reference.collection('avaliacoes').count().get();
        final count = avaliacoesSnap.count ?? 0;

        ships.add(ShipRecord(
          docId: doc.id,
          nome: nome,
          normalized: normalizeShipName(nome),
          ratingCount: count,
        ));

        progress++;
        if (progress % 25 == 0 || progress == naviosSnap.docs.length) {
          _log('  Processed $progress / ${naviosSnap.docs.length} ships...');
        }
      }

      _log('');
      _log('All ships loaded. Running duplicate detection...');
      _log('');

      final groups = findDuplicates(ships);

      final report = generateReport(ships, groups);
      setState(() => _fullReport = report);

      _log(report);
      _log('');
      _log('Done! Use the "Download Report" button to save.');
    } catch (e) {
      _log('');
      _log('ERROR: $e');
    }

    setState(() => _auditing = false);
  }

  void _downloadReport() {
    if (_fullReport == null) return;

    final bytes = utf8.encode(_fullReport!);
    final blob = html.Blob([bytes], 'text/plain');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'duplicate_ships_report.txt')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ShipRate - Find Duplicate Ships'),
        actions: [
          if (_fullReport != null)
            TextButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download, color: Colors.greenAccent),
              label: const Text(
                'Download Report',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
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
            const Icon(Icons.directions_boat, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Login to audit duplicate ships',
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
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _auditing ? null : _runAudit,
              icon: _auditing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_auditing ? 'Scanning...' : 'Find Duplicates'),
            ),
            if (_fullReport != null) ...[
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _downloadReport,
                icon: const Icon(Icons.download),
                label: const Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                ),
              ),
            ],
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
                    ? 'Press "Find Duplicates" to scan the navios collection...'
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
