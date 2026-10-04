import 'maneuver_tug.dart';

enum ManeuverPropellerDirection { rightHanded, leftHanded }

enum ManeuverPropellerPitch { fixed, controllable }

enum ManeuverFirstLine { headLine, breastLine, spring }

class ManeuverShipOption {
  const ManeuverShipOption({required this.id, required this.name});

  final String id;
  final String name;
}

class ManeuverReportDraft {
  const ManeuverReportDraft({
    required this.portName,
    required this.portCode,
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
      'schemaVersion': 1,
      'pilotId': pilotId,
      if (pilotName != null && pilotName.isNotEmpty) 'pilotName': pilotName,
      'portName': portName,
      'portCode': portCode,
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
