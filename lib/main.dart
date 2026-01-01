import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io'; 
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'data/local_storage_service.dart';
import 'screens/main_wrapper_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Αρχικοποίηση του Database Factory για Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }


  await LocalStorageService().init();

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