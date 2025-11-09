import 'package:intl/intl.dart';

/// Date utility functions
class DateUtils {
  /// Format date to readable string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format date to time string
  static String formatTime(DateTime date, {String format = 'hh:mm a'}) {
    return DateFormat(format).format(date);
  }

  /// Get days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of week
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get end of week
  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Add days to date
  static DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }

  /// Subtract days from date
  static DateTime subtractDays(DateTime date, int days) {
    return date.subtract(Duration(days: days));
  }

  /// Get relative time string (e.g., "2 days ago", "in 3 days")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes.abs()} minutes ${difference.isNegative ? "ago" : "from now"}';
      }
      return '${difference.inHours.abs()} hours ${difference.isNegative ? "ago" : "from now"}';
    } else if (difference.inDays.abs() < 7) {
      return '${difference.inDays.abs()} days ${difference.isNegative ? "ago" : "from now"}';
    } else if (difference.inDays.abs() < 30) {
      final weeks = (difference.inDays.abs() / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ${difference.isNegative ? "ago" : "from now"}';
    } else {
      final months = (difference.inDays.abs() / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ${difference.isNegative ? "ago" : "from now"}';
    }
  }

  /// Calculate cycle phase
  static String getCyclePhase(DateTime cycleStart, int cycleDay) {
    if (cycleDay <= 5) {
      return 'menstrual';
    } else if (cycleDay <= 13) {
      return 'follicular';
    } else if (cycleDay <= 16) {
      return 'ovulation';
    } else {
      return 'luteal';
    }
  }

  /// Calculate ovulation date (typically day 14 of cycle)
  static DateTime calculateOvulationDate(DateTime cycleStart, int cycleLength) {
    return addDays(cycleStart, cycleLength - 14);
  }

  /// Calculate fertile window (5 days before ovulation, 1 day after)
  static Map<String, DateTime> calculateFertileWindow(
      DateTime cycleStart, int cycleLength) {
    final ovulationDate = calculateOvulationDate(cycleStart, cycleLength);
    return {
      'start': subtractDays(ovulationDate, 5),
      'end': addDays(ovulationDate, 1),
    };
  }
}
