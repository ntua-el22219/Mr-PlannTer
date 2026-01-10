import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../data/database_helper.dart';

class NewTaskScreen extends StatefulWidget {
  final String initialType; // 'task' or 'deadline'
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  const NewTaskScreen({super.key, required this.initialType, this.initialDate, this.initialTime});

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
  
  // Date/Time
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialTime != null) {
      _selectedTime = widget.initialTime!;
    }
    _dateController.text = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    _timeController.text = "${_selectedTime.hour.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')}";
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
        context: context, initialDate: _selectedDate, 
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null) {
      setState(() {
        _selectedDate = d;
        _dateController.text = "${d.day}/${d.month}/${d.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) {
      setState(() {
        _selectedTime = t;
        _timeController.text = "${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}";
      });
    }
  }

  void _save() async {
    // Έλεγχος εγκυρότητας (Validation)
    if (_formKey.currentState!.validate()) {
      try {
        final duration = int.tryParse(_durController.text.trim()) ?? 0;

        final newTask = {
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'type': _type,
          'is_completed': 0,
          'frequency': _type == 'task' ? _freqController.text.trim() : '',
          'duration': duration,
          'importance': _importance,
          'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
          'scheduled_time': "${_selectedTime.hour.toString().padLeft(2,'0')}:${_selectedTime.minute.toString().padLeft(2,'0')}",
        };
        
        // Προσπάθεια αποθήκευσης
        await DatabaseHelper().insertTask(newTask);

        // Αν όλα πήγαν καλά, κλείσε το παράθυρο
        if (mounted) Navigator.pop(context, true);
        
      } catch (e) {
        debugPrint("Database Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final isTask = _type == 'task';
    final title = isTask ? "New Task" : "New Deadline";

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade200,
      resizeToAvoidBottomInset: true,
      
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Close Button (X)
            Positioned(
              top: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 2.5),
                    color: Colors.lightBlue.shade200, 
                  ),
                  child: const Icon(Icons.close, size: 30, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Main Yellow Container
            Positioned(
              top: 80,
              bottom: 0,
              left: 20,
              right: 20,
              child: Container(
                margin: const EdgeInsets.only(bottom: 80), 
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      Center(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 15),

                      // Title: Υποχρεωτικό
                      _buildCustomField(_titleController, "Title", 1, isRequired: true),
                      const SizedBox(height: 10),

                      // Description: Προαιρετικό
                      _buildCustomField(_descController, "Description", 4, isRequired: false),
                      const SizedBox(height: 10),

                      if (isTask) ...[
                        Row(
                          children: [
                            Expanded(child: Text("Frequency (days/week)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900))),
                            const SizedBox(width: 10),
                            // Frequency: Υποχρεωτικό και μόνο αριθμοί
                            SizedBox(width: 60, child: _buildCustomField(_freqController, "", 1, isRequired: true, isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: Text("Duration (minutes)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900))),
                            const SizedBox(width: 10),
                            // Duration: Υποχρεωτικό και μόνο αριθμοί
                            SizedBox(width: 60, child: _buildCustomField(_durController, "", 1, isRequired: true, isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      Text("Importance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => _importance = index + 1),
                            child: Container(
                              width: 40, height: 25,
                              decoration: BoxDecoration(
                                color: _importance > index ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.black),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 15),

                      Text(isTask ? "Plan your task:" : "Date & Time", style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 5),
                      
                      Row(
                        children: [
                          const Text("Date ", style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: _buildCustomField(_dateController, "DD/MM/YYYY", 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("Time ", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 100,
                            child: GestureDetector(
                              onTap: _pickTime,
                              child: AbsorbPointer(
                                child: _buildCustomField(_timeController, "HH:MM", 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20), 
        child: SizedBox(
          width: 70, 
          height: 70,
          child: FloatingActionButton(
            onPressed: _save,
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            shape: const CircleBorder(), 
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, 
                border: Border.all(width: 3, color: Colors.black), 
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  // Widget με validation και έλεγχο αριθμών
  Widget _buildCustomField(
    TextEditingController controller, 
    String hint, 
    int lines, 
    {bool isRequired = false, bool isNumber = false} 
  ) {
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
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        
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