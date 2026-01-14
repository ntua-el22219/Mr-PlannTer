import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/database_helper.dart';
import '../data/task_model.dart';
import '../data/recurrence_helper.dart';
import '../widgets/cloudy_background.dart';
import '../widgets/recurrence_picker_dialog.dart';
import '../data/notification_service.dart';

class NewTaskScreen extends StatefulWidget {
  final String initialType; // 'task' or 'deadline'
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Task? existingTask; // For editing mode

  const NewTaskScreen({
    super.key,
    required this.initialType,
    this.initialDate,
    this.initialTime,
    this.existingTask,
  });

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  // Πεδία μόνο για Tasks
  final _freqController = TextEditingController();
  final _durController = TextEditingController();

  late String _type;
  int _importance = 1;
  String _recurrenceRule = ''; // Google Calendar-style recurrence

  // Date/Time
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Collapsible planning section state
  bool _isPlanningExpanded = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;

    // If editing an existing task, populate fields
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _descController.text = task.description;
      _importance = task.importance;
      _durController.text = task.duration.toString();
      _recurrenceRule = task.recurrenceRule;

      // Parse the scheduled date
      final dateParts = task.scheduledDate.split('-');
      if (dateParts.length == 3) {
        _selectedDate = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
        );
      }

      // Parse the scheduled time
      final timeParts = task.scheduledTime.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      _isPlanningExpanded = true; // Show planning section when editing
    } else {
      // New task - use initial date/time if provided
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate!;
      }
      if (widget.initialTime != null) {
        _selectedTime = widget.initialTime!;
      }
      // Always show planning for deadlines
      if (_type == 'deadline') {
        _isPlanningExpanded = true;
      }
    }

    _dateController.text =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    _timeController.text =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _freqController.dispose();
    _durController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() {
        _selectedDate = d;
        _dateController.text = "${d.day}/${d.month}/${d.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (t != null) {
      setState(() {
        _selectedTime = t;
        _timeController.text =
            "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _showRecurrencePicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          RecurrencePickerDialog(initialRule: _recurrenceRule),
    );

    if (result != null) {
      setState(() {
        _recurrenceRule = result;
      });
    }
  }

  void _save() async {
    // Έλεγχος εγκυρότητας (Validation)
    if (_formKey.currentState!.validate()) {
      try {
        final duration = int.tryParse(_durController.text.trim()) ?? 0;

        // For deadlines, date/time is always required
        // For tasks, only if planning is expanded
        final isPlanned = _type == 'deadline' || _isPlanningExpanded;

        // CRITICAL VALIDATION: Prevent incomplete planned tasks
        if (isPlanned) {
          // Deadline: MUST have date and time
          if (_type == 'deadline') {
            if (_dateController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Deadline MUST have a date!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            if (_timeController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Deadline MUST have a time!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
          }
          // Planned Task: MUST have BOTH date and time
          else if (_type == 'task' && _isPlanningExpanded) {
            if (_dateController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Planned task MUST have a date!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
            if (_timeController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("❌ Planned task MUST have a time!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }
          }
        }

        // Build task data
        final scheduledDate = isPlanned
            ? _selectedDate.toIso8601String().split('T')[0]
            : ''; // Empty for unplanned
        final scheduledTime = isPlanned
            ? "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}"
            : ''; // Empty for unplanned

        // CONSISTENCY CHECK: Ensure both or neither are set
        if ((scheduledDate.isEmpty && scheduledTime.isNotEmpty) ||
            (scheduledDate.isNotEmpty && scheduledTime.isEmpty)) {
          debugPrint('ERROR: Inconsistent date/time state!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Date and time must both be set or both empty!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Show confirmation before saving
        final confirmed = await _showSaveConfirmation(
          isPlanned: isPlanned,
          scheduledDate: scheduledDate,
          scheduledTime: scheduledTime,
        );

        if (!confirmed) return; // User cancelled

        final taskData = {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'type': _type,
          'is_completed': widget.existingTask?.isCompleted == true ? 1 : 0,
          'frequency': _type == 'task' ? _freqController.text.trim() : '',
          'duration': duration,
          'importance': _importance,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'recurrence_rule': _recurrenceRule,
        };
 
        int taskId; // 1. Δημιουργούμε μεταβλητή για να κρατήσουμε το ID

        // Προσπάθεια αποθήκευσης
        if (widget.existingTask != null) {
          // Update existing task
          taskId = widget.existingTask!.id!; 
          taskData['id'] = taskId;
          await DatabaseHelper().updateTask(taskData);
        } else {
          taskId = await DatabaseHelper().insertTask(taskData);
        }

        // 2. Ελέγχουμε αν πρέπει να βγάλουμε το Pop-up Ειδοποιήσεων
        // (Μόνο αν έχει οριστεί ημερομηνία και ώρα)
        if (scheduledDate.isNotEmpty && scheduledTime.isNotEmpty && mounted) {
           await showNotificationSetupDialog(
             context,
             taskId, // Περνάμε το σωστό ID
             _titleController.text.trim(),
             scheduledDate,
             scheduledTime,
             _type == 'deadline',
           );
        }

        // Αν όλα πήγαν καλά, κλείσε το παράθυρο
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        debugPrint("Database Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Μήνυμα αν υπάρχουν λάθη στο form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields correctly!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Show confirmation dialog before saving
  Future<bool> _showSaveConfirmation({
    required bool isPlanned,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        _type == 'deadline' ? 'Confirm Deadline' : 'Confirm Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPlanned ? '✅ PLANNED TASK' : '📋 UNPLANNED TASK',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isPlanned) ...[
                            Text(
                              '📅 $scheduledDate at ⏰ $scheduledTime',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (_recurrenceRule.isNotEmpty)
                              Text(
                                '🔄 ${RecurrenceHelper.getShortDescription(_recurrenceRule)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ] else
                            const Text(
                              'No date or time set',
                              style: TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text(
                      'Title: ${_titleController.text.trim()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Type: ${_type == 'task' ? '📋 Task' : '📅 Deadline'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Importance: ${'⭐' * _importance}',
                      style: const TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 18),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.blue.shade900,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isTask = _type == 'task';
    final isEditing = widget.existingTask != null;
    final title = isEditing
        ? (isTask ? "Edit Task" : "Edit Deadline")
        : (isTask ? "New Task" : "New Deadline");

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: CloudyBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Close Button (X)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 2.5),
                        color: Colors.white.withOpacity(0.8),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Main Yellow Container - Centered vertically
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Title: Required
                            _buildCustomField(
                              _titleController,
                              "Title",
                              1,
                              isRequired: true,
                            ),
                            const SizedBox(height: 10),

                            // Description: Optional
                            _buildCustomField(
                              _descController,
                              "Description",
                              4,
                              isRequired: false,
                            ),
                            const SizedBox(height: 10),

                            if (isTask) ...[
                              // Recurrence Button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showRecurrencePicker,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Repeat",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _recurrenceRule.isEmpty
                                                ? "Does not repeat"
                                                : RecurrenceHelper.getShortDescription(
                                                    _recurrenceRule,
                                                  ),
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Duration (minutes)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 60,
                                    child: _buildCustomField(
                                      _durController,
                                      "",
                                      1,
                                      isRequired: true,
                                      isNumber: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            Text(
                              "Importance",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _importance = index + 1),
                                  child: Container(
                                    width: 40,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: _importance > index
                                          ? Colors.blue.shade900
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.black),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 15),

                            // Collapsible Planning Section (for tasks)
                            if (isTask)
                              GestureDetector(
                                onTap: () => setState(
                                  () => _isPlanningExpanded =
                                      !_isPlanningExpanded,
                                ),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  children: [
                                    Center(
                                      child: Icon(
                                        _isPlanningExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 30,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    if (_isPlanningExpanded) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        "Plan your task: (optional)",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Text(
                                            "Date ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _pickDate,
                                              behavior: HitTestBehavior.opaque,
                                              child: AbsorbPointer(
                                                child: _buildCustomField(
                                                  _dateController,
                                                  "DD/MM/YYYY",
                                                  1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            "Time ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: GestureDetector(
                                              onTap: _pickTime,
                                              behavior: HitTestBehavior.opaque,
                                              child: AbsorbPointer(
                                                child: _buildCustomField(
                                                  _timeController,
                                                  "HH:MM",
                                                  1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                            // For deadlines, always show date/time (no arrow)
                            if (!isTask) ...[
                              const SizedBox(height: 10),
                              Text(
                                "Date & Time",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Text(
                                    "Date ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickDate,
                                      behavior: HitTestBehavior.opaque,
                                      child: AbsorbPointer(
                                        child: _buildCustomField(
                                          _dateController,
                                          "DD/MM/YYYY",
                                          1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    "Time ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: GestureDetector(
                                      onTap: _pickTime,
                                      behavior: HitTestBehavior.opaque,
                                      child: AbsorbPointer(
                                        child: _buildCustomField(
                                          _timeController,
                                          "HH:MM",
                                          1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Action Button (Check)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: FloatingActionButton(
                      onPressed: _save,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(width: 3, color: Colors.black),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget με validation και έλεγχο αριθμών
  Widget _buildCustomField(
    TextEditingController controller,
    String hint,
    int lines, {
    bool isRequired = false,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        // Αν είναι αριθμός, εμφάνισε αριθμητικό πληκτρολόγιο
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // Αν είναι αριθμός, δέξου μόνο ψηφία (όχι γράμματα)
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],

        validator: (v) {
          // Έλεγχος αν είναι κενό
          if (isRequired && (v == null || v.trim().isEmpty)) {
            return "Required";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.all(10),
          border: InputBorder.none,
          errorStyle: const TextStyle(height: 0.8),
        ),
      ),
    );
  }
}
