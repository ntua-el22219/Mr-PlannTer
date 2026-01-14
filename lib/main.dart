import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/local_storage_service.dart';
import 'data/database_helper.dart';
import 'data/notification_service.dart';
import 'screens/main_wrapper_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification service
  await NotificationService().init();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
    debugPrint(
      'Client ID: ${dotenv.env['GOOGLE_CLIENT_ID']?.substring(0, 20)}...',
    );
  } catch (e) {
    debugPrint('ERROR loading .env file: $e');
    debugPrint('Google Calendar sync will not work without credentials.');
    debugPrint(
      'Please create a .env file in the project root with your Google credentials.',
    );
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Αρχικοποίηση του Database Factory για Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await LocalStorageService().init();

  // Add sample tasks for testing (AFTER database is initialized)
  await _addSampleTasks();

  runApp(const MyApp());
}

Future<void> _addSampleTasks() async {
  try {
    final dbHelper = DatabaseHelper();

    // Check if tasks already exist
    final allTasks = await dbHelper.queryAllTasks();
    if (allTasks.isNotEmpty) {
      debugPrint('Sample tasks already exist');
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sampleTasks = [
      {
        'title': 'Morning Exercise',
        'description': 'Cardio workout session',
        'type': 'task',
        'is_completed': 0,
        'frequency': '7',
        'duration': 45,
        'importance': 4,
        'scheduled_date': today.toIso8601String().split('T')[0],
        'scheduled_time': '08:00',
        'color_value': 0xFFC5D9F0,
      },
      {
        'title': 'Team Meeting',
        'description': 'Weekly sync with the team',
        'type': 'task',
        'is_completed': 0,
        'frequency': '5',
        'duration': 60,
        'importance': 5,
        'scheduled_date': today.toIso8601String().split('T')[0],
        'scheduled_time': '11:00',
        'color_value': 0xFF4D96FF,
      },
      {
        'title': 'Project Submission',
        'description': 'Submit final project report',
        'type': 'deadline',
        'is_completed': 0,
        'frequency': '',
        'duration': 120,
        'importance': 5,
        'scheduled_date': today
            .add(Duration(days: 2))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '17:00',
        'color_value': 0xFFD4BBA8,
      },
      {
        'title': 'Lunch with Sarah',
        'description': 'Catch up at the cafe',
        'type': 'task',
        'is_completed': 0,
        'frequency': '1',
        'duration': 90,
        'importance': 3,
        'scheduled_date': today.toIso8601String().split('T')[0],
        'scheduled_time': '13:00',
        'color_value': 0xFFFFD93D,
      },
      {
        'title': 'Grocery Shopping',
        'description': 'Buy weekly groceries',
        'type': 'task',
        'is_completed': 0,
        'frequency': '2',
        'duration': 60,
        'importance': 3,
        'scheduled_date': today
            .add(Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '10:00',
        'color_value': 0xFF6BCB77,
      },
      {
        'title': 'Client Presentation',
        'description': 'Present Q1 results to client',
        'type': 'deadline',
        'is_completed': 0,
        'frequency': '',
        'duration': 90,
        'importance': 5,
        'scheduled_date': today
            .add(Duration(days: 5))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '14:00',
        'color_value': 0xFFFF6B6B,
      },
      {
        'title': 'Yoga Class',
        'description': 'Evening relaxation session',
        'type': 'task',
        'is_completed': 0,
        'frequency': '3',
        'duration': 60,
        'importance': 3,
        'scheduled_date': today.toIso8601String().split('T')[0],
        'scheduled_time': '18:30',
        'color_value': 0xFFA78BFA,
      },
      {
        'title': 'Code Review',
        'description': 'Review PR #245',
        'type': 'task',
        'is_completed': 0,
        'frequency': '5',
        'duration': 30,
        'importance': 4,
        'scheduled_date': today
            .add(Duration(days: 1))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '15:00',
        'color_value': 0xFF4D96FF,
      },
      {
        'title': 'Study Flutter',
        'description': 'Learn advanced state management',
        'type': 'task',
        'is_completed': 0,
        'frequency': '4',
        'duration': 120,
        'importance': 4,
        'scheduled_date': today
            .add(Duration(days: 3))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '19:00',
        'color_value': 0xFFC5D9F0,
      },
      {
        'title': 'Dentist Appointment',
        'description': 'Regular checkup',
        'type': 'deadline',
        'is_completed': 0,
        'frequency': '',
        'duration': 45,
        'importance': 4,
        'scheduled_date': today
            .add(Duration(days: 7))
            .toIso8601String()
            .split('T')[0],
        'scheduled_time': '09:30',
        'color_value': 0xFFD4BBA8,
      },
      // Unplanned tasks for AI Planner demo
      {
        'title': 'Learn Dart Basics',
        'description': 'Complete Dart fundamentals course',
        'type': 'task',
        'is_completed': 0,
        'frequency': '',
        'duration': 180,
        'importance': 5,
        'scheduled_date': '',
        'scheduled_time': '',
        'color_value': 0xFF4D96FF,
      },
      {
        'title': 'Write Blog Post',
        'description': 'Article about Flutter performance',
        'type': 'task',
        'is_completed': 0,
        'frequency': '',
        'duration': 120,
        'importance': 3,
        'scheduled_date': '',
        'scheduled_time': '',
        'color_value': 0xFFC5D9F0,
      },
      {
        'title': 'Fix Bug #234',
        'description': 'UI rendering issue in calendar',
        'type': 'task',
        'is_completed': 0,
        'frequency': '',
        'duration': 90,
        'importance': 4,
        'scheduled_date': '',
        'scheduled_time': '',
        'color_value': 0xFFFF6B6B,
      },
      {
        'title': 'Organize Project Files',
        'description': 'Clean up project structure',
        'type': 'task',
        'is_completed': 0,
        'frequency': '',
        'duration': 60,
        'importance': 2,
        'scheduled_date': '',
        'scheduled_time': '',
        'color_value': 0xFF6BCB77,
      },
      {
        'title': 'Update Documentation',
        'description': 'Update README and API docs',
        'type': 'task',
        'is_completed': 0,
        'frequency': '',
        'duration': 100,
        'importance': 3,
        'scheduled_date': '',
        'scheduled_time': '',
        'color_value': 0xFFA78BFA,
      },
    ];

    for (final task in sampleTasks) {
      await dbHelper.insertTask(task);
    }

    debugPrint('Added ${sampleTasks.length} sample tasks');
  } catch (e) {
    debugPrint('Error adding sample tasks: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr PlannTer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainWrapperScreen(),
    );
  }
}
