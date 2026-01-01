import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String apiKey = 'AIzaSyCsWqieMWAiCyY2QkHAPiL2PmDqUALTi4A'; 

  Future<List<String>> generateStudyPlan(String goal) async {
    try {
      // Ρύθμιση του μοντέλου Gemini
      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

      // Η εντολή (Prompt) που στέλνουμε στο AI
      final prompt = '''
        You are a helpful study assistant app.
        The user wants to achieve this goal: "$goal".
        Create a list of 5 specific, actionable study tasks.
        RETURN ONLY THE TASKS, separated by a pipe symbol (|).
        Do not include numbering, bullets, or intro text.
        Example output: Read Chapter 1|Solve 5 exercises|Review notes|Take a quiz|Summarize key points
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        // Χωρίζουμε την απάντηση με βάση το σύμβολο |
        return response.text!.split('|').map((e) => e.trim()).toList();
      } else {
        return ["Could not generate plan. Try again."];
      }
    } catch (e) {
      print("Gemini Error: $e");
      return [
         "Error: $e",
        "Check internet connection",
        "Verify API Key",
        "Try again later"
      ];
    }
  }
}
