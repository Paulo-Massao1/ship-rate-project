import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller for editing existing ratings.
///
/// Responsibilities:
/// - Load existing rating data
/// - Update rating in Firestore
/// - Update ship information
class EditRatingController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const List<String> cabinCriteria = [
    'Temperatura da Cabine',
    'Limpeza da Cabine',
  ];

  static const List<String> bridgeCriteria = [
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
  ];

  static const List<String> otherCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  /// All rating criteria combined.
  List<String> get allCriteria => [
        ...cabinCriteria,
        ...bridgeCriteria,
        ...otherCriteria,
      ];

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Checks if user is authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Loads rating data from a document snapshot.
  Future<RatingEditData> loadRatingData(QueryDocumentSnapshot rating) async {
    final data = rating.data() as Map<String, dynamic>;
    final shipRef = rating.reference.parent.parent!;
    final shipDoc = await shipRef.get();
    final shipData = shipDoc.data();

    return RatingEditData(
      shipRef: shipRef,
      shipName: shipData?['nome'] ?? '',
      shipImo: shipData?['imo'] ?? '',
      disembarkationDate: (data['dataDesembarque'] as Timestamp?)?.toDate(),
      cabinType: _normalizeCabinType(data['tipoCabine']),
      cabinDeck: data['deckCabine'],
      generalObservation: data['observacaoGeral'] ?? '',
      shipInfo: data['infoNavio'] as Map<String, dynamic>? ?? {},
      bridgeInfo: data['infoPassadico'] as Map<String, dynamic>? ?? {},
      ratingItems: data['itens'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Saves rating changes to Firestore.
  Future<void> saveChanges({
    required DocumentReference ratingRef,
    required DocumentReference shipRef,
    required RatingUpdateData updateData,
  }) async {
    if (!isAuthenticated) {
      throw Exception('Usuário não autenticado');
    }

    // Update ship document
    await shipRef.update({
      'nome': updateData.shipName,
      'imo': updateData.shipImo,
    });

    // Build rating items map
    final itens = <String, dynamic>{};
    for (final criterio in allCriteria) {
      itens[criterio] = {
        'nota': updateData.ratings[criterio] ?? 3.0,
        'observacao': updateData.observations[criterio] ?? '',
      };
    }

    // Update rating document
    await ratingRef.update({
      'dataDesembarque': Timestamp.fromDate(updateData.disembarkationDate),
      'tipoCabine': updateData.cabinType,
      'deckCabine': updateData.cabinDeck,
      'itens': itens,
      'observacaoGeral': updateData.generalObservation,
      'infoNavio': updateData.shipInfo,
      'infoPassadico': updateData.bridgeInfo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Validates required fields.
  String? validateFields({
    required String shipName,
    required DateTime? disembarkationDate,
    required String? cabinType,
  }) {
    if (shipName.isEmpty) {
      return 'Digite o nome do navio';
    }
    if (disembarkationDate == null) {
      return 'Selecione a data de desembarque';
    }
    if (cabinType == null) {
      return 'Selecione o tipo de cabine';
    }
    return null;
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Normalizes cabin type for backwards compatibility.
  String? _normalizeCabinType(String? type) {
    if (type == 'PRT') return 'Pilot';
    return type;
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// Data class for loaded rating edit data.
class RatingEditData {
  final DocumentReference shipRef;
  final String shipName;
  final String shipImo;
  final DateTime? disembarkationDate;
  final String? cabinType;
  final String? cabinDeck;
  final String generalObservation;
  final Map<String, dynamic> shipInfo;
  final Map<String, dynamic> bridgeInfo;
  final Map<String, dynamic> ratingItems;

  RatingEditData({
    required this.shipRef,
    required this.shipName,
    required this.shipImo,
    required this.disembarkationDate,
    required this.cabinType,
    required this.cabinDeck,
    required this.generalObservation,
    required this.shipInfo,
    required this.bridgeInfo,
    required this.ratingItems,
  });
}

/// Data class for rating update payload.
class RatingUpdateData {
  final String shipName;
  final String shipImo;
  final DateTime disembarkationDate;
  final String cabinType;
  final String? cabinDeck;
  final String generalObservation;
  final Map<String, double> ratings;
  final Map<String, String> observations;
  final Map<String, dynamic> shipInfo;
  final Map<String, dynamic> bridgeInfo;

  RatingUpdateData({
    required this.shipName,
    required this.shipImo,
    required this.disembarkationDate,
    required this.cabinType,
    required this.cabinDeck,
    required this.generalObservation,
    required this.ratings,
    required this.observations,
    required this.shipInfo,
    required this.bridgeInfo,
  });
}