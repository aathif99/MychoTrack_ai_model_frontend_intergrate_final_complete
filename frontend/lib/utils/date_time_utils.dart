class DateTimeUtils {
  /// Parses date and time strings (stored in UTC or local) and converts to device local DateTime.
  static DateTime? parseToLocal(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    try {
      String trimmedDate = dateStr.trim();
      String trimmedTime = (timeStr ?? '').trim();

      // If dateStr contains full ISO format (e.g. 2026-08-15T06:31:00.000Z)
      if (trimmedDate.contains('T')) {
        DateTime parsed = DateTime.parse(trimmedDate);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }

      // If timeStr is empty, default to 00:00:00
      if (trimmedTime.isEmpty) {
        trimmedTime = '00:00:00';
      }

      // If time format is HH:MM, pad to HH:MM:00
      if (trimmedTime.length == 5) {
        trimmedTime = '$trimmedTime:00';
      }

      // If time format has more precision, take HH:MM:SS
      if (trimmedTime.contains('.')) {
        trimmedTime = trimmedTime.split('.')[0];
      }

      // Parse as UTC ISO string and convert to user device local time
      final isoUtc = '${trimmedDate}T${trimmedTime}Z';
      return DateTime.parse(isoUtc).toLocal();
    } catch (_) {
      // Fallback: try parsing dateStr directly
      try {
        DateTime parsed = DateTime.parse(dateStr);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (_) {
        return null;
      }
    }
  }

  /// Formats a DateTime to DD.MM.YYYY
  static String formatDate(DateTime? dateTime, {String fallback = ''}) {
    if (dateTime == null) return fallback;
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day.$month.$year';
  }

  /// Formats a DateTime to 12-hour or 24-hour HH:MM format
  static String formatTime(DateTime? dateTime, {String fallback = '', bool use12Hour = false}) {
    if (dateTime == null) return fallback;
    if (use12Hour) {
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
