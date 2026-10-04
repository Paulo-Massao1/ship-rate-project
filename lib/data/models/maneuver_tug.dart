import 'package:cloud_firestore/cloud_firestore.dart';

enum ManeuverTugType {
  azimuthal,
  conventional,
  unspecified;

  String get firestoreValue => name;

  static ManeuverTugType fromFirestore(Object? value) {
    return ManeuverTugType.values.firstWhere(
      (type) => type.firestoreValue == value,
      orElse: () => ManeuverTugType.unspecified,
    );
  }
}

enum ManeuverTugSource { operationalParameters, community }

class ManeuverTug {
  const ManeuverTug({
    required this.id,
    required this.name,
    required this.portCode,
    required this.type,
    required this.source,
    this.bollardPull,
    this.createdBy,
    this.createdAt,
    this.officialTerminalNames = const <String>{},
  });

  final String id;
  final String name;
  final String portCode;
  final ManeuverTugType type;
  final ManeuverTugSource source;
  final double? bollardPull;
  final String? createdBy;
  final DateTime? createdAt;
  final Set<String> officialTerminalNames;

  bool get isOfficial =>
      source == ManeuverTugSource.operationalParameters;

  factory ManeuverTug.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    final bollardPull = data['bollardPull'];

    return ManeuverTug(
      id: document.id,
      name: data['name'] as String? ?? '',
      portCode: data['portCode'] as String? ?? '',
      type: ManeuverTugType.fromFirestore(data['type']),
      source: ManeuverTugSource.community,
      bollardPull: bollardPull is num ? bollardPull.toDouble() : null,
      createdBy: data['createdBy'] as String?,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
