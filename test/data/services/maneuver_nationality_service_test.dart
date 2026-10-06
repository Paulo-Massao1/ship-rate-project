import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/data/services/maneuver_nationality_service.dart';

void main() {
  test('normalizes shared maneuver nationality names consistently', () {
    expect(
      ManeuverNationalityService.normalizeName('  Sul-africana  '),
      'SUL AFRICANA',
    );
    expect(
      ManeuverNationalityService.normalizeName('Portuguesa'),
      'PORTUGUESA',
    );
  });
}
