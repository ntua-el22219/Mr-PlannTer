import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String? apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<List<String>> generateStudyPlan(String goal) async {
    try {
      // Ρύθμιση του μοντέλου Gemini
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey ?? '');
 
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
        return response.text!.split('|').map((e) => e.trim()).toList();
      } else {
        throw Exception("Could not generate plan. Empty response.");
      }
    } catch (e) {
      print("Gemini Error: $e");
      throw Exception(e.toString()); 
    }
  }
}
