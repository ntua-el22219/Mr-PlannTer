import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/local_storage_service.dart';
import 'data/database_helper.dart';
// import 'data/notification_service.dart';
import 'screens/main_wrapper_screen.dart';
import 'services/sound_effect_service.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

// 1. Αρχικοποίηση Ειδοποιήσεων
  await NotificationService.initialize();

  // 2. Ρυθμίσεις Οθόνης
  // Enable full screen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // Initialize sound effect service for fast playback
  await SoundEffectService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize default music playback
  final storage = LocalStorageService();
  final selectedSong = storage.getSelectedSong() ?? 'Lo-fi Beats';
  await AudioService().playSong(selectedSong);

	// ...existing code...

  runApp(const MyApp());
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
