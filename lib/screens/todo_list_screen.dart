import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import 'settings_screen.dart';
import 'new_task_screen.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoading = true;
  
  // false = Tasks Tab, true = Deadlines Tab
  bool _showDeadlines = false; 

  @override
  void initState() {
    super.initState();
    _refreshTaskList();
  }

  // Φόρτωση δεδομένων από τη βάση
  Future<void> _refreshTaskList() async {
    try {
      final data = await DatabaseHelper().queryAllTasks();
      if (mounted) {
        setState(() {
          _allTasks = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading tasks: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Check/Uncheck εργασίας
  void _toggleTaskCompletion(int id, int currentStatus) async {
    final newStatus = currentStatus == 0 ? 1 : 0;
    await DatabaseHelper().updateTaskCompletion(id, newStatus);
    _refreshTaskList();
  }

  // Πλοήγηση στην οθόνη προσθήκης και αυτόματη αλλαγή TAB
  void _navigateToAdd(String type) async {
    // Πηγαίνουμε στη φόρμα και περιμένουμε να επιστρέψει
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewTaskScreen(initialType: type),
      ),
    );

    // Αν επιστρέψει true (δηλαδή πατήθηκε το ✓)
    if (result == true) {
      // Αλλάζουμε αυτόματα το Tab για να δει ο χρήστης αυτό που πρόσθεσε
      if (type == 'deadline') {
        setState(() => _showDeadlines = true);
      } else {
        setState(() => _showDeadlines = false);
      }
      
      // Ξαναφορτώνουμε τη λίστα
      _refreshTaskList();
      
      // Εμφανίζουμε μήνυμα επιτυχίας
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("New $type added successfully!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Φιλτράρισμα λίστας ανάλογα με το Tab
    final currentList = _allTasks.where((item) {
      return item['type'] == (_showDeadlines ? 'deadline' : 'task');
    }).toList();

    return Scaffold(
      body: CloudyAnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Settings Icon
              Positioned(
                top: 10, left: 10,
                child: IconButton(
                  icon: const Icon(Icons.settings, size: 35, color: Colors.black),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
                  },
                ),
              ),

              // Main Yellow Container with List
              Positioned(
                top: 60, bottom: 80, left: 20, right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082), // Κίτρινο
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: [
                      // Tabs (Tasks / Deadlines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        child: Row(
                          children: [
                            _buildTabButton('Tasks', !_showDeadlines, () {
                              setState(() => _showDeadlines = false);
                            }),
                            const SizedBox(width: 20),
                            _buildTabButton('Deadlines', _showDeadlines, () {
                              setState(() => _showDeadlines = true);
                            }),
                          ],
                        ),
                      ),
                      
                      Container(height: 2, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 10)),

                      // List of tasks/deadlines
                      Expanded(
                        child: _isLoading 
                            ? const Center(child: CircularProgressIndicator())
                            : currentList.isEmpty 
                                ? Center(child: Text("No ${_showDeadlines ? 'deadlines' : 'tasks'} yet!", style: AppTextStyles.mediumStyle.copyWith(color: Colors.black54)))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(10),
                                    itemCount: currentList.length,
                                    itemBuilder: (context, index) {
                                      return _buildCustomListItem(currentList[index]);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),

              // AI Planner Button
              Positioned(
                bottom: 90, left: 30,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.black, width: 1.5)
                    ),
                  ),
                  onPressed: () {}, 
                  child: Text("AI Planner", style: AppTextStyles.footerInElement.copyWith(color: Colors.white)),
                ),
              ),

              // Κουμπί Προσθήκης (+)
              Positioned(
                bottom: 90, right: 30,
                child: GestureDetector(
                  onTap: () => _showAddOptions(context),
                  child: Container(
                    width: 50, height: 50,
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
      ),
    );
  }

  Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            text,
            style: AppTextStyles.settingsHeader.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.black45,
            ),
          ),
          Container(
            height: 3, width: 60, margin: const EdgeInsets.only(top: 4),
            color: isActive ? Colors.blue.shade900 : Colors.transparent,
          )
        ],
      ),
    );
  }

  Widget _buildCustomListItem(Map<String, dynamic> item) {
    final bool isCompleted = (item['is_completed'] ?? 0) == 1;
    final String title = item['title'] ?? '';

    return GestureDetector(
      onTap: () => _toggleTaskCompletion(item['id'], item['is_completed'] ?? 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade900, width: 2),
                color: isCompleted ? Colors.blue.shade900 : Colors.transparent,
              ),
              child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.footerInElement.copyWith(
                  fontSize: 16,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              title: Text("New Task", style: AppTextStyles.mediumStyle.copyWith(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.check_box_outlined, color: Colors.black),
              onTap: () { Navigator.pop(c); _navigateToAdd('task'); },
            ),
            ListTile(
              title: Text("New Deadline", style: AppTextStyles.mediumStyle.copyWith(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.timer, color: Colors.black),
              onTap: () { Navigator.pop(c); _navigateToAdd('deadline'); },
            ),
          ],
        ),
      ),
    );
  }
}