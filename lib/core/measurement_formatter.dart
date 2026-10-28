/// Consistent formatting for navigation measurements stored as numbers or
/// numeric strings in Firestore.
abstract final class MeasurementFormatter {
  /// Formats meters with at most two decimal places and at least one.
  ///
  /// Rounding before rendering removes binary floating-point artifacts such
  /// as `13.799999999999999` while preserving values such as `13.05`.
  static String meters(
    dynamic value, {
    String emptyValue = '—',
    String decimalSeparator = ',',
  }) {
    if (value == null) return emptyValue;

    final raw = value.toString().trim();
    if (raw.isEmpty || raw == emptyValue) return emptyValue;

    final numericText =
        raw.toLowerCase().endsWith('m')
            ? raw.substring(0, raw.length - 1).trim()
            : raw;
    final number =
        value is num
            ? value.toDouble()
            : double.tryParse(numericText.replaceAll(',', '.'));

    if (number == null || !number.isFinite) return emptyValue;

    var formatted = number.toStringAsFixed(2);
    if (formatted == '-0.00') formatted = '0.00';
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return '${formatted.replaceAll('.', decimalSeparator)}m';
  }

  /// Rounds a value to the precision persisted for depth records.
  static double toHundredths(double value) => (value * 100).round() / 100;
}
