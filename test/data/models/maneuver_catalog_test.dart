import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/data/models/maneuver_catalog.dart';

void main() {
  test('catalog contains all 21 terminals used for maneuver reports', () {
    final terminals = ManeuverCatalog.ports
        .expand((port) => port.terminals)
        .toList(growable: false);

    expect(terminals, hasLength(21));
    expect(terminals.map((terminal) => terminal.id).toSet(), hasLength(21));
  });

  test('only Cargill currently has maneuver preparation information', () {
    final terminalsWithPreparation = <String>[
      for (final port in ManeuverCatalog.ports)
        for (final terminal in port.terminals)
          if (terminal.hasPreparationInfo)
            '${port.code}:${terminal.id}:${terminal.name}',
    ];

    expect(terminalsWithPreparation, equals(const ['STM:stm_cargill:Cargill']));
  });

  test('only Cargill offers preparation without a Plus subscription', () {
    final publicPreparationTerminals = <String>[
      for (final port in ManeuverCatalog.ports)
        for (final terminal in port.terminals)
          if (!terminal.preparationRequiresPlus)
            '${port.code}:${terminal.id}:${terminal.name}',
    ];

    expect(
      publicPreparationTerminals,
      equals(const ['STM:stm_cargill:Cargill']),
    );
  });
}
