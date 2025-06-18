import 'dart:math';

/// Utilities for parsing numeric values from strings.
class ParseUtils {
  static double parseDouble(String? value) {
    if (value == null) return 0.0;
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }
}