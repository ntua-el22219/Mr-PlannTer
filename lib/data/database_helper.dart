import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mr_plannter.db');

    return await openDatabase(
      path,
      version: 3, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    // Check if color_value column exists, if not add it
    try {
      final result = await db.rawQuery("PRAGMA table_info(tasks)");
      final hasColorColumn = result.any((col) => col['name'] == 'color_value');
      
      if (!hasColorColumn) {
        debugPrint('Adding color_value column...');
        await db.execute('ALTER TABLE tasks ADD COLUMN color_value INTEGER');
        debugPrint('color_value column added successfully');
      }
    } catch (e) {
      debugPrint('Error checking/adding color_value column: $e');
    }
  }

  void _onCreate(Database db, int version) async {
    // Πίνακας για Tasks (Εργασίες και Deadlines)
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT, 
        description TEXT, 
        type TEXT, 
        is_completed INTEGER, 
        frequency TEXT, 
        duration INTEGER, 
        importance INTEGER, 
        scheduled_date TEXT, 
        scheduled_time TEXT, 
        google_event_id TEXT,
        color_value INTEGER
      )
    ''');
    
    // Πίνακας για την τρέχουσα κατάσταση του φυτού (Timer)
    await db.execute('''
      CREATE TABLE plant_state (
        id INTEGER PRIMARY KEY,
        current_stage INTEGER, 
        total_study_time INTEGER 
      )
    ''');
    // Αρχικοποίηση με μηδενικές τιμές
    await db.insert('plant_state', {'id': 1, 'current_stage': 0, 'total_study_time': 0});

    // Πίνακας για τα Ολοκληρωμένα Φυτά (Άλμπουμ) 
    await db.execute('''
      CREATE TABLE completed_plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_image_path TEXT,
        plant_name TEXT,
        completion_date TEXT
      )
    ''');
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Αν αναβαθμιστεί η βάση, φτιάχνουμε τον πίνακα αν δεν υπάρχει
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE completed_plants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plant_image_path TEXT,
          plant_name TEXT,
          completion_date TEXT
        )
      ''');
    }
    
    // Add color_value column if it doesn't exist
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN color_value INTEGER');
      } catch (e) {
        // Column might already exist
        debugPrint('Column might already exist: $e');
      }
    }
  }


  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('tasks', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'scheduled_date ASC');
  }

  Future<int> updateTaskCompletion(int id, int isCompleted) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_completed': isCompleted},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update Google Calendar Event ID for a task
  Future<int> updateTaskGoogleEventId(int id, String googleEventId) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'google_event_id': googleEventId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all tasks that haven't been synced to Google Calendar
  Future<List<Map<String, dynamic>>> getUnsyncedTasks() async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'google_event_id IS NULL OR google_event_id = ?',
      whereArgs: [''],
      orderBy: 'scheduled_date ASC',
    );
  }

  // Update task color
  Future<int> updateTaskColor(int id, int? colorValue) async {
    final db = await database;
    try {
      final result = await db.update(
        'tasks',
        {'color_value': colorValue},
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Task color updated: $result rows affected');
      return result;
    } catch (e) {
      debugPrint('Error updating task color: $e');
      rethrow;
    }
  }

  Future<int> updatePlantState(int newStage, int totalStudyMinutes) async {
    final db = await database;
    final currentState = await getPlantState();
    int currentTotalTime = currentState?['total_study_time'] ?? 0;

    return db.update(
      'plant_state',
      {'current_stage': newStage, 'total_study_time': currentTotalTime + totalStudyMinutes},
      where: 'id = ?', whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> getPlantState() async {
    final db = await database;
    final result = await db.query('plant_state', where: 'id = ?', whereArgs: [1]);
    return result.isNotEmpty ? result.first : null;
  }


  // Προσθήκη ενός ολοκληρωμένου φυτού στο ιστορικό
  Future<int> addCompletedPlant(String imagePath, String name) async {
    final db = await database;
    return await db.insert('completed_plants', {
      'plant_image_path': imagePath,
      'plant_name': name,
      'completion_date': DateTime.now().toIso8601String(),
    });
  }

  // Ανάκτηση όλων των ολοκληρωμένων φυτών
  Future<List<Map<String, dynamic>>> getCompletedPlants() async {
    final db = await database;
    // Τα φέρνουμε με σειρά από το πιο πρόσφατο προς το παλιότερο
    return await db.query('completed_plants', orderBy: 'completion_date DESC');
  }

  // Check if task exists with similar title and datetime
  Future<Map<String, dynamic>?> findSimilarTask({
    required String title,
    required String scheduledDate,
    String? scheduledTime,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'tasks',
      where: 'LOWER(title) = ? AND scheduled_date = ?',
      whereArgs: [title.toLowerCase(), scheduledDate],
    );
    
    // If time is specified, check for exact match
    if (scheduledTime != null && scheduledTime.isNotEmpty) {
      final exactMatch = results.where((task) => task['scheduled_time'] == scheduledTime).toList();
      return exactMatch.isNotEmpty ? exactMatch.first : null;
    }
    
    // Return first match if no time specified
    return results.isNotEmpty ? results.first : null;
  }

  // Διαγραφή Task με βάση το ID
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}