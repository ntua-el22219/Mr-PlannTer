import 'package:flutter/material.dart';
import '../theme/text_styles.dart';
import 'package:table_calendar/table_calendar.dart';
import 'settings_screen.dart'; 
import 'new_task_screen.dart'; 
import '../widgets/cloudy_background.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildViewSwitcher(),
              _buildCurrentViewContent(),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCurrentViewContent() {
    switch (_currentView) {
      case CalendarView.today:
        return Column(
          children: [
            _buildTodayInfo(),
            _buildTodayTasks(),
          ],
        );
      case CalendarView.month:
        return _buildMonthlyView();
      case CalendarView.calendar:
        return Column(
          children: [
            _buildCalendarWidget(),
            _buildGoogleSyncButton(),
          ],
        );
    }
  }

  //  Header and Switcher

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.settings, size: 30, color: Colors.black54),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text, style: AppTextStyles.footerInElement.copyWith(color: isSelected ? Colors.white : Colors.black)),
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
            Text('Tuesday', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}',
                  style: AppTextStyles.bigTitle.copyWith(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                Text(
                  'DEC', 
                  style: AppTextStyles.heading2.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('13:20', style: AppTextStyles.caption.copyWith(color: Colors.blue.shade700)),
                    Text('Athens', style: AppTextStyles.caption.copyWith(color: Colors.blue.shade700)),
                    const SizedBox(height: 5),
                    Text('8:20', style: AppTextStyles.caption.copyWith(color: Colors.black54)),
                    Text('Buenos Aires', style: AppTextStyles.caption.copyWith(color: Colors.black54)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Todays tasks', style: AppTextStyles.footerInElement.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                  ),
                  child: Text('Reminders', style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Colors.yellow.shade400, borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Session', style: AppTextStyles.settingsHeader.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5:00 PM Start', style: AppTextStyles.taskHour),
                    Chip(
                      label: Text('30 Min', style: AppTextStyles.caption.copyWith(color: Colors.black, fontSize: 10)),
                      backgroundColor: Colors.white,
                    ),
                    Text('5:30 PM End', style: AppTextStyles.taskHour),
                  ],
                )
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(15)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Human-computer interaction Deadline', style: AppTextStyles.settingsHeader.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      Text('23:59', style: AppTextStyles.footerInElement.copyWith(fontWeight: FontWeight.bold)),
                      Text('Ends in 3 hours', style: AppTextStyles.caption.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Month View

  Widget _buildMonthlyView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.yellow.shade400, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('NOV', style: AppTextStyles.mediumStyle.copyWith(color: Colors.grey.shade700)),
                const Icon(Icons.arrow_left),
                const Text('DEC', style: TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_right),
                Text('JAN', style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
        
        Column( 
          children: [
            _buildDailySchedule('Tuesday', 10, Colors.yellow.shade300),
            _buildDailySchedule('Wednesday', 11, Colors.red.shade300),
            _buildDailySchedule('Thursday', 12, Colors.green.shade300),
            _buildDailySchedule('Friday', 13, Colors.purple.shade300),
            _buildDailySchedule('Saturday', 14, Colors.blue.shade300),
            _buildDailySchedule('Sunday', 15, Colors.orange.shade300),
          ],
        ),
      ],
    );
  }

  Widget _buildDailySchedule(String day, int date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$day, $date DEC', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeSlot('3pm', '4pm'),
                _buildTimeSlot('4pm', '5pm'),
                _buildTimeSlot('5pm', '6pm'),
              ],
            ),
          ],
        ),
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
                onTap: () {
                  Navigator.pop(bc); 
                  // Καλούμε το NewTaskScreen με type='task'
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const NewTaskScreen(initialType: 'task')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.red),
                title: const Text('Add New Deadline'),
                onTap: () {
                  Navigator.pop(bc);
                  // Καλούμε το NewTaskScreen με type='deadline'
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const NewTaskScreen(initialType: 'deadline')));
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
              color: const Color.fromRGBO(255,255,255,0.5),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.yellow.shade300, borderRadius: BorderRadius.circular(15)),
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
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false, 
            titleCentered: true,
            titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            leftChevronIcon: const Icon(Icons.arrow_left, color: Colors.black),
            rightChevronIcon: const Icon(Icons.arrow_right, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSyncButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        child: TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attempting Google Calendar Sync...')),
            );
          },
          icon: const Icon(Icons.sync, color: Colors.blue),
          label: const Text('Synchronize with Google Calendar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}