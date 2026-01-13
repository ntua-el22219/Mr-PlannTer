import 'package:flutter/material.dart';
import '../data/task_model.dart';
import '../screens/new_task_screen.dart';
import './calendar_utils.dart';

class MonthViewWidget extends StatefulWidget {
  final List<Task> allTasks;
  final bool isLoading;
  final DateTime visibleMonth;
  final DateTime minMonth;
  final VoidCallback onMonthChanged;
  final Function(int) onChangeMonth;
  final VoidCallback onTasksUpdate;

  const MonthViewWidget({
    super.key,
    required this.allTasks,
    required this.isLoading,
    required this.visibleMonth,
    required this.minMonth,
    required this.onMonthChanged,
    required this.onChangeMonth,
    required this.onTasksUpdate,
  });

  @override
  State<MonthViewWidget> createState() => _MonthViewWidgetState();
}

class _MonthViewWidgetState extends State<MonthViewWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMonthNavigationBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [_buildMonthlyView()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigationBar() {
    final prevMonth = DateTime(
        widget.visibleMonth.year, widget.visibleMonth.month - 1, 1);
    final nextMonth = DateTime(
        widget.visibleMonth.year, widget.visibleMonth.month + 1, 1);
    final canGoBack = !prevMonth.isBefore(widget.minMonth);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              CalendarUtils.getMonthName(prevMonth.month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            IconButton(
              onPressed: canGoBack ? () => widget.onChangeMonth(-1) : null,
              icon: Icon(
                Icons.chevron_left,
                color: canGoBack
                    ? const Color(0xFFFCD34D)
                    : Colors.grey.shade700,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              CalendarUtils.getMonthName(widget.visibleMonth.month),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFCD34D),
              ),
            ),
            IconButton(
              onPressed: () => widget.onChangeMonth(1),
              icon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFCD34D),
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              CalendarUtils.getMonthName(nextMonth.month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final daysInMonth = DateUtils.getDaysInMonth(
      widget.visibleMonth.year,
      widget.visibleMonth.month,
    );
    final now = DateTime.now();
    final bool isCurrentVisibleMonth = widget.visibleMonth.year == now.year &&
        widget.visibleMonth.month == now.month;
    final int startDay = isCurrentVisibleMonth ? now.day : 1;
    final startDate = DateTime(
      widget.visibleMonth.year,
      widget.visibleMonth.month,
      startDay,
    );
    final daysToShow = daysInMonth - (startDay - 1);

    return Column(
      children: [
        if (widget.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: List.generate(daysToShow, (index) {
              final date = startDate.add(Duration(days: index));
              final tasksForDay =
                  CalendarUtils.getTasksForDate(date, widget.allTasks);
              final colors = [
                const Color(0xFFE8D5E8),
                const Color(0xFFC9D9E8),
                const Color(0xFFC8E5D8),
                const Color(0xFFFDE8B6),
                const Color(0xFFE8D5E8),
                const Color(0xFFD4C5E2),
                const Color(0xFFC8E5D8),
              ];
              return _buildDailyScheduleCard(
                date,
                tasksForDay,
                colors[index % colors.length],
              );
            }),
          ),
      ],
    );
  }

  Widget _buildDailyScheduleCard(
    DateTime date,
    List<Task> tasks,
    Color backgroundColor,
  ) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    List<TimeOfDay> defaultSlots;
    if (isToday) {
      final currentHour = now.hour;
      final nextHour = currentHour + 1;
      defaultSlots = [
        TimeOfDay(hour: (nextHour) % 24, minute: 0),
        TimeOfDay(hour: (nextHour + 3) % 24, minute: 0),
        TimeOfDay(hour: (nextHour + 6) % 24, minute: 0),
      ];
    } else {
      defaultSlots = [
        const TimeOfDay(hour: 10, minute: 0),
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 18, minute: 0),
      ];
    }

    final taskSlots = tasks
        .map((t) => CalendarUtils.parseTimeOfDay(t.scheduledTime))
        .where((t) => t != null)
        .cast<TimeOfDay>()
        .toList();

    final merged = <String, TimeOfDay>{};

    if (taskSlots.length >= 3) {
      for (final t in taskSlots) {
        merged['${t.hour}:${t.minute}'] = t;
      }
    } else {
      for (final t in taskSlots) {
        merged['${t.hour}:${t.minute}'] = t;
      }
      final defaultsToKeep = 3 - taskSlots.length;
      var added = 0;
      for (final d in defaultSlots) {
        final key = '${d.hour}:${d.minute}';
        if (!merged.containsKey(key)) {
          merged[key] = d;
          added++;
        }
        if (added >= defaultsToKeep) break;
      }
    }

    final timeSlots = merged.values.toList()
      ..sort(
        (a, b) => a.hour == b.hour
            ? a.minute.compareTo(b.minute)
            : a.hour.compareTo(b.hour),
      );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CalendarUtils.getDayName(date.weekday),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                Text(
                  CalendarUtils.getMonthName(date.month),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: timeSlots.map((slot) {
                final slotTasks = tasks.where((t) {
                  final parsed = CalendarUtils.parseTimeOfDay(t.scheduledTime);
                  if (parsed == null) return false;
                  return parsed.hour == slot.hour &&
                      parsed.minute == slot.minute;
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CalendarUtils.formatTimeOfDay(slot),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          _showAddOptionsForSlot(context, date, slot),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: backgroundColor.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (slotTasks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...slotTasks.map((task) {
                        return Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: task.type == 'deadline'
                                  ? Colors.red
                                  : Colors.blue,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOptionsForSlot(
      BuildContext context, DateTime date, TimeOfDay time) async {
    await showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE082),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                "New Task",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(
                Icons.check_box_outlined,
                color: Colors.black,
              ),
              onTap: () async {
                Navigator.pop(c);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => NewTaskScreen(
                      initialType: 'task',
                      initialDate: date,
                      initialTime: time,
                    ),
                  ),
                );
                if (result == true) widget.onTasksUpdate();
              },
            ),
            ListTile(
              title: const Text(
                "New Deadline",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.timer, color: Colors.black),
              onTap: () async {
                Navigator.pop(c);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => NewTaskScreen(
                      initialType: 'deadline',
                      initialDate: date,
                      initialTime: time,
                    ),
                  ),
                );
                if (result == true) widget.onTasksUpdate();
              },
            ),
          ],
        ),
      ),
    );
  }
}
