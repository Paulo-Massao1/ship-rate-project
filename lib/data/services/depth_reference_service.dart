import '../models/tide_entry.dart';
import 'tide_data_service.dart';

enum DepthReferenceType { ruler, santanaTide }

class DepthReference {
  final DepthReferenceType type;
  final String name;
  final String? code;

  const DepthReference({
    required this.type,
    required this.name,
    this.code,
  });

  String get displayName => code == null ? name : '$name ($code)';
}

class TideReferenceEvent {
  final DateTime dateTime;
  final double height;

  const TideReferenceEvent({
    required this.dateTime,
    required this.height,
  });
}

class SantanaTideWindow {
  final TideReferenceEvent? previousLowTide;
  final TideReferenceEvent? nextHighTide;

  const SantanaTideWindow({
    required this.previousLowTide,
    required this.nextHighTide,
  });

  bool get hasData => previousLowTide != null || nextHighTide != null;
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

    if (_santanaLocations.contains(normalized)) return _santanaTide;
    if (normalized.startsWith('prainha')) {
      return const DepthReference(
        type: DepthReferenceType.ruler,
        name: 'Régua de Santarém',
        code: 'STM',
      );
    }

    return _rulersByLocation[normalized];
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

    TideReferenceEvent? previousLowTide;
    TideReferenceEvent? nextHighTide;

    for (final event in events) {
      if (!event.tide.isHighTide &&
          !event.dateTime.isAfter(measurement) &&
          (previousLowTide == null ||
              event.dateTime.isAfter(previousLowTide.dateTime))) {
        previousLowTide = TideReferenceEvent(
          dateTime: event.dateTime,
          height: event.tide.height,
        );
      }

      if (event.tide.isHighTide &&
          !event.dateTime.isBefore(measurement) &&
          (nextHighTide == null ||
              event.dateTime.isBefore(nextHighTide.dateTime))) {
        nextHighTide = TideReferenceEvent(
          dateTime: event.dateTime,
          height: event.tide.height,
        );
      }
    }

    return SantanaTideWindow(
      previousLowTide: previousLowTide,
      nextHighTide: nextHighTide,
    );
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
