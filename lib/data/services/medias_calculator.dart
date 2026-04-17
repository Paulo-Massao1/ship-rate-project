/// Shared utility for computing aggregated ship rating averages ("medias").
///
/// Single source of truth for:
/// - Official rating criteria order
/// - Mapping from full criteria names to the short keys persisted in the
///   `medias` field on a ship document
/// - The calculation algorithm (sum scores > 0 per criterion, divide by count,
///   format as String with one decimal place)
///
/// ⚠️ CRITICAL: Do NOT change the criteria list or key map without migrating
/// existing Firestore data — they define the persisted document structure.
class MediasCalculator {
  static const List<String> ratingCriteria = [
    'Dispositivo de Embarque/Desembarque',
    'Temperatura da Cabine',
    'Limpeza da Cabine',
    'Passadiço – Equipamentos',
    'Passadiço – Temperatura',
    'Comida',
    'Relacionamento com comandante/tripulação',
  ];

  static const Map<String, String> averageKeyMap = {
    'Dispositivo de Embarque/Desembarque': 'dispositivo',
    'Temperatura da Cabine': 'temp_cabine',
    'Limpeza da Cabine': 'limpeza_cabine',
    'Passadiço – Equipamentos': 'passadico_equip',
    'Passadiço – Temperatura': 'passadico_temp',
    'Comida': 'comida',
    'Relacionamento com comandante/tripulação': 'relacionamento',
  };

  /// Calculates averaged scores per criterion from the given ratings.
  ///
  /// Each entry in [ratings] is expected to be a rating document's data map
  /// containing an `itens` map keyed by criterion name. Scores of zero or
  /// missing values are ignored.
  ///
  /// Returns a map of short keys to averages formatted with one decimal place.
  /// Criteria with no valid scores are omitted from the result.
  static Map<String, String> calculate(Iterable<Map<String, dynamic>> ratings) {
    final totals = {for (final c in ratingCriteria) c: 0.0};
    final counts = {for (final c in ratingCriteria) c: 0};

    for (final rating in ratings) {
      final items = rating['itens'] as Map?;
      if (items == null) continue;

      for (final criterion in ratingCriteria) {
        final value = items[criterion];
        if (value is Map) {
          final score = _toDouble(value['nota']);
          if (score > 0) {
            totals[criterion] = totals[criterion]! + score;
            counts[criterion] = counts[criterion]! + 1;
          }
        }
      }
    }

    final averages = <String, String>{};
    for (final criterion in ratingCriteria) {
      if (counts[criterion]! > 0) {
        final average = totals[criterion]! / counts[criterion]!;
        averages[averageKeyMap[criterion] ?? criterion.toLowerCase()] =
            average.toStringAsFixed(1);
      }
    }

    return averages;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }
}
