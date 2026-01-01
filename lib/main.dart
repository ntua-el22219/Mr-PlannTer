import 'package:flutter/material.dart';
// Εισάγουμε τον κεντρικό διαχειριστή πλοήγησης
import 'package:app_mr_plannter/screens/main_wrapper_screen.dart'; 
import 'data/local_storage_service.dart'; 

// Ορίζουμε το main μία φορά και ως async για να καλέσουμε την init()
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Αρχικοποίηση της τοπικής αποθήκευσης (Persistence)
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