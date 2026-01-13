import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/task_model.dart';
import '../widgets/cloudy_background.dart';
import 'settings_screen.dart';
import 'new_task_screen.dart';
import 'ai_planner_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  // false = Tasks Tab, true = Deadlines Tab
  bool _showDeadlines = false;

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  // Φόρτωση των Tasks από τη Βάση
  Future<void> _refreshTaskList() async {
    try {
      final data = await DatabaseHelper().queryAllTasks();
      if (mounted) {
        setState(() {
          // Μετατρέπουμε τα δεδομένα της βάσης (Map) σε αντικείμενα (Task)
          _tasks = data.map((e) => Task.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading tasks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Εναλλαγή κατάστασης ολοκλήρωσης Task
  void _toggleTaskCompletion(Task task) async {
    // Αν είναι 1 κάντο 0, αν είναι 0 κάντο 1
    final newStatus = task.isCompleted ? 0 : 1;
    await DatabaseHelper().updateTaskCompletion(task.id!, newStatus);
    _refreshTaskList(); // Ανανέωσε τη λίστα
  }

  // Διαγραφή Task
  void _deleteTask(int id) async {
    await DatabaseHelper().deleteTask(id);
    _refreshTaskList(); // Ανανέωσε τη λίστα για να φύγει το σβησμένο

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task deleted"),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Πλοήγηση στην οθόνη προσθήκης νέου Task/Deadline
  void _navigateToAdd(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewTaskScreen(initialType: type)),
    );

    // Αν επέστρεψε true, πρόσθεσε το νέο Task/Deadline
    if (result == true) {
      // Άλλαξε αυτόματα καρτέλα
      if (type == 'deadline') {
        setState(() => _showDeadlines = true);
      } else {
        setState(() => _showDeadlines = false);
      }

      // Ξαναφόρτωσε τα δεδομένα για να φανεί το καινούργιο
      _refreshTaskList();
    }
  }

  // Πλοήγηση στην οθόνη επεξεργασίας Task/Deadline
  void _navigateToEdit(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NewTaskScreen(initialType: task.type, existingTask: task),
      ),
    );

    // Αν επέστρεψε true, ανανέωσε τη λίστα
    if (result == true) {
      _refreshTaskList();
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
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
              onTap: () {
                Navigator.pop(c);
                _navigateToAdd('task');
              },
            ),
            ListTile(
              title: const Text(
                "New Deadline",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.timer, color: Colors.black),
              onTap: () {
                Navigator.pop(c);
                _navigateToAdd('deadline');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Φιλτράρισμα της λίστας ανάλογα με την επιλεγμένη καρτέλα
    final currentList = _tasks.where((task) {
      return task.type == (_showDeadlines ? 'deadline' : 'task');
    }).toList();

    return Scaffold(
      body: CloudyBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = (constraints.maxHeight / 917.0).clamp(0.7, 1.4);
            final double settingsLeft = 10 * scale;
            final double settingsTop = 17 * scale;
            final double settingsSize = 72 * scale;

            return Stack(
              children: [
                SafeArea(
                  child: Stack(
                    children: [

              // Κεντρικό Κίτρινο Πλαίσιο
              Positioned(
                top: 120,
                bottom: 80,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082), // Κίτρινο
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() > 100) {
                        if (velocity < 0 && _showDeadlines) {
                          // Swiped left, but already on Deadlines, so do nothing
                        } else if (velocity < 0 && !_showDeadlines) {
                          // Swiped left - go to Deadlines
                          setState(() => _showDeadlines = true);
                        } else if (velocity > 0 && _showDeadlines) {
                          // Swiped right - go to Tasks
                          setState(() => _showDeadlines = false);
                        }
                      }
                    },
                    child: Column(
                      children: [
                        // Tabs (Tasks / Deadlines)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          child: Row(
                            children: [
                              _buildTabButton(
                                'Tasks',
                                !_showDeadlines,
                                () => setState(() => _showDeadlines = false),
                              ),
                              const SizedBox(width: 20),
                              _buildTabButton(
                                'Deadlines',
                                _showDeadlines,
                                () => setState(() => _showDeadlines = true),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          height: 2,
                          color: Colors.black12,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),

                        // Λίστα με Tasks/Deadlines
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : currentList.isEmpty
                              ? Center(
                                  child: Text(
                                    "No ${_showDeadlines ? 'deadlines' : 'tasks'} yet!",
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: currentList.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskItem(currentList[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // AI Planner Button (only show for Tasks, not Deadlines)
              if (!_showDeadlines)
                Positioned(
                  bottom: 90,
                  left: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                      ),
                    ),
                    onPressed: () async {
                      // Ανοίγουμε την οθόνη του AI και περιμένουμε να γυρίσει
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const AIPlannerScreen(),
                        ),
                      );

                      // Αν επιστρέψει true (σημαίνει ότι προστέθηκαν tasks), κάνουμε refresh τη λίστα
                      if (result == true) {
                        _refreshTaskList();
                      }
                    },
                    child: const Text("AI Planner"),
                  ),
                ),

              // Κουμπί Προσθήκης (+)
              Positioned(
                bottom: 90,
                right: 30,
                child: GestureDetector(
                  onTap: () => _showAddOptions(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
                    ],
                  ),
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
    );
  }

  // Βοηθητικό Widget για τα Tabs
  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.black45,
            ),
          ),
          Container(
            height: 3,
            width: 60,
            margin: const EdgeInsets.only(top: 4),
            color: isActive ? Colors.blue.shade900 : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // Βοηθητικό Widget για κάθε γραμμή Task
  Widget _buildTaskItem(Task task) {
    // Check if task is planned (has date/time)
    final isPlanned =
        task.scheduledDate.isNotEmpty && task.scheduledTime.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleTaskCompletion(task),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade900, width: 2),
                color: task.isCompleted
                    ? Colors.blue.shade900
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),

          const SizedBox(width: 10),

          // Τίτλος και Ημερομηνία
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                // Εμφάνιση ημερομηνίας και ώρας ή "Unplanned"
                Text(
                  isPlanned
                      ? "${task.scheduledDate} @ ${task.scheduledTime}"
                      : "Unplanned",
                  style: TextStyle(
                    fontSize: 12,
                    color: isPlanned ? Colors.grey : Colors.orange.shade700,
                    fontStyle: isPlanned ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Κουμπί Επεξεργασίας (Edit)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _navigateToEdit(task),
          ),

          // Κουμπί Διαγραφής (Trash)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteTask(task.id!), // Καλεί τη διαγραφή
          ),
        ],
      ),
    );
  }
}
