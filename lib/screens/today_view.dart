import 'package:flutter/material.dart';
import 'dart:async';
import '../data/task_model.dart';
import '../data/database_helper.dart';
import '../theme/text_styles.dart';
import './calendar_utils.dart';

class TodayViewWidget extends StatefulWidget {
  final List<Task> allTasks;
  final bool isLoading;
  final VoidCallback onTasksUpdate;

  const TodayViewWidget({
    super.key,
    required this.allTasks,
    required this.isLoading,
    required this.onTasksUpdate,
  });

  @override
  State<TodayViewWidget> createState() => _TodayViewWidgetState();
}

class _TodayViewWidgetState extends State<TodayViewWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Update time every 100ms for smooth, responsive updates
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = CalendarUtils.getTodayTasks(widget.allTasks);

    return Column(
      children: [
        _buildTodayTasks(todayTasks, context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTodayTasks(List<Task> todayTasks, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Todays tasks',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: const Color(0xFFFCD34D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Reminders',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFCD34D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (todayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No tasks for today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...todayTasks
                .map((task) => _buildTaskCard(task, context))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, BuildContext context) {
    final isDeadline = task.type == 'deadline';
    final defaultBackgroundColor = isDeadline
        ? const Color(0xFFD4BBA8)
        : const Color(0xFFC5D9F0);
    final backgroundColor = task.colorValue != null
        ? Color(task.colorValue!)
        : defaultBackgroundColor;

    final timeParts = task.scheduledTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final startTime = TimeOfDay(hour: hour, minute: minute);
    final endMinute = (minute + task.duration) % 60;
    final endHour = hour + ((minute + task.duration) ~/ 60);
    final endTime = TimeOfDay(hour: endHour, minute: endMinute);

    return GestureDetector(
      onTap: () => _showColorPickerDialog(task),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isDeadline)
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      task.scheduledTime,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Ends in 3 hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${startTime.format(context)} Start',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${task.duration} Min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${endTime.format(context)} End',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(Task task) {
    final colors = [
      const Color(0xFFC5D9F0),
      const Color(0xFFD4BBA8),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCB77),
      const Color(0xFF4D96FF),
      const Color(0xFFFF6B6B),
      const Color(0xFFA78BFA),
      const Color(0xFFFFA500),
    ];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Task Color',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: colors.map((color) {
                  final isSelected = task.colorValue == color.value;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _updateTaskColor(task, color);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : Border.all(color: Colors.grey.shade400, width: 1),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateTaskColor(Task task, Color color) async {
    try {
      await DatabaseHelper().updateTaskColor(task.id!, color.value);
      widget.onTasksUpdate();
    } catch (e) {
      debugPrint('Error updating task color: $e');
    }
  }
}
