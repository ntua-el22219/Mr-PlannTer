import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String? apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<List<String>> generateStudyPlan(String goal) async {
    try {
      // Setup Gemini model
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey ?? '',
      );

      // Prompt for study plan generation
      final prompt =
          '''
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
        throw Exception("Could not generate study plan. Empty response.");
      }
    } catch (e) {
      print("Gemini Study Plan Error: $e");
      throw Exception(e.toString());
    }
  }

  Future<List<String>> generateScheduleSuggestions(String prompt) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey ?? '',
      );
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty && line.contains('|'))
            .map((line) => line.trim())
            .toList();
      } else {
        throw Exception(
          "Could not generate schedule suggestions. Empty response.",
        );
      }
    } catch (e) {
      print("Gemini Schedule Error: $e");
      throw Exception(e.toString());
    }
  }
}
