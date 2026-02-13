import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/services/pdf_service.dart';

/// Controller for managing user's ratings list.
///
/// Responsibilities:
/// - Load all ratings for the current user
/// - Delete ratings
/// - Export ratings to PDF
/// - Calculate rating statistics
class MyRatingsController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _shipsCollection = 'navios';
  static const String _usersCollection = 'usuarios';
  static const String _ratingsSubcollection = 'avaliacoes';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Gets the current user's ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Checks if user is authenticated.
  bool get isAuthenticated => currentUserId != null;

  /// Loads all ratings for the current user.
  ///
  /// Returns a list of [RatingWithShipInfo] sorted by date (newest first).
  /// Throws [Exception] if user is not authenticated.
  Future<List<RatingWithShipInfo>> loadUserRatings() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final callSign = await _getUserCallSign(userId);
    final results = <RatingWithShipInfo>[];

    final shipsSnapshot = await _firestore.collection(_shipsCollection).get();

    for (final ship in shipsSnapshot.docs) {
      final shipData = ship.data();
      final shipName = shipData['nome'] ?? 'Navio sem nome';
      final shipImo = shipData['imo'] ?? '';

      final ratingsSnapshot =
          await ship.reference.collection(_ratingsSubcollection).get();

      for (final rating in ratingsSnapshot.docs) {
        final data = rating.data();

        if (_ratingBelongsToUser(data, userId, callSign)) {
          results.add(RatingWithShipInfo(
            shipName: shipName,
            shipImo: shipImo,
            rating: rating,
          ));
        }
      }
    }

    _sortByDateDescending(results);
    return results;
  }

  /// Deletes a rating.
  Future<void> deleteRating(DocumentReference ratingRef) async {
    await ratingRef.delete();
  }

  /// Generates a PDF for a rating.
  Future<dynamic> generateRatingPdf(
    RatingWithShipInfo item,
    PdfLabels labels,
  ) async {
    final data = item.rating.data() as Map<String, dynamic>;

    final evaluatorName = data['nomeGuerra'] ?? labels.notAvailable;
    final evaluationDate = resolveEvaluationDate(data);
    final cabinType = data['tipoCabine'] ?? labels.notAvailable;
    final disembarkationDate = (data['dataDesembarque'] as Timestamp).toDate();
    final ratings = _extractRatings(data);
    final generalObservation = data['observacaoGeral'];
    final shipInfo = data['infoNavio'] as Map<String, dynamic>?;

    return PdfService.generateRatingPdf(
      shipName: item.shipName,
      shipImo: item.shipImo.isNotEmpty ? item.shipImo : null,
      evaluatorName: evaluatorName,
      evaluationDate: evaluationDate,
      cabinType: cabinType,
      disembarkationDate: disembarkationDate,
      ratings: ratings,
      generalObservation: generalObservation,
      shipInfo: shipInfo,
      labels: labels,
    );
  }

  /// Saves and shares a PDF.
  Future<void> saveAndSharePdf(dynamic pdf, String shipName) async {
    final fileName = generatePdfFileName(shipName);
    await PdfService.saveAndSharePdf(pdf, fileName);
  }

  /// Calculates the average rating from rating items.
  double calculateAverageRating(Map<String, dynamic> data) {
    final itens = data['itens'] as Map<String, dynamic>?;
    if (itens == null || itens.isEmpty) return 0.0;

    double total = 0.0;
    int count = 0;

    for (final item in itens.values) {
      if (item is Map<String, dynamic>) {
        final nota = item['nota'];
        if (nota is num) {
          total += nota.toDouble();
          count++;
        }
      }
    }

    return count > 0 ? total / count : 0.0;
  }

  /// Resolves the rating date from data.
  DateTime resolveRatingDate(Map<String, dynamic> data) {
    final ts = data['createdAt'] ?? data['data'];
    if (ts is Timestamp) {
      return ts.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Resolves evaluation date for PDF generation.
  DateTime resolveEvaluationDate(Map<String, dynamic> data) {
    return (data['createdAt'] as Timestamp?)?.toDate() ??
        (data['data'] as Timestamp?)?.toDate() ??
        DateTime.now();
  }

  /// Generates a filename for PDF export.
  String generatePdfFileName(String shipName) {
    final firstName =
        shipName.split(' ').first.replaceAll(RegExp(r'[^\w]'), '');
    return 'ShipRate_$firstName';
  }

  /// Formats date for display.
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  Future<String?> _getUserCallSign(String userId) async {
    final userSnapshot =
        await _firestore.collection(_usersCollection).doc(userId).get();

    if (!userSnapshot.exists) {
      throw Exception('Dados do usuário não encontrados');
    }

    return userSnapshot.data()?['nomeGuerra'];
  }

  bool _ratingBelongsToUser(
    Map<String, dynamic> data,
    String userId,
    String? callSign,
  ) {
    final ratingUserId = data['usuarioId'];
    final ratingCallSign = data['nomeGuerra'];

    return (ratingUserId != null && ratingUserId == userId) ||
        (ratingUserId == null &&
            callSign != null &&
            ratingCallSign == callSign);
  }

  void _sortByDateDescending(List<RatingWithShipInfo> ratings) {
    ratings.sort((a, b) {
      final aDate = resolveRatingDate(a.rating.data() as Map<String, dynamic>);
      final bDate = resolveRatingDate(b.rating.data() as Map<String, dynamic>);
      return bDate.compareTo(aDate);
    });
  }

  Map<String, Map<String, dynamic>> _extractRatings(Map<String, dynamic> data) {
    final itensData = data['itens'] as Map<String, dynamic>? ?? {};
    final ratings = <String, Map<String, dynamic>>{};

    itensData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        ratings[key] = {
          'nota': (value['nota'] as num?)?.toDouble() ?? 0.0,
          'observacao': value['observacao'] ?? '',
        };
      }
    });

    return ratings;
  }
}

// =============================================================================
// DATA CLASS
// =============================================================================

/// Data class holding a rating with its ship information.
class RatingWithShipInfo {
  final String shipName;
  final String shipImo;
  final QueryDocumentSnapshot rating;

  RatingWithShipInfo({
    required this.shipName,
    required this.shipImo,
    required this.rating,
  });
}