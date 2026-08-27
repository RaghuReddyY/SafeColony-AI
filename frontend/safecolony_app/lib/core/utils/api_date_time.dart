/// Date/time helpers for values received from the SafeColony API.
///
/// The backend's existing SQL DateTime columns store UTC without timezone
/// metadata. DateTime.parse() treats a timezone-less string as local time,
/// which shifts the displayed clock on devices in India. This helper treats
/// timezone-less API timestamps as UTC and leaves already-zoned values intact.
class ApiDateTime {
  static DateTime parse(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      throw const FormatException('API timestamp is empty.');
    }

    final parsed = DateTime.parse(text);
    if (parsed.isUtc || _hasTimezone(text)) {
      return parsed;
    }

    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    try {
      return parse(value);
    } catch (_) {
      return null;
    }
  }

  static bool _hasTimezone(String value) {
    // ISO-8601 timezone suffix: Z or ±HH:mm / ±HHmm.
    return RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  }
}
