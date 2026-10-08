import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/data/models/maneuver_report.dart';

void main() {
  test(
    'stores maneuver current direction as up or down instead of degrees',
    () {
      const draft = ManeuverReportDraft(
        portName: 'Santarém',
        portCode: 'STM',
        terminalId: 'stm_cargill',
        terminalName: 'Cargill',
        currentDirection: ManeuverCurrentDirection.upstream,
        currentIntensityKnots: 1.5,
      );

      final data = draft.toFirestore(pilotId: 'pilot-id');
      final approach = data['approach']! as Map<String, dynamic>;

      expect(data['schemaVersion'], 4);
      expect(approach['currentDirection'], 'subindo');
      expect(approach['currentIntensityKnots'], 1.5);
      expect(approach, isNot(contains('currentDirectionDegrees')));
    },
  );

  test('parses the persisted current direction values', () {
    expect(
      ManeuverCurrentDirection.fromFirestore('subindo'),
      ManeuverCurrentDirection.upstream,
    );
    expect(
      ManeuverCurrentDirection.fromFirestore('baixando'),
      ManeuverCurrentDirection.downstream,
    );
  });

  test('preserves a legacy current direction while editing old reports', () {
    const draft = ManeuverReportDraft(
      portName: 'Santarém',
      portCode: 'STM',
      terminalId: 'stm_cargill',
      terminalName: 'Cargill',
      currentDirectionDegrees: 288,
    );

    final data = draft.toFirestore(pilotId: 'pilot-id');
    final approach = data['approach']! as Map<String, dynamic>;

    expect(approach['currentDirectionDegrees'], 288);
    expect(approach, isNot(contains('currentDirection')));
  });
}
