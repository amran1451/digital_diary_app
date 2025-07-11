class WellBeingUtils {
  static const okValue = 'OK';
  static const okLabel = 'Всё хорошо';

  static String format(String? value) {
    if (value == null || value.isEmpty) return '';
    return value == okValue ? okLabel : value;
  }

  static String normalize(String value) {
    final trimmed = value.trim();
    return trimmed == okLabel ? okValue : trimmed;
  }
}