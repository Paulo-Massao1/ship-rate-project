import 'package:flutter_test/flutter_test.dart';
import 'package:ship_rate/core/measurement_formatter.dart';

void main() {
  group('MeasurementFormatter.meters', () {
    test('removes floating-point artifacts', () {
      expect(MeasurementFormatter.meters(13.799999999999999), '13,8m');
      expect(MeasurementFormatter.meters(15.399999999999999), '15,4m');
    });

    test('keeps up to two meaningful decimal places', () {
      expect(MeasurementFormatter.meters(13.79), '13,79m');
      expect(MeasurementFormatter.meters(13.05), '13,05m');
      expect(MeasurementFormatter.meters(12.35), '12,35m');
      expect(MeasurementFormatter.meters(17), '17,0m');
    });

    test('normalizes numeric strings and existing units', () {
      expect(MeasurementFormatter.meters('13,80'), '13,8m');
      expect(MeasurementFormatter.meters('16.20m'), '16,2m');
    });

    test('returns the empty marker for missing or invalid values', () {
      expect(MeasurementFormatter.meters(null), '—');
      expect(MeasurementFormatter.meters(''), '—');
      expect(MeasurementFormatter.meters('invalid'), '—');
    });
  });

  test('rounds values before persistence', () {
    expect(MeasurementFormatter.toHundredths(13.799999999999999), 13.8);
    expect(MeasurementFormatter.toHundredths(12.34 + 1.45), 13.79);
    expect(MeasurementFormatter.toHundredths(13.054), 13.05);
    expect(MeasurementFormatter.toHundredths(13.055), 13.06);
  });
}
