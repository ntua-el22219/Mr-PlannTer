import 'task_model.dart';

// Google Calendar-like recurrence patterns
class RecurrencePattern {
  static const String NONE = 'NONE';
  static const String DAILY = 'DAILY';
  static const String WEEKLY = 'WEEKLY';
  static const String BIWEEKLY = 'BIWEEKLY';
  static const String MONTHLY = 'MONTHLY';
  static const String YEARLY = 'YEARLY';
  static const String CUSTOM = 'CUSTOM';
}

class RecurrenceHelper {
  /// Returns true if a recurring task occurs on [date]. Non-recurring returns false.
  static bool occursOnDate(Task task, DateTime date) {
    final rule = task.recurrenceRule;
    final startDateStr = task.scheduledDate;
    if (rule.isEmpty || rule == 'NONE' || startDateStr.isEmpty) return false;

    DateTime? start;
    try {
      start = DateTime.parse(startDateStr);
    } catch (_) {
      return false;
    }

    // Normalize date to date-only for comparisons
    final target = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(start.year, start.month, start.day);
    if (target.isBefore(startDate)) return false;

    final parsed = parseRule(rule);
    final freq = (parsed['frequency'] as String).toUpperCase();
    final interval = parsed['interval'] as int? ?? 1;
    final byDay = (parsed['byDay'] as List<String>? ?? [])
        .map((d) => d.toUpperCase())
        .toList();
    final endType = parsed['endType'] as String? ?? 'never';
    final endDateStr = parsed['endDate'] as String? ?? '';
    final endCountStr = parsed['endCount'] as String? ?? '';

    // End date check
    if (endType == 'onDate' && endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
        if (target.isAfter(endOnly)) return false;
      } catch (_) {
        /* ignore */
      }
    }

    // Helper: weekday code
    String _weekdayCode(int weekday) {
      const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return codes[weekday - 1];
    }

    // Count-based termination
    int? maxCount;
    if (endType == 'afterCount' && endCountStr.isNotEmpty) {
      maxCount = int.tryParse(endCountStr);
    }

    int occurrenceIndex = 0; // zero-based

    bool occurs = false;
    switch (freq) {
      case 'DAILY':
        final daysDiff = target.difference(startDate).inDays;
        if (daysDiff % interval == 0) {
          occurrenceIndex = daysDiff ~/ interval;
          occurs = true;
        }
        break;
      case 'WEEKLY':
      case 'BIWEEKLY': // treat as interval 2 weeks
        final weeksInterval = freq == 'BIWEEKLY' ? 2 : interval;
        final daysDiff = target.difference(startDate).inDays;
        final weeksDiff = daysDiff ~/ 7;
        final sameWeekday =
            byDay.isEmpty || byDay.contains(_weekdayCode(target.weekday));
        if (sameWeekday && weeksDiff % weeksInterval == 0) {
          occurrenceIndex = weeksDiff;
          occurs = true;
        }
        break;
      case 'MONTHLY':
        final monthsDiff =
            (target.year - startDate.year) * 12 +
            (target.month - startDate.month);
        final sameDay = target.day == startDate.day;
        if (monthsDiff % interval == 0 && sameDay) {
          occurrenceIndex = monthsDiff ~/ interval;
          occurs = true;
        }
        break;
      case 'YEARLY':
        final yearsDiff = target.year - startDate.year;
        final sameMd =
            target.month == startDate.month && target.day == startDate.day;
        if (yearsDiff % interval == 0 && sameMd) {
          occurrenceIndex = yearsDiff ~/ interval;
          occurs = true;
        }
        break;
      default:
        occurs = false;
    }

