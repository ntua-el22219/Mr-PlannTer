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

    FocusScope.of(context).unfocus();

    setState(() {
      _isGenerating = true;
      _generatedSteps = [];
    });

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
  }

  Future<void> _saveSelectedTasks() async {
    int count = 0;
    for (var step in _generatedSteps) {
      if (step['isSelected']) {
        final newTask = Task(
          title: step['title'],
          type: 'task',
          scheduledDate: DateTime.now().toIso8601String().split('T')[0],
          scheduledTime: "09:00",
          description: "AI Plan: ${_controller.text}",
          duration: 30,
          importance: 2,
        );
        await DatabaseHelper().insertTask(newTask.toMap());
        count++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count Tasks added!")));
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
                            "will be added to your calendar:",
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
