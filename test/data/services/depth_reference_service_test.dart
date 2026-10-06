import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/data/services/depth_reference_service.dart';

void main() {
  group('DepthReferenceService.resolve', () {
    test('maps every documented ruler location', () {
      const expectations = <String, String>{
        'Arapiri': 'Régua de Santarém (STM)',
        'Cuieiras': 'Régua de Santarém (STM)',
        'Ilha Nova': 'Régua de Santarém (STM)',
        'Patacho Sul': 'Régua de Santarém (STM)',
        'Peixe Boi': 'Régua de Santarém (STM)',
        'Prainha - Rota Sul': 'Régua de Santarém (STM)',
        'São Raimundo': 'Régua de Santarém (STM)',
        'Serpa': 'Régua de Itacoatiara (ITA)',
        'Fundeadouro Itacoatiara': 'Régua de Itacoatiara (ITA)',
        'Fundeadouro de Itacoatiara': 'Régua de Itacoatiara (ITA)',
        'Bicheira': 'Régua de Parintins (PAR)',
        'Ciganas': 'Régua de Parintins (PAR)',
        'Ilha de Parintins': 'Régua de Parintins (PAR)',
        'Ilha Parintins': 'Régua de Parintins (PAR)',
        'Mocambo': 'Régua de Parintins (PAR)',
        'Paraná dos Arcos': 'Régua de Parintins (PAR)',
        'Xibui': 'Régua de Parintins (PAR)',
        'Balaio': 'Régua de Juruti (JUR)',
        'Caldeirão': 'Régua de Juruti (JUR)',
        'Juruti/Canal': 'Régua de Juruti (JUR)',
        'Canal de Juruti': 'Régua de Juruti (JUR)',
        'Parauaquara': 'Régua de Juruti (JUR)',
        'Santa Rita': 'Régua de Juruti (JUR)',
        'Bacabal': 'Régua de Trombetas',
        'Rio Trombetas': 'Régua de Trombetas',
        'Rio Trombetas - Bacabal': 'Régua de Trombetas',
        'Bacabal / Rio Trombetas': 'Régua de Trombetas',
        'Gurupatuba': 'Régua de Almeirim',
        'Rio São Raimundo': 'Régua de Santarém (STM)',
        'Canal do Peixe Boi': 'Régua de Santarém (STM)',
      };

      for (final entry in expectations.entries) {
        final reference = DepthReferenceService.resolve(entry.key);

        expect(reference, isNotNull, reason: entry.key);
        expect(reference!.type, DepthReferenceType.ruler, reason: entry.key);
        expect(reference.displayName, entry.value, reason: entry.key);
      }
    });

    test('maps every documented Santana tide location and its qualifiers', () {
      const locations = [
        'Aruans',
        'Aruans - Enseada',
        'Aruans/Enseada',
        'Paraná de Aruans',
        'Paraná de Aruans - Enseada',
        'Jari',
        'Rio Jari',
        'Mazagão',
        'Porto de Mazagão',
        'Oiapoque',
        'Canal do Oiapoque',
        'Pracuúbas - Bijogo',
        'Pracaúbas - Bijogo',
      ];

      for (final location in locations) {
        final reference = DepthReferenceService.resolve(location);

        expect(reference, isNotNull, reason: location);
        expect(
          reference!.type,
          DepthReferenceType.santanaTide,
          reason: location,
        );
        expect(reference.displayName, 'Maré de Santana', reason: location);
      }
    });

    test('does not guess a reference for an unknown location', () {
      expect(DepthReferenceService.resolve('Local não mapeado'), isNull);
    });
  });
}
