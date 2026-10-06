import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManeuverNationalityException implements Exception {
  const ManeuverNationalityException(this.code);

  final ManeuverNationalityError code;
}

enum ManeuverNationalityError { invalidName, duplicate, signedOut }

/// Shared nationality catalog used by every maneuver report.
class ManeuverNationalityService {
  ManeuverNationalityService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _predefinedNames = <String>{
    'FILIPINO',
    'RUSSIAN',
    'UKRAINIAN',
    'INDIAN',
    'CHINESE',
    'BRAZILIAN',
  };

  Stream<List<String>> watchNationalities() {
    return _firestore
        .collection('maneuverNationalities')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
            .map((document) => (document.data()['name'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList(growable: false)..sort((a, b) => a.compareTo(b)),
        );
  }

  Future<String> createNationality(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ManeuverNationalityException(
        ManeuverNationalityError.signedOut,
      );
    }

    final displayName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedName = normalizeName(displayName);
    final lookupKey = _lookupKey(normalizedName);
    if (displayName.length < 2 ||
        displayName.length > 80 ||
        lookupKey.isEmpty) {
      throw const ManeuverNationalityException(
        ManeuverNationalityError.invalidName,
      );
    }
    if (_predefinedNames.contains(normalizedName)) {
      throw const ManeuverNationalityException(
        ManeuverNationalityError.duplicate,
      );
    }

    final reference = _firestore
        .collection('maneuverNationalities')
        .doc(lookupKey);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const ManeuverNationalityException(
          ManeuverNationalityError.duplicate,
        );
      }

      transaction.set(reference, {
        'name': displayName,
        'normalizedName': normalizedName,
        'lookupKey': lookupKey,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return displayName;
  }

  static String normalizeName(String value) {
    const replacements = <String, String>{
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
    };

    var normalized = value.trim().toUpperCase();
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    return normalized
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _lookupKey(String normalizedName) {
    return normalizedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
