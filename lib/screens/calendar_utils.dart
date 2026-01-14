import 'package:flutter/material.dart';
import '../data/task_model.dart';
import '../data/recurrence_helper.dart';

/// Shared utilities and helper methods for calendar views
class CalendarUtils {
  /// Get tasks for a specific date
  static List<Task> getTasksForDate(DateTime date, List<Task> allTasks) {
    return allTasks.where((task) {
      if (task.scheduledDate.isEmpty) return false;
      try {
        final taskDate = DateTime.parse(task.scheduledDate);
        final sameDay = taskDate.year == date.year &&
            taskDate.month == date.month &&
            taskDate.day == date.day;

        if (task.recurrenceRule.isEmpty) return sameDay;
        return sameDay || RecurrenceHelper.occursOnDate(task, date);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Get today's tasks
  static List<Task> getTodayTasks(List<Task> allTasks) {
    final today = DateTime.now();
    return getTasksForDate(today, allTasks);
  }

  /// Get current time for a timezone
  static String getCurrentTime(String timezone) {
    final now = DateTime.now();
    if (timezone == 'Athens') {
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    } else if (timezone == 'BuenosAires') {
      final baTime = now.subtract(const Duration(hours: 5));
      return '${baTime.hour.toString().padLeft(2, '0')}:${baTime.minute.toString().padLeft(2, '0')}';
    }
    return '00:00';
  }

  /// Get day name from weekday number
  static String getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Get month name from month number
  static String getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  /// Parse TimeOfDay from string
  static TimeOfDay? parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Format TimeOfDay to string
  static String formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final suffix = t.period == DayPeriod.am ? 'am' : 'pm';
    if (t.minute == 0) {
      return '$hour$suffix';
    }
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute$suffix';
  }
}
