import 'package:cloud_firestore/cloud_firestore.dart';

import 'maneuver_tug.dart';

enum ManeuverPropellerDirection { rightHanded, leftHanded }

enum ManeuverPropellerPitch { fixed, controllable }

enum ManeuverFirstLine { headLine, breastLine, spring }

class ManeuverShipOption {
  const ManeuverShipOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ManeuverTugSnapshot {
  const ManeuverTugSnapshot({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    this.bollardPull,
  });

  final String id;
  final String name;
  final ManeuverTugType type;
  final String source;
  final double? bollardPull;

  factory ManeuverTugSnapshot.fromMap(Map<String, dynamic> data) {
    final bollardPull = data['bollardPull'];
    return ManeuverTugSnapshot(
      id: (data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      type: ManeuverTugType.fromFirestore(data['type']),
      source: (data['source'] ?? '').toString(),
      bollardPull: bollardPull is num ? bollardPull.toDouble() : null,
    );
  }
}

class ManeuverReportRecord {
  const ManeuverReportRecord({
    required this.id,
    required this.pilotId,
    required this.portName,
    required this.portCode,
    required this.terminalId,
    required this.terminalName,
    required this.createdAt,
    this.pilotName,
    this.shipName,
    this.lengthMeters,
    this.beamMeters,
    this.maximumDraftMeters,
    this.propellerDirection,
    this.propellerPitch,
    this.officerNationality,
    this.crewNationality,
    this.forwardTug,
    this.aftTug,
    this.currentDirectionDegrees,
    this.currentIntensityKnots,
    this.windDirectionDegrees,
    this.windIntensityKnots,
    this.approachComments,
    this.forwardFirstLine,
    this.aftFirstLine,
    this.mooringComments,
  });

  final String id;
  final String pilotId;
  final String? pilotName;
  final String portName;
  final String portCode;
  final String terminalId;
  final String terminalName;
  final DateTime? createdAt;
  final String? shipName;
  final double? lengthMeters;
  final double? beamMeters;
  final double? maximumDraftMeters;
  final ManeuverPropellerDirection? propellerDirection;
  final ManeuverPropellerPitch? propellerPitch;
  final String? officerNationality;
  final String? crewNationality;
  final ManeuverTugSnapshot? forwardTug;
  final ManeuverTugSnapshot? aftTug;
  final int? currentDirectionDegrees;
  final double? currentIntensityKnots;
  final int? windDirectionDegrees;
  final double? windIntensityKnots;
  final String? approachComments;
  final ManeuverFirstLine? forwardFirstLine;
  final ManeuverFirstLine? aftFirstLine;
  final String? mooringComments;

  bool get hasShipData =>
      shipName != null ||
      lengthMeters != null ||
      beamMeters != null ||
      maximumDraftMeters != null ||
      propellerDirection != null ||
      propellerPitch != null ||
      officerNationality != null ||
      crewNationality != null;

  bool get hasApproachData =>
      forwardTug != null ||
      aftTug != null ||
      currentDirectionDegrees != null ||
      currentIntensityKnots != null ||
      windDirectionDegrees != null ||
      windIntensityKnots != null ||
      approachComments != null;

  bool get hasMooringData =>
      forwardFirstLine != null ||
      aftFirstLine != null ||
      mooringComments != null;

  factory ManeuverReportRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final ship = _asMap(data['ship']);
    final approach = _asMap(data['approach']);
    final mooring = _asMap(data['mooring']);
    final createdAt = data['createdAt'];

    return ManeuverReportRecord(
      id: document.id,
      pilotId: (data['pilotId'] ?? '').toString(),
      pilotName: _asOptionalString(data['pilotName']),
      portName: (data['portName'] ?? '').toString(),
      portCode: (data['portCode'] ?? '').toString(),
      terminalId: (data['terminalId'] ?? '').toString(),
      terminalName: (data['terminalName'] ?? '').toString(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      shipName: _asOptionalString(ship['name']),
      lengthMeters: _asDouble(ship['lengthMeters']),
      beamMeters: _asDouble(ship['beamMeters']),
      maximumDraftMeters: _asDouble(ship['maximumDraftMeters']),
      propellerDirection: _enumByName(
        ManeuverPropellerDirection.values,
        ship['propellerDirection'],
      ),
      propellerPitch: _enumByName(
        ManeuverPropellerPitch.values,
        ship['propellerPitch'],
      ),
      officerNationality: _asOptionalString(ship['officerNationality']),
      crewNationality: _asOptionalString(ship['crewNationality']),
      forwardTug: _asTugSnapshot(approach['forwardTug']),
      aftTug: _asTugSnapshot(approach['aftTug']),
      currentDirectionDegrees: _asInt(approach['currentDirectionDegrees']),
      currentIntensityKnots: _asDouble(approach['currentIntensityKnots']),
      windDirectionDegrees: _asInt(approach['windDirectionDegrees']),
      windIntensityKnots: _asDouble(approach['windIntensityKnots']),
      approachComments: _asOptionalString(approach['comments']),
      forwardFirstLine: _enumByName(
        ManeuverFirstLine.values,
        mooring['forwardFirstLine'],
      ),
      aftFirstLine: _enumByName(
        ManeuverFirstLine.values,
        mooring['aftFirstLine'],
      ),
      mooringComments: _asOptionalString(mooring['comments']),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }

  static String? _asOptionalString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static double? _asDouble(Object? value) {
    return value is num ? value.toDouble() : null;
  }

  static int? _asInt(Object? value) {
    return value is num ? value.toInt() : null;
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? value) {
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    return null;
  }

  static ManeuverTugSnapshot? _asTugSnapshot(Object? value) {
    final map = _asMap(value);
    return map.isEmpty ? null : ManeuverTugSnapshot.fromMap(map);
  }
}

class ManeuverReportDraft {
  const ManeuverReportDraft({
    required this.portName,
    required this.portCode,
    required this.terminalId,
    required this.terminalName,
    this.shipId,
    this.shipName,
    this.lengthMeters,
    this.beamMeters,
    this.maximumDraftMeters,
    this.propellerDirection,
    this.propellerPitch,
    this.officerNationality,
    this.crewNationality,
    this.forwardTug,
    this.aftTug,
    this.currentDirectionDegrees,
    this.currentIntensityKnots,
    this.windDirectionDegrees,
    this.windIntensityKnots,
    this.approachComments,
    this.forwardFirstLine,
    this.aftFirstLine,
    this.mooringComments,
  });

  final String portName;
  final String portCode;
  final String terminalId;
  final String terminalName;
  final String? shipId;
  final String? shipName;
  final double? lengthMeters;
  final double? beamMeters;
  final double? maximumDraftMeters;
  final ManeuverPropellerDirection? propellerDirection;
  final ManeuverPropellerPitch? propellerPitch;
  final String? officerNationality;
  final String? crewNationality;
  final ManeuverTug? forwardTug;
  final ManeuverTug? aftTug;
  final int? currentDirectionDegrees;
  final double? currentIntensityKnots;
  final int? windDirectionDegrees;
  final double? windIntensityKnots;
  final String? approachComments;
  final ManeuverFirstLine? forwardFirstLine;
  final ManeuverFirstLine? aftFirstLine;
  final String? mooringComments;

  Map<String, dynamic> toFirestore({
    required String pilotId,
    String? pilotName,
  }) {
    return {
      'schemaVersion': 2,
      'pilotId': pilotId,
      if (pilotName != null && pilotName.isNotEmpty) 'pilotName': pilotName,
      'portName': portName,
      'portCode': portCode,
      'terminalId': terminalId,
      'terminalName': terminalName,
      'ship': _withoutNulls({
        'id': shipId,
        'name': shipName,
        'lengthMeters': lengthMeters,
        'beamMeters': beamMeters,
        'maximumDraftMeters': maximumDraftMeters,
        'propellerDirection': propellerDirection?.name,
        'propellerPitch': propellerPitch?.name,
        'officerNationality': officerNationality,
        'crewNationality': crewNationality,
      }),
      'approach': _withoutNulls({
        'forwardTug': _tugSnapshot(forwardTug),
        'aftTug': _tugSnapshot(aftTug),
        'currentDirectionDegrees': currentDirectionDegrees,
        'currentIntensityKnots': currentIntensityKnots,
        'windDirectionDegrees': windDirectionDegrees,
        'windIntensityKnots': windIntensityKnots,
        'comments': approachComments,
      }),
      'mooring': _withoutNulls({
        'forwardFirstLine': forwardFirstLine?.name,
        'aftFirstLine': aftFirstLine?.name,
        'comments': mooringComments,
      }),
    };
  }

  static Map<String, dynamic>? _tugSnapshot(ManeuverTug? tug) {
    if (tug == null) return null;
    return _withoutNulls({
      'id': tug.id,
      'name': tug.name,
      'bollardPull': tug.bollardPull,
      'type': tug.type.firestoreValue,
      'source': tug.isOfficial ? 'operationalParameters' : 'community',
    });
  }

  static Map<String, dynamic> _withoutNulls(Map<String, dynamic> values) {
    return Map<String, dynamic>.fromEntries(
      values.entries.where((entry) => entry.value != null),
    );
  }
}