    if (!occurs) return false;
    if (maxCount != null && occurrenceIndex + 1 > maxCount) return false;
    return true;
  }

  // Parse recurrence rule from RRULE format
  static Map<String, dynamic> parseRule(String rule) {
    if (rule.isEmpty || rule == 'NONE') {
      return {
        'frequency': 'NONE',
        'interval': 1,
        'byDay': [],
        'endType': 'never', // 'never', 'onDate', 'afterCount'
        'endDate': '',
        'endCount': '',
      };
    }

    final parts = rule.split(';');
    final result = {
      'frequency': 'NONE',
      'interval': 1,
      'byDay': <String>[],
      'endType': 'never',
      'endDate': '',
      'endCount': '',
    };

    for (var part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length != 2) continue;

      final key = keyValue[0].trim();
      final value = keyValue[1].trim();

      switch (key) {
        case 'FREQ':
          result['frequency'] = value;
          break;
        case 'INTERVAL':
          result['interval'] = int.tryParse(value) ?? 1;
          break;
        case 'BYDAY':
          result['byDay'] = value.split(',');
          break;
        case 'UNTIL':
          result['endType'] = 'onDate';
          result['endDate'] = value;
          break;
        case 'COUNT':
          result['endType'] = 'afterCount';
          result['endCount'] = value;
          break;
      }
    }

    return result;
  }

  // Build RRULE from recurrence data
  static String buildRule({
    required String frequency,
    int interval = 1,
    List<String> byDay = const [],
    String endType = 'never',
    String endDate = '',
    String endCount = '',
  }) {
    if (frequency == 'NONE' || frequency.isEmpty) {
      return '';
    }

    final parts = ['FREQ=$frequency'];

    if (interval > 1) {
      parts.add('INTERVAL=$interval');
    }

    if (byDay.isNotEmpty) {
      parts.add('BYDAY=${byDay.join(",")}');
    }

    if (endType == 'onDate' && endDate.isNotEmpty) {
      parts.add('UNTIL=$endDate');
    } else if (endType == 'afterCount' && endCount.isNotEmpty) {
      parts.add('COUNT=$endCount');
    }

    return parts.join(';');
  }

  // Get human-readable description of recurrence
  static String getDescription(String rule) {
    if (rule.isEmpty || rule == 'NONE') {
      return 'Does not repeat';
    }

    final parsed = parseRule(rule);
    final frequency = parsed['frequency'] as String;
    final interval = parsed['interval'] as int;
    final byDay = parsed['byDay'] as List<String>;

    String description = '';

    switch (frequency) {
      case 'DAILY':
        description = interval == 1 ? 'Daily' : 'Every $interval days';
        break;
      case 'WEEKLY':
        description = interval == 1 ? 'Weekly' : 'Every $interval weeks';
        if (byDay.isNotEmpty) {
          final days = _formatDays(byDay);
          description += ' on $days';
        }
        break;
      case 'BIWEEKLY':
        description = 'Every 2 weeks';
        if (byDay.isNotEmpty) {
          final days = _formatDays(byDay);
          description += ' on $days';
        }
        break;
      case 'MONTHLY':
        description = interval == 1 ? 'Monthly' : 'Every $interval months';
        break;
      case 'YEARLY':
        description = 'Yearly';
        break;
      default:
        description = 'Custom';
    }

    // Add end condition
    final endType = parsed['endType'] as String;
    final endDate = parsed['endDate'] as String;
    final endCount = parsed['endCount'] as String;

    if (endType == 'onDate' && endDate.isNotEmpty) {
      description += ' until $endDate';
    } else if (endType == 'afterCount' && endCount.isNotEmpty) {
      description += ' ($endCount times)';
    }

    return description;
  }

  static String _formatDays(List<String> days) {
    const dayMap = {
      'MO': 'Monday',
      'TU': 'Tuesday',
      'WE': 'Wednesday',
      'TH': 'Thursday',
      'FR': 'Friday',
      'SA': 'Saturday',
      'SU': 'Sunday',
    };

    return days.map((d) => dayMap[d] ?? d).join(', ');
  }

  // Get short RRULE format for display (e.g., "Weekly on Mon, Wed, Fri")
  static String getShortDescription(String rule) {
    if (rule.isEmpty || rule == 'NONE') {
      return 'No repeat';
    }

    final parsed = parseRule(rule);
    final frequency = parsed['frequency'] as String;
    final byDay = parsed['byDay'] as List<String>;

    switch (frequency) {
      case 'DAILY':
        return 'Daily';
      case 'WEEKLY':
        if (byDay.isNotEmpty) {
          final days = byDay.map((d) => d.substring(0, 1)).join(',');
          return 'Weekly on $days';
        }
        return 'Weekly';
      case 'BIWEEKLY':
        return 'Bi-weekly';
      case 'MONTHLY':
        return 'Monthly';
      case 'YEARLY':
        return 'Yearly';
      default:
        return 'Repeats';
    }
  }
}
