import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/text_styles.dart';
import 'package:table_calendar/table_calendar.dart';
import 'settings_screen.dart';
import 'new_task_screen.dart';
import '../widgets/cloudy_background.dart';
import '../data/database_helper.dart';
import '../data/task_model.dart';
import '../data/recurrence_helper.dart';
import '../services/google_calendar_service.dart';

enum CalendarView { today, month, calendar }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarView _currentView = CalendarView.today;
  late DateTime _visibleMonth;
  late DateTime _minMonth;
  Timer? _timeUpdateTimer;
  String _currentTime = '';

  List<Task> _allTasks = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _minMonth = _visibleMonth;
    _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _loadTasks();
    
    // Update time display every second
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final newTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        if (_currentTime != newTime) {
          setState(() {
            _currentTime = newTime;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final data = await DatabaseHelper().queryAllTasks();
      if (mounted) {
        setState(() {
          _allTasks = data.map((e) => Task.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Task> _getTasksForDate(DateTime date) {
    return _allTasks.where((task) {
      if (task.scheduledDate.isEmpty) return false;
      try {
        final taskDate = DateTime.parse(task.scheduledDate);
        final sameDay =
            taskDate.year == date.year &&
            taskDate.month == date.month &&
            taskDate.day == date.day;

        if (task.recurrenceRule.isEmpty) return sameDay;
        return sameDay || RecurrenceHelper.occursOnDate(task, date);
      } catch (_) {
        return false; // Skip malformed dates to avoid crashes
      }
    }).toList();
  }

  List<Task> _getTodayTasks() {
    final today = DateTime.now();
    return _getTasksForDate(today);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation
        return true;
      },
      child: Scaffold(
        body: CloudyAnimatedBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double scale = (constraints.maxHeight / 917.0).clamp(0.7, 1.4);
              final double settingsLeft = 10 * scale;
              final double settingsTop = 17 * scale;
              final double settingsSize = 72 * scale;

              return Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(height: 85 * scale), // Space for settings icon
                      // Date/time header (hidden on Month view per design)
                      if (_currentView != CalendarView.month &&
                          _currentView != CalendarView.calendar)
                        _buildHeader(context),

                      // View switcher buttons (always visible) - allows screen navigation
                      _buildViewSwitcher(),

                      // Scrollable content area with view switching gestures
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity.abs() > 100) {
                              final currentIndex = CalendarView.values.indexOf(_currentView);
                              
                              if (velocity < 0) {
                                // Swiped left - move to next view
                                if (currentIndex < CalendarView.values.length - 1) {
                                  setState(() => _currentView = CalendarView.values[currentIndex + 1]);
                                }
                              } else {
                                // Swiped right - move to previous view
                                if (currentIndex > 0) {
                                  setState(() => _currentView = CalendarView.values[currentIndex - 1]);
                                }
                              }
                            }
                          },
                          child: _currentView == CalendarView.month
                              ? Column(
                                  children: [
                                    _buildMonthNavigationBar(),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [_buildCurrentViewContent()],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : SingleChildScrollView(child: _buildCurrentViewContent()),
                        ),
                      ),
                    ],
                  ),
                  // Settings Icon (same as main page)
                  Positioned(
                    top: settingsTop,
                    left: settingsLeft,
                    child: IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: settingsSize,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case CalendarView.today:
        return Column(
          children: [_buildTodayTasks(), const SizedBox(height: 100)],
        );
      case CalendarView.month:
        return Column(
          children: [_buildMonthlyView(), const SizedBox(height: 100)],
        );
      case CalendarView.calendar:
        return Column(
          children: [
            _buildCalendarWidget(),
            _buildGoogleSyncButton(),
            const SizedBox(height: 100),
          ],
        );
    }
  }

  //  Header and Switcher

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = now.day.toString().padLeft(2, '0');
    final monthStr = now.month.toString().padLeft(2, '0');
    final dayName = _getDayName(now.weekday);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day name
          Text(
            dayName,
            style: AppTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),

          // Date and time zones row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Large date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date number
                    Text(
                      '$dateStr.$monthStr',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E40AF), // Deep blue
                        height: 0.9,
                      ),
                    ),
                    // Month
                    Text(
                      _getMonthName(now.month),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E40AF),
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),

              // Right: Current time
              if (_currentView != CalendarView.month)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD34D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrentTime(String timezone) {
    final now = DateTime.now();
    if (timezone == 'Athens') {
      return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    } else if (timezone == 'BuenosAires') {
      // Buenos Aires is UTC-3, Athens is UTC+2 (winter) or UTC+3 (summer), diff ≈ 5 hours
      final baTime = now.subtract(const Duration(hours: 5));
      return '${baTime.hour.toString().padLeft(2, '0')}:${baTime.minute.toString().padLeft(2, '0')}';
    }
    return '00:00';
  }

  Widget _buildViewSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPillButton('Today', CalendarView.today),
          _buildPillButton('Month', CalendarView.month),
          _buildPillButton('Calendar', CalendarView.calendar),
        ],
      ),
    );
  }

  Widget _buildPillButton(String text, CalendarView view) {
    bool isSelected = _currentView == view;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          setState(() => _currentView = view);
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.black : Colors.transparent,
          side: const BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.footerInElement.copyWith(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  // Today View

  Widget _buildTodayInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tuesday',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bigTitle.copyWith(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'DEC',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '13:20',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Athens',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '8:20',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      'Buenos Aires',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTasks() {
    final todayTasks = _getTodayTasks();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D), // Bright yellow
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and Reminders button
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
                    color: Color(0xFF1E40AF), // Classic blue
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF), // Classic blue
                    foregroundColor: const Color(0xFFFCD34D), // Yellow text
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

          // Tasks list
          if (_isLoading)
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
            ...todayTasks.map((task) => _buildTaskCard(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isDeadline = task.type == 'deadline';

    // Use custom color if set, otherwise default colors
    final defaultBackgroundColor = isDeadline
        ? const Color(0xFFD4BBA8)
        : const Color(0xFFC5D9F0);
    final backgroundColor = task.colorValue != null
        ? Color(task.colorValue!)
        : defaultBackgroundColor;

    // Parse time
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
            // Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            // Description if exists
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

            // Time info
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
      const Color(0xFFC5D9F0), // Light blue (default for tasks)
      const Color(0xFFD4BBA8), // Tan (default for deadlines)
      const Color(0xFFFFD93D), // Bright yellow
      const Color(0xFF6BCB77), // Green
      const Color(0xFF4D96FF), // Bright blue
      const Color(0xFFFF6B6B), // Red
      const Color(0xFFA78BFA), // Purple
      const Color(0xFFFFA500), // Orange
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
                      debugPrint('Selected color: ${color.value}');
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
      debugPrint('Updating task ${task.id} with color ${color.value}');
      final result = await DatabaseHelper().updateTaskColor(
        task.id!,
        color.value,
      );
      debugPrint('Update result: $result');
      await _loadTasks(); // Reload to show updated color
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task color updated!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating task color: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final suffix = t.period == DayPeriod.am ? 'am' : 'pm';
    if (t.minute == 0) {
      return '$hour$suffix';
    }
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute$suffix';
  }

  Future<void> _showAddOptionsForSlot(DateTime date, TimeOfDay time) async {
    if (!mounted) return;
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
                if (result == true) _loadTasks();
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
                if (result == true) _loadTasks();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    final candidate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + delta,
      1,
    );
    if (candidate.isBefore(_minMonth))
      return; // prevent going before current month
    setState(() {
      _visibleMonth = candidate;
    });
  }

  Widget _buildMonthNavigationBar() {
    final prevMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    final canGoBack = !prevMonth.isBefore(_minMonth);

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
              _getMonthName(prevMonth.month),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            IconButton(
              onPressed: canGoBack ? () => _changeMonth(-1) : null,
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
              _getMonthName(_visibleMonth.month),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFCD34D),
              ),
            ),
            IconButton(
              onPressed: () => _changeMonth(1),
              icon: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFCD34D),
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              _getMonthName(nextMonth.month),
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

  // Month View

  Widget _buildMonthlyView() {
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final now = DateTime.now();
    final bool isCurrentVisibleMonth =
        _visibleMonth.year == now.year && _visibleMonth.month == now.month;
    final int startDay = isCurrentVisibleMonth ? now.day : 1;
    final startDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      startDay,
    );
    final daysToShow = daysInMonth - (startDay - 1);

    return Column(
      children: [
        // Daily schedules
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: List.generate(daysToShow, (index) {
              final date = startDate.add(Duration(days: index));
              final tasksForDay = _getTasksForDate(date);
              final colors = [
                const Color(0xFFE8D5E8), // Mauve/purple
                const Color(0xFFC9D9E8), // Light purple/blue
                const Color(0xFFC8E5D8), // Mint green
                const Color(0xFFFDE8B6), // Peach
                const Color(0xFFE8D5E8), // Mauve
                const Color(0xFFD4C5E2), // Light purple
                const Color(0xFFC8E5D8), // Mint
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

  String _getMonthName(int month) {
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

  String _getDayName(int weekday) {
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

  Widget _buildDailyScheduleCard(
    DateTime date,
    List<Task> tasks,
    Color backgroundColor,
  ) {
    // Smart default slots based on whether it's today or future
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    List<TimeOfDay> defaultSlots;
    if (isToday) {
      // For today: show next 3 upcoming hours (rounded up)
      final currentHour = now.hour;
      final nextHour = currentHour + 1;
      defaultSlots = [
        TimeOfDay(hour: (nextHour) % 24, minute: 0),
        TimeOfDay(hour: (nextHour + 3) % 24, minute: 0),
        TimeOfDay(hour: (nextHour + 6) % 24, minute: 0),
      ];
    } else {
      // For future dates: use sensible spread (morning, afternoon, evening)
      defaultSlots = [
        const TimeOfDay(hour: 10, minute: 0), // 10am
        const TimeOfDay(hour: 14, minute: 0), // 2pm
        const TimeOfDay(hour: 18, minute: 0), // 6pm
      ];
    }

    final taskSlots = tasks
        .map((t) => _parseTimeOfDay(t.scheduledTime))
        .where((t) => t != null)
        .cast<TimeOfDay>()
        .toList();

    final merged = <String, TimeOfDay>{};

    if (taskSlots.length >= 3) {
      // Enough task slots: show only actual tasks
      for (final t in taskSlots) {
        merged['${t.hour}:${t.minute}'] = t;
      }
    } else {
      // Not enough tasks: include tasks + only the defaults needed to reach 3 slots
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
          // Left: Date
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayName(date.weekday),
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
                  _getMonthName(date.month),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Right: Time slots with add + existing tasks
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: timeSlots.map((slot) {
                final slotTasks = tasks.where((t) {
                  final parsed = _parseTimeOfDay(t.scheduledTime);
                  if (parsed == null) return false;
                  return parsed.hour == slot.hour &&
                      parsed.minute == slot.minute;
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimeOfDay(slot),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showAddOptionsForSlot(date, slot),
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

  Widget _buildTimeSlot(String start, String end) {
    void showAddEventDialog() {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.note_add, color: Colors.green),
                title: const Text('Add New Task'),
                onTap: () async {
                  Navigator.pop(bc);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const NewTaskScreen(initialType: 'task'),
                    ),
                  );
                  if (result == true) _loadTasks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.red),
                title: const Text('Add New Deadline'),
                onTap: () async {
                  Navigator.pop(bc);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) =>
                          const NewTaskScreen(initialType: 'deadline'),
                    ),
                  );
                  if (result == true) _loadTasks();
                },
              ),
            ],
          );
        },
      );
    }

    return Column(
      children: [
        Text(start, style: const TextStyle(fontSize: 10)),
        GestureDetector(
          onTap: showAddEventDialog,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
        Text(end, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // Calendar View

  Widget _buildCalendarWidget() {
    final selectedDayTasks = _selectedDay != null
        ? _getTasksForDate(_selectedDay!)
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
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return _getTasksForDate(day);
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

        // Selected day tasks
        if (_selectedDay != null) ...[
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
            ...selectedDayTasks.map((task) => _buildCalendarTaskCard(task)),
        ],
      ],
    );
  }

  Widget _buildCalendarTaskCard(Task task) {
    final color = task.colorValue != null
        ? Color(task.colorValue!)
        : (task.type == 'deadline'
              ? const Color(0xFFD4BBA8)
              : const Color(0xFFC5D9F0));

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
            task.type == 'deadline' ? Icons.alarm : Icons.check_circle_outline,
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
        child: _isSyncing
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
                  _syncWithGoogleCalendar(direction: 'export');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('Import from Google Calendar'),
                subtitle: const Text('Get events from Google Calendar'),
                onTap: () {
                  Navigator.pop(context);
                  _syncWithGoogleCalendar(direction: 'import');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync, color: Colors.purple),
                title: const Text('Two-way Sync'),
                subtitle: const Text('Export tasks & import events'),
                onTap: () {
                  Navigator.pop(context);
                  _syncWithGoogleCalendar(direction: 'both');
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncWithGoogleCalendar({String direction = 'export'}) async {
    setState(() => _isSyncing = true);

    try {
      final googleService = GoogleCalendarService();

      // Authenticate first
      final api = await googleService.authenticate();
      if (api == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to authenticate with Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Ensure calendar exists
      final calendarId = await googleService.getOrCreateMrPlannTerCalendar();
      if (calendarId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create/find calendar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      int exportedCount = 0;
      int importedCount = 0;
      int duplicatesFound = 0;

      // Export to Google Calendar
      if (direction == 'export' || direction == 'both') {
        final unsyncedData = await DatabaseHelper().getUnsyncedTasks();
        final unsyncedTasks = unsyncedData.map((e) => Task.fromMap(e)).toList();

        for (var task in unsyncedTasks) {
          try {
            final dateTime = DateTime.parse(
              '${task.scheduledDate} ${task.scheduledTime}:00',
            );
            final eventId = await googleService.createCalendarEvent(
              title: '${task.type == 'deadline' ? '🔴 ' : '📝 '}${task.title}',
              startTime: dateTime,
              duration: Duration(minutes: task.duration),
              description: task.description.isNotEmpty
                  ? task.description
                  : 'From Mr PlannTer',
            );

            if (eventId != null && task.id != null) {
              await DatabaseHelper().updateTaskGoogleEventId(task.id!, eventId);
              exportedCount++;
            }
          } catch (e) {
            debugPrint('Error exporting task ${task.title}: $e');
          }
        }
      }

      // Import from Google Calendar
      if (direction == 'import' || direction == 'both') {
        final events = await googleService.fetchCalendarEvents(
          calendarId: 'primary',
        );

        for (var event in events) {
          if (event.summary == null || event.start?.dateTime == null) continue;

          final title = event.summary!;
          final rawStart = event.start!.dateTime!;
          final rawEnd = event.end?.dateTime;

          // Convert to local only if UTC; otherwise keep provided timezone/offset
          final startDateTime = rawStart.isUtc ? rawStart.toLocal() : rawStart;
          final endDateTimeRaw =
              rawEnd ?? startDateTime.add(const Duration(hours: 1));
          final endDateTime = endDateTimeRaw.isUtc
              ? endDateTimeRaw.toLocal()
              : endDateTimeRaw;

          final duration = endDateTime.difference(startDateTime).inMinutes;

          final scheduledDate =
              '${startDateTime.year}-${startDateTime.month.toString().padLeft(2, '0')}-${startDateTime.day.toString().padLeft(2, '0')}';
          final scheduledTime =
              '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}';

          // Check if task already exists
          final existingTask = await DatabaseHelper().findSimilarTask(
            title: title.replaceAll('🔴 ', '').replaceAll('📝 ', ''),
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
          );

          if (existingTask != null) {
            duplicatesFound++;
            continue;
          }

          // Import the event as a task
          await DatabaseHelper().insertTask({
            'title': title.replaceAll('🔴 ', '').replaceAll('📝 ', ''),
            'description': event.description ?? 'Imported from Google Calendar',
            'type': title.contains('🔴') ? 'deadline' : 'task',
            'is_completed': 0,
            'frequency': 'none',
            'duration': duration,
            'importance': 3,
            'scheduled_date': scheduledDate,
            'scheduled_time': scheduledTime,
            'google_event_id': event.id,
            'color_value': null,
          });
          importedCount++;
        }
      }

      // Reload tasks
      await _loadTasks();

      // Show result message
      if (mounted) {
        String message = '';
        if (direction == 'export') {
          message = exportedCount > 0
              ? 'Successfully exported $exportedCount tasks to Google Calendar!'
              : 'All tasks are already synced!';
        } else if (direction == 'import') {
          message = importedCount > 0
              ? 'Successfully imported $importedCount events from Google Calendar!'
              : 'No new events to import.';
          if (duplicatesFound > 0) {
            message += ' ($duplicatesFound duplicates skipped)';
          }
        } else {
          message = 'Exported: $exportedCount, Imported: $importedCount';
          if (duplicatesFound > 0) {
            message += ' ($duplicatesFound duplicates skipped)';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: (exportedCount + importedCount) > 0
                ? Colors.green
                : Colors.blue,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
}
