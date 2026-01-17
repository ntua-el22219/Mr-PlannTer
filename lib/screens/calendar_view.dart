import '../theme/importance_colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/task_model.dart';
import '../data/database_helper.dart';
import '../services/google_calendar_service.dart';
import './calendar_utils.dart';

class CalendarViewWidget extends StatefulWidget {
  final List<Task> allTasks;
  final bool isLoading;
  final bool isSyncing;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay) onPageChanged;
  final VoidCallback onTasksUpdate;
  final Function(String direction) onSync;

  const CalendarViewWidget({
    super.key,
    required this.allTasks,
    required this.isLoading,
    required this.isSyncing,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onTasksUpdate,
    required this.onSync,
  });

  @override
  State<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends State<CalendarViewWidget> {
  late CalendarFormat _calendarFormat;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayTasks = widget.selectedDay != null
        ? CalendarUtils.getTasksForDate(widget.selectedDay!, widget.allTasks)
        : <Task>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCD34D),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: widget.focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  isSameDay(widget.selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                widget.onDaySelected(selectedDay, focusedDay);
              },
              onPageChanged: (focusedDay) {
                widget.onPageChanged(focusedDay);
              },
              eventLoader: (day) {
                return CalendarUtils.getTasksForDate(day, widget.allTasks);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  final tasks = events.cast<Task>();
                  final hasDeadline = tasks.any((t) => t.type == 'deadline');
                  final hasTask = tasks.any((t) => t.type == 'task');

                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasTask)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E40AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasDeadline)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E40AF), width: 2),
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF1E40AF),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 2,
                markersAlignment: Alignment.bottomCenter,
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1E40AF),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color(0xFF1E40AF),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ),
        ),
        if (widget.selectedDay != null) ...[
          if (selectedDayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks for this day',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...selectedDayTasks
                .map((task) => _buildCalendarTaskCard(task))
                .toList(),
        ],
        _buildGoogleSyncButton(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCalendarTaskCard(Task task) {
    final color = getImportanceColor(
      type: task.type,
      importance: task.importance,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.type == 'deadline' ? Colors.red : const Color(0xFF1E40AF),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.type == 'deadline'
                ? Icons.alarm
                : Icons.check_circle_outline,
            color: task.type == 'deadline'
                ? Colors.red
                : const Color(0xFF1E40AF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                task.scheduledTime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              if (task.duration > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${task.duration} min',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSyncButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: widget.isSyncing
            ? const CircularProgressIndicator()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showSyncOptions,
                    icon: const Icon(Icons.sync),
                    label: const Text('Google Calendar Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Google Calendar Sync',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.blue),
                title: const Text('Export to Google Calendar'),
                subtitle: const Text('Send your tasks to Google Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSync('export');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Import from Google Calendar'),
                subtitle: const Text('Get events from Google Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSync('import');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.purple),
                title: const Text('Two-way Sync'),
                subtitle: const Text('Export tasks & import events'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSync('both');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}