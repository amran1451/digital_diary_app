import 'dart:math';

/// Utilities for parsing numeric values from strings.
class ParseUtils {
  static double parseDouble(String? value) {
    if (value == null) return 0.0;
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }


  /// Parses a time duration string and returns hours as a double.
  ///
  /// Supports formats like "7:30", "7.5", "7ч 30м".
  static double parseHours(String? value) {
    if (value == null) return 0.0;
    final s = value.toLowerCase();

    // HH:MM or H:MM
    final hmMatch = RegExp(r'^(\d{1,2})[:.](\d{1,2})').firstMatch(s);
    if (hmMatch != null) {
      final h = int.tryParse(hmMatch.group(1) ?? '') ?? 0;
      final m = int.tryParse(hmMatch.group(2) ?? '') ?? 0;
      return h + m / 60.0;
    }

    // Xч Yм or Xч
    final chMatch = RegExp(r'(\d+)\s*ч\s*(\d+)?').firstMatch(s);
    if (chMatch != null) {
      final h = int.tryParse(chMatch.group(1) ?? '') ?? 0;
      final m = int.tryParse(chMatch.group(2) ?? '0') ?? 0;
      return h + m / 60.0;
    }

    // Decimal number like "7.5" or "7,5"
    final num = double.tryParse(s.replaceAll(',', '.'));
    if (num != null) return num;

    // Fallback to digits only
    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    if (digits != null) return double.tryParse(digits) ?? 0.0;

    return 0.0;
  }
}