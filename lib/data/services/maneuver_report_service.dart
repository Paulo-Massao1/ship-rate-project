import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/maneuver_report.dart';

class ManeuverReportException implements Exception {
  const ManeuverReportException(this.code);

  final ManeuverReportError code;
}

enum ManeuverReportError { signedOut, saveFailed, deleteFailed }

class ManeuverReportService {
  ManeuverReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<List<ManeuverShipOption>> loadShips() async {
    final snapshot = await _firestore.collection('navios').get();
    final ships = <ManeuverShipOption>[];

    for (final document in snapshot.docs) {
      final data = document.data();
      if (data['merged'] == true) continue;

      final name = (data['nome'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      ships.add(ManeuverShipOption(id: document.id, name: name));
    }

    ships.sort((a, b) => a.name.toUpperCase().compareTo(b.name.toUpperCase()));
    return ships;
  }

  Future<String> saveReport(ManeuverReportDraft draft) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ManeuverReportException(ManeuverReportError.signedOut);
    }

    try {
      var profileName = '';
      try {
        final userDocument = await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .get();
        profileName = (userDocument.data()?['nomeGuerra'] ?? '')
            .toString()
            .trim();
      } catch (_) {
        // The report can still be saved with the Firebase profile fallback.
      }
      final authName = (user.displayName ?? '').trim();
      final pilotName = profileName.isNotEmpty ? profileName : authName;

      final reference = await _firestore.collection('manobras_relatos').add({
        ...draft.toFirestore(pilotId: user.uid, pilotName: pilotName),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return reference.id;
    } on ManeuverReportException {
      rethrow;
    } catch (_) {
      throw const ManeuverReportException(ManeuverReportError.saveFailed);
    }
  }

  Stream<List<ManeuverReportRecord>> watchReports({
    required String portCode,
    required String terminalName,
  }) {
    return _firestore
        .collection('manobras_relatos')
        .where('portCode', isEqualTo: portCode.trim().toUpperCase())
        .where('terminalName', isEqualTo: terminalName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ManeuverReportRecord.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> deleteReport(String reportId) async {
    if (_auth.currentUser == null) {
      throw const ManeuverReportException(ManeuverReportError.signedOut);
    }

    try {
      await _firestore.collection('manobras_relatos').doc(reportId).delete();
    } catch (_) {
      throw const ManeuverReportException(ManeuverReportError.deleteFailed);
    }
  }
}
