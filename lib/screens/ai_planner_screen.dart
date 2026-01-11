import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/task_model.dart';
import '../data/gemini_service.dart';

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedSteps = [];

  // Δημιουργία του πλάνου με το Gemini AI
  Future<void> _generatePlan() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus(); // Κλείνει το πληκτρολόγιο

    setState(() {
      _isGenerating = true;
      _generatedSteps = []; // Καθαρίζουμε τη λίστα
    });

    try {
      // Προσπαθούμε να πάρουμε τα αποτελέσματα
      final steps = await GeminiService().generateStudyPlan(text);

      if (mounted) {
        setState(() {
          _generatedSteps = steps.map((step) => {
            'title': step,
            'isSelected': true
          }).toList();
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false; // Σταματάμε το loading
        });
        
        // Εμφανίζουμε το Popup
        _showErrorDialog("Oops! Something went wrong.\n\nDetails: $e");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Ο χρήστης πρέπει να πατήσει το κουμπί για να κλείσει
      builder: (ctx) => AlertDialog(
        // Σχήμα με στρογγυλεμένες γωνίες
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white, // Αποφυγή μωβ απόχρωσης στο Material 3
        
        // Τίτλος με Εικονίδιο και Χρώμα
        title: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.redAccent.shade200, // Απαλό κόκκινο
            ),
            const SizedBox(height: 10),
            Text(
              "Something went wrong",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),

        // Το κυρίως μήνυμα
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),

        // Το κουμπί από κάτω
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // Κόκκινο φόντο
                  foregroundColor: Colors.white, // Άσπρα γράμματα
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Οβάλ κουμπί
                  ),
                  elevation: 5, // Σκιά για βάθος
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelectedTasks() async {
    // Ρωτάμε τον χρήστη για Ημερομηνία
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: "SELECT START DATE",
    );

    if (pickedDate == null) return; // Αν πατήσει Cancel, δεν κάνουμε τίποτα

    // Ρωτάμε τον χρήστη για Ώρα
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: "SELECT TIME",
    );

    if (pickedTime == null) return; // Αν πατήσει Cancel, σταματάμε

    // Μετατροπή της ώρας σε κείμενο 
    final String formattedTime = 
        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
    
    // Μετατροπή ημερομηνίας σε κείμενο 
    final String formattedDate = pickedDate.toIso8601String().split('T')[0];

    int count = 0;
    for (var step in _generatedSteps) {
      if (step['isSelected']) {
        final newTask = Task(
          title: step['title'],
          type: 'task',
          scheduledDate: formattedDate, // Χρήση της επιλεγμένης ημερομηνίας
          scheduledTime: formattedTime, // Χρήση της επιλεγμένης ώρας
          description: "AI Plan: ${_controller.text}",
          duration: 30,
          importance: 2,
        );
        await DatabaseHelper().insertTask(newTask.toMap());
        count++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$count Tasks added for $formattedDate at $formattedTime!")),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade200, // Φόντο Ουρανού
      resizeToAvoidBottomInset: true, // Για να ανεβαίνει όταν βγαίνει το πληκτρολόγιο
      body: SafeArea(
        child: Stack(
          children: [
            // Κουμπί Κλεισίματος (X) ψηλά
            Positioned(
              top: 10, left: 0, right: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 50, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Το Κίτρινο Πλαίσιο
            Padding(
              padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F), // Κίτρινο Χρώμα
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black45, width: 1),
                ),
                child: Column(
                  children: [
                    // Header Text
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: const [
                          Text(
                            "These recommendations",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                          ),
                          Text(
                            "will be added to your tasks:",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                    ),

                    // Εισαγωγή στόχου
                    if (_generatedSteps.isEmpty && !_isGenerating)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Enter your goal (e.g. Study Math)...",
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _generatePlan,
                          ),
                        ),
                        onSubmitted: (_) => _generatePlan(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Loading ή Λίστα
                    Expanded(
                      child: _isGenerating
                          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                          : _generatedSteps.isEmpty
                              ? const Center(child: Icon(Icons.edit_note, size: 60, color: Colors.black26))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  itemCount: _generatedSteps.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _generatedSteps[index]['isSelected'] = !_generatedSteps[index]['isSelected'];
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.blue.shade300, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            // Το κυκλικό checkbox
                                            Container(
                                              width: 16, height: 16,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.blue.shade900, width: 2),
                                                color: _generatedSteps[index]['isSelected'] 
                                                    ? Colors.blue.shade900 
                                                    : Colors.transparent,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            // Το κείμενο
                                            Expanded(
                                              child: Text(
                                                _generatedSteps[index]['title'],
                                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // Footer Buttons (Yes / No)
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          const Text(
                            "Do you agree?",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // YES Button (Green)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B5E20), // Πράσινο
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: _generatedSteps.isEmpty ? null : _saveSelectedTasks,
                                child: const Text("Yes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 40),
                              // NO Button (Red)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB71C1C), // Κόκκινο
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("No", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
