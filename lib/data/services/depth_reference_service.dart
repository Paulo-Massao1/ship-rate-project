import '../models/tide_entry.dart';
import 'tide_data_service.dart';

enum DepthReferenceType { ruler, santanaTide }

class DepthReference {
  final DepthReferenceType type;
  final String name;
  final String? code;

  const DepthReference({required this.type, required this.name, this.code});

  String get displayName => code == null ? name : '$name ($code)';
}

class TideReferenceEvent {
  final DateTime dateTime;
  final double height;
  final bool isHighTide;

  const TideReferenceEvent({
    required this.dateTime,
    required this.height,
    required this.isHighTide,
  });
}

class SantanaTideWindow {
  final TideReferenceEvent? previousTide;
  final TideReferenceEvent? nextTide;

  const SantanaTideWindow({required this.previousTide, required this.nextTide});

  bool get hasData => previousTide != null || nextTide != null;
}

/// Resolves the depth reference used by each passage location.
///
/// Ruler values are intentionally not loaded here. They change daily and will
/// come from WebPilot once its API is available. The service currently owns
/// only the stable location-to-reference mapping and the offline Santana tide
/// lookup.
class DepthReferenceService {
  DepthReferenceService._();

  static const _santanaTide = DepthReference(
    type: DepthReferenceType.santanaTide,
    name: 'Maré de Santana',
  );

  static const Map<String, DepthReference> _rulersByLocation = {
    'arapiri': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'cuieiras': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'ilha nova': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'patacho sul': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'peixe boi': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'sao raimundo': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Santarém',
      code: 'STM',
    ),
    'serpa': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Itacoatiara',
      code: 'ITA',
    ),
    'fundeadouro itacoatiara': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Itacoatiara',
      code: 'ITA',
    ),
    'fundeadouro de itacoatiara': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Itacoatiara',
      code: 'ITA',
    ),
    'bicheira': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'ciganas': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'ilha de parintins': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'ilha parintins': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'mocambo': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'parana dos arcos': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'xibui': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Parintins',
      code: 'PAR',
    ),
    'balaio': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'caldeirao': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'juruti': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'juruti canal': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'canal de juruti': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'parauaquara': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'santa rita': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Juruti',
      code: 'JUR',
    ),
    'bacabal': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Trombetas',
    ),
    'rio trombetas': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Trombetas',
    ),
    'rio trombeta': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Trombetas',
    ),
    'trombetas': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Trombetas',
    ),
    'trombeta': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Trombetas',
    ),
    'gurupatuba': DepthReference(
      type: DepthReferenceType.ruler,
      name: 'Régua de Almeirim',
    ),
  };

  static const Set<String> _santanaLocations = {
    'aruans',
    'parana de aruans',
    'jari',
    'mazagao',
    'oiapoque',
    'pracaubas bijogo',
    'pracuubas bijogo',
  };

  static DepthReference? resolve(String? locationName) {
    final normalized = _normalize(locationName ?? '');
    if (normalized.isEmpty) return null;

    if (_matchesKnownLocation(normalized, _santanaLocations)) {
      return _santanaTide;
    }
    if (normalized.startsWith('prainha')) {
      return const DepthReference(
        type: DepthReferenceType.ruler,
        name: 'Régua de Santarém',
        code: 'STM',
      );
    }

    for (final entry in _rulersByLocation.entries) {
      if (_matchesKnownLocation(normalized, {entry.key})) return entry.value;
    }

    return null;
  }

  /// Accepts the stable reference name with an operational qualifier, such as
  /// "Aruans - Enseada", without guessing a reference for unknown locations.
  static bool _matchesKnownLocation(String normalized, Set<String> aliases) {
    for (final alias in aliases) {
      if (normalized == alias ||
          normalized.startsWith('$alias ') ||
          normalized.endsWith(' $alias')) {
        return true;
      }
    }
    return false;
  }

  static Future<SantanaTideWindow> loadSantanaTideWindow(
    DateTime measurement,
  ) async {
    final location = await TideDataService.getLocation('santana');
    final events = <({DateTime dateTime, TideEntry tide})>[];

    for (var offset = -1; offset <= 1; offset++) {
      final day = DateTime(
        measurement.year,
        measurement.month,
        measurement.day + offset,
      );

      for (final tide in location.entriesForDate(day)) {
        final timeParts = tide.time.split(':');
        if (timeParts.length != 2) continue;

        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour == null || minute == null) continue;

        events.add((
          dateTime: DateTime(day.year, day.month, day.day, hour, minute),
          tide: tide,
        ));
      }
    }

    TideReferenceEvent? previousTide;
    TideReferenceEvent? nextTide;

    for (final event in events) {
      if (!event.dateTime.isAfter(measurement) &&
          (previousTide == null ||
              event.dateTime.isAfter(previousTide.dateTime))) {
        previousTide = TideReferenceEvent(
          dateTime: event.dateTime,
          height: event.tide.height,
          isHighTide: event.tide.isHighTide,
        );
      }

      if (event.dateTime.isAfter(measurement) &&
          (nextTide == null || event.dateTime.isBefore(nextTide.dateTime))) {
        nextTide = TideReferenceEvent(
          dateTime: event.dateTime,
          height: event.tide.height,
          isHighTide: event.tide.isHighTide,
        );
      }
    }

    return SantanaTideWindow(previousTide: previousTide, nextTide: nextTide);
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp('[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(' +'), ' ')
        .trim();
  }
}
