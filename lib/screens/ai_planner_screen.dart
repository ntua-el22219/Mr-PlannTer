import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/task_model.dart';
import '../data/gemini_service.dart';
import '../data/recurrence_helper.dart';
import '../widgets/cloudy_background.dart';
import '../data/notification_service.dart'; 

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  List<Task> _unplannedTasks = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  final Map<int, Map<String, dynamic>> _suggestions = {}; // taskId -> {date, time, reasoning}
  
  @override
  void initState() {
    super.initState();
    _loadUnplannedTasks();
  }

  Future<void> _loadUnplannedTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _suggestions.clear();
      });

      final taskMaps = await DatabaseHelper().queryAllTasks();
      final unplanned = taskMaps
          .map((map) => Task.fromMap(map))
          .where((task) => task.scheduledDate.isEmpty && task.type == 'task')
          .toList();
      
      setState(() {
        _unplannedTasks = unplanned;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Failed to load tasks: $e");
    }
  }

  Future<void> _generateSuggestions() async {
    if (_unplannedTasks.isEmpty) {
      _showErrorDialog("No unplanned tasks to schedule");
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final allTasks = await DatabaseHelper().queryAllTasks();
      final plannedTasks = allTasks
          .map((e) => Task.fromMap(e))
          .where((t) => t.scheduledDate.isNotEmpty && t.scheduledTime.isNotEmpty)
          .toList();

      final today = DateTime.now();
      final horizonEnd = today.add(const Duration(days: 7));
      final plannedBlocks = <String>[];

      for (final t in plannedTasks) {
        // Base instance
        plannedBlocks.add(
          "${t.title} on ${t.scheduledDate} at ${t.scheduledTime} (${t.duration}min, importance ${t.importance})",
        );

        // Recurring instances within 7-day horizon
        if (t.recurrenceRule.isNotEmpty) {
          for (int d = 0; d <= 7; d++) {
            final date = DateTime(today.year, today.month, today.day + d);
            if (RecurrenceHelper.occursOnDate(t, date)) {
              final dateStr = date.toIso8601String().split('T')[0];
              plannedBlocks.add(
                "${t.title} on $dateStr at ${t.scheduledTime} (${t.duration}min, importance ${t.importance})",
              );
            }
          }
        }
      }

      final plannedSummary = plannedBlocks.isEmpty ? 'None' : plannedBlocks.join('; ');

      final unplannedSummary = _unplannedTasks
          .map((t) => "${t.title} (${t.duration}min, importance ${t.importance})")
          .join("; ");

      final prompt = '''
        Today is ${DateTime.now().toString().split(' ')[0]}.

        Existing scheduled tasks (avoid conflicts, keep their time blocks free):
        $plannedSummary

        Tasks to schedule (within the next 7 days):
        $unplannedSummary

        Rules:
        - Do NOT overlap any planned tasks.
        - Do NOT overlap suggested tasks with each other.
        - Avoid scheduling two high-importance tasks (importance >=4) back-to-back; leave breathing room.
        - Use realistic spacing; keep mornings for focus-heavy tasks when possible.
        - Use 24h time. Keep suggestions within 7 days from today.

        RETURN ONLY lines in this exact format:
        TASK_NUMBER|DATE(YYYY-MM-DD)|TIME(HH:MM 24h)|REASON

        Example:
        1|2026-01-13|09:00|Morning focus slot, no conflicts
        2|2026-01-13|14:30|After lunch, avoids overlap with Meeting
      ''';

      final suggestions = await GeminiService().generateScheduleSuggestions(prompt);
      
      if (mounted) {
        setState(() {
          _suggestions.clear();
          for (var i = 0; i < suggestions.length && i < _unplannedTasks.length; i++) {
            final parts = suggestions[i].split('|');
            if (parts.length >= 3) {
              _suggestions[i] = {
                'date': parts[1].trim(),
                'time': parts[2].trim(),
                'reason': parts.length > 3 ? parts[3].trim() : '',
              };
            }
          }
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        _showErrorDialog("Failed to generate suggestions: $e");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent.shade200),
            const SizedBox(height: 10),
            Text(
              "Oops!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptSuggestion(int taskIndex) async {
    final suggestion = _suggestions[taskIndex];
    if (suggestion == null) return;

    try {
      final task = _unplannedTasks[taskIndex];
      task.scheduledDate = suggestion['date'];
      task.scheduledTime = suggestion['time'];

      await DatabaseHelper().updateTask(task.toMap());

      // Set up notifications for the scheduled task
      if (mounted) {
        // Εμφανίζουμε το Pop-up αμέσως μετά την αποδοχή
        await showNotificationSetupDialog(
          context,
          task.id!, 
          task.title,
          task.scheduledDate,
          task.scheduledTime,
          task.type == 'deadline', // Έλεγχος αν είναι deadline
        );
      }
      
      // Remove this task from unplanned list without full reload
      setState(() {
        _unplannedTasks.removeAt(taskIndex);
        // Rebuild suggestion map with adjusted indices
        final newSuggestions = <int, Map<String, dynamic>>{};
        _suggestions.forEach((key, value) {
          if (key < taskIndex) {
            newSuggestions[key] = value;
          } else if (key > taskIndex) {
            newSuggestions[key - 1] = value;
          }
        });
        _suggestions.clear();
        _suggestions.addAll(newSuggestions);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ ${task.title} scheduled for ${suggestion['date']} at ${suggestion['time']}"),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog("Failed to save task: $e");
    }
  }

  Future<void> _rejectSuggestion(int taskIndex) async {
    setState(() {
      _suggestions.remove(taskIndex);
    });
  }

  Future<void> _editSuggestion(int taskIndex) async {
    final suggestion = _suggestions[taskIndex];
    if (suggestion == null) return;

    // Show custom edit dialog
    final dateController = TextEditingController(text: suggestion['date']);
    final timeController = TextEditingController(text: suggestion['time']);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE082),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 2),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Schedule",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: "Time (HH:MM)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _suggestions[taskIndex]!['date'] = dateController.text;
                        _suggestions[taskIndex]!['time'] = timeController.text;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Close Button (X) - Centered at top
            Positioned(
              top: 80,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                  child: const Icon(Icons.close, size: 35, color: Colors.black),
                ),
              ),
            ),

            // Main Yellow Container
            Positioned(
              top: 150,
              bottom: 100,
              child: Container(
                width: 650,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            "📋 Unplanned Tasks (${_unplannedTasks.length})",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Task list / empty state
                          Expanded(
                            child: _unplannedTasks.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, size: 80, color: Colors.green.shade700),
                                        const SizedBox(height: 16),
                                        Text(
                                          "All tasks planned!",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          "No unplanned tasks to schedule",
                                          style: TextStyle(color: Colors.black54, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        ..._unplannedTasks.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final task = entry.value;
                                          final suggestion = _suggestions[idx];

                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.black, width: 1.5),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${task.duration}min • ${'⭐' * task.importance}",
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                ),

                                                if (suggestion != null) ...[
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "🤖 AI Suggestion:",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.blue.shade900,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          "📅 ${suggestion['date']} at ⏰ ${suggestion['time']}",
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (suggestion['reason'].isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            suggestion['reason'],
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey.shade800,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () => _acceptSuggestion(idx),
                                                          icon: const Icon(Icons.check, size: 16),
                                                          label: const Text("Accept", style: TextStyle(fontSize: 12)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green.shade600,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () => _editSuggestion(idx),
                                                          icon: const Icon(Icons.edit, size: 16),
                                                          label: const Text("Edit", style: TextStyle(fontSize: 12)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.orange.shade600,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: ElevatedButton.icon(
                                                          onPressed: () => _rejectSuggestion(idx),
                                                          icon: const Icon(Icons.close, size: 16),
                                                          label: const Text("Reject", style: TextStyle(fontSize: 12)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red.shade600,
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 12),
                          // Generate suggestions button (always visible at bottom)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (_isGenerating || _unplannedTasks.isEmpty)
                                  ? null
                                  : _generateSuggestions,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_fix_high),
                              label: Text(
                                _isGenerating ? "Generating suggestions..." : "Generate AI Suggestions",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
