import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/maneuver_tug.dart';

class ManeuverTugException implements Exception {
  const ManeuverTugException(this.code);

  final ManeuverTugError code;
}

enum ManeuverTugError { invalidName, invalidBollardPull, duplicate, signedOut }

class ManeuverTugService {
  ManeuverTugService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const supportedPortCodes = <String>{
    'SAN',
    'STM',
    'JAR',
    'JUR',
    'PTR',
    'ITA',
  };

  static const _officialTugs = <ManeuverTug>[
    ManeuverTug(
      id: 'official-san-tamoio',
      name: 'TAMOIO',
      portCode: 'SAN',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 50.73,
    ),
    ManeuverTug(
      id: 'official-san-pelagius',
      name: 'PELAGIUS',
      portCode: 'SAN',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 55.60,
    ),
    ManeuverTug(
      id: 'official-stm-araruama',
      name: 'ARARUAMA',
      portCode: 'STM',
      type: ManeuverTugType.conventional,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 40.00,
    ),
    ManeuverTug(
      id: 'official-stm-ciclone',
      name: 'CICLONE',
      portCode: 'STM',
      type: ManeuverTugType.conventional,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 45.00,
    ),
    ManeuverTug(
      id: 'official-stm-san-sauipe',
      name: 'SAN SAUÍPE',
      portCode: 'STM',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 40.00,
    ),
    ManeuverTug(
      id: 'official-stm-pollux-ii',
      name: 'POLLUX II',
      portCode: 'STM',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 50.80,
    ),
    ManeuverTug(
      id: 'official-stm-eng-mascarenhas',
      name: 'ENG. MASCARENHAS',
      portCode: 'STM',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 51.00,
    ),
    ManeuverTug(
      id: 'official-ptr-cnl-ametista',
      name: 'CNL AMETISTA',
      portCode: 'PTR',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 45.00,
    ),
    ManeuverTug(
      id: 'official-ptr-cnl-rubi',
      name: 'CNL RUBI',
      portCode: 'PTR',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 45.20,
    ),
    ManeuverTug(
      id: 'official-jur-sao-joao',
      name: 'SÃO JOÃO',
      portCode: 'JUR',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 41.30,
    ),
    ManeuverTug(
      id: 'official-jur-sao-paulo',
      name: 'SÃO PAULO',
      portCode: 'JUR',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 46.50,
    ),
    ManeuverTug(
      id: 'official-ita-stefano-locks',
      name: 'STEFANO LOCKS',
      portCode: 'ITA',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 50.00,
      officialTerminalNames: {'Hermasa 1', 'Hermasa 2', 'Hermasa 3'},
    ),
    ManeuverTug(
      id: 'official-ita-joao-triches',
      name: 'JOÃO TRICHES',
      portCode: 'ITA',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 27.60,
      officialTerminalNames: {'Hermasa 1', 'Hermasa 2', 'Hermasa 3'},
    ),
    ManeuverTug(
      id: 'official-ita-j-guilherme-ii',
      name: 'J. GUILHERME II',
      portCode: 'ITA',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 60.50,
      officialTerminalNames: {'TFB'},
    ),
    ManeuverTug(
      id: 'official-ita-j-guilherme-vii',
      name: 'J. GUILHERME VII',
      portCode: 'ITA',
      type: ManeuverTugType.azimuthal,
      source: ManeuverTugSource.operationalParameters,
      bollardPull: 56.88,
      officialTerminalNames: {'TFB'},
    ),
  ];

  List<ManeuverTug> officialTugsForPort(
    String portCode, {
    String? terminalName,
  }) {
    final normalizedPortCode = portCode.trim().toUpperCase();
    return _officialTugs
        .where(
          (tug) =>
              tug.portCode == normalizedPortCode &&
              (terminalName == null ||
                  tug.officialTerminalNames.isEmpty ||
                  tug.officialTerminalNames.contains(terminalName)),
        )
        .toList(growable: false);
  }

  Stream<List<ManeuverTug>> watchTugsForPort(
    String portCode, {
    String? terminalName,
  }) {
    final normalizedPortCode = portCode.trim().toUpperCase();
    final official = officialTugsForPort(
      normalizedPortCode,
      terminalName: terminalName,
    );
    final officialNames = official.map((tug) => normalizeName(tug.name)).toSet();

    return _firestore
        .collection('maneuverTugs')
        .where('portCode', isEqualTo: normalizedPortCode)
        .snapshots()
        .map((snapshot) {
          final community = snapshot.docs
              .map(ManeuverTug.fromFirestore)
              .where(
                (tug) =>
                    tug.name.isNotEmpty &&
                    !officialNames.contains(normalizeName(tug.name)),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return [...official, ...community];
        });
  }

  Future<ManeuverTug> createCommunityTug({
    required String portCode,
    required String name,
    required ManeuverTugType type,
    double? bollardPull,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const ManeuverTugException(ManeuverTugError.signedOut);
    }

    final normalizedPortCode = portCode.trim().toUpperCase();
    final displayName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedName = normalizeName(displayName);
    final lookupKey = _lookupKey(normalizedName);

    if (!supportedPortCodes.contains(normalizedPortCode) ||
        displayName.length < 2 ||
        displayName.length > 60 ||
        lookupKey.isEmpty) {
      throw const ManeuverTugException(ManeuverTugError.invalidName);
    }
    if (bollardPull != null &&
        (bollardPull <= 0 || bollardPull > 200 || !bollardPull.isFinite)) {
      throw const ManeuverTugException(ManeuverTugError.invalidBollardPull);
    }

    final officialDuplicate = officialTugsForPort(
      normalizedPortCode,
    ).any((tug) => normalizeName(tug.name) == normalizedName);
    if (officialDuplicate) {
      throw const ManeuverTugException(ManeuverTugError.duplicate);
    }

    final documentId = '$normalizedPortCode--$lookupKey';
    final reference = _firestore.collection('maneuverTugs').doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        throw const ManeuverTugException(ManeuverTugError.duplicate);
      }

      transaction.set(reference, {
        'name': displayName.toUpperCase(),
        'normalizedName': normalizedName,
        'lookupKey': lookupKey,
        'portCode': normalizedPortCode,
        'type': type.firestoreValue,
        'source': 'community',
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        if (bollardPull != null) 'bollardPull': bollardPull,
      });
    });

    return ManeuverTug(
      id: documentId,
      name: displayName.toUpperCase(),
      portCode: normalizedPortCode,
      type: type,
      source: ManeuverTugSource.community,
      bollardPull: bollardPull,
      createdBy: user.uid,
    );
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
