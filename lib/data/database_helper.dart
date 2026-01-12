import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();

    // Force table creation check immediately
    try {
      final result = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'",
      );

      if (result.isEmpty) {
        debugPrint('Tasks table does not exist after init, creating now...');
        await _createTables(_database!);
      } else {
        debugPrint('Tasks table already exists');
      }
    } catch (e) {
      debugPrint('Error checking tables: $e');
    }

    return _database!;
  }

  Future<Database> _initDb() async {
    // For desktop platforms, ensure FFI is initialized
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasePath = await databaseFactory.getDatabasesPath();
    final path = join(databasePath, 'mr_plannter.db');

    debugPrint('Opening database at: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  Future<void> _onOpen(Database db) async {
    debugPrint('Database opened, checking tables...');

    // Check if tasks table exists
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='tasks'",
      );

      if (result.isEmpty) {
        debugPrint('Tasks table does not exist, creating it...');
        await _createTables(db);
        return;
      }

      debugPrint('Tasks table exists, checking columns...');
      final columns = await db.rawQuery("PRAGMA table_info(tasks)");
      debugPrint('Tasks table columns: $columns');
      final hasColorColumn = columns.any((col) => col['name'] == 'color_value');
      final hasRecurrenceColumn = columns.any(
        (col) => col['name'] == 'recurrence_rule',
      );

      if (!hasColorColumn) {
        debugPrint('Adding color_value column...');
        await db.execute('ALTER TABLE tasks ADD COLUMN color_value INTEGER');
        debugPrint('color_value column added successfully');
      }

      if (!hasRecurrenceColumn) {
        debugPrint('Adding recurrence_rule column...');
        await db.execute('ALTER TABLE tasks ADD COLUMN recurrence_rule TEXT');
        debugPrint('recurrence_rule column added successfully');
      }
    } catch (e) {
      debugPrint('Error checking/adding color_value column: $e');
    }
  }

  Future<void> _createTables(Database db) async {
    debugPrint('Creating all database tables...');

    // Πίνακας για Tasks (Εργασίες και Deadlines)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
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
        color_value INTEGER,
        recurrence_rule TEXT
      )
    ''');
    debugPrint('Tasks table created successfully');

    // Πίνακας για την τρέχουσα κατάσταση του φυτού (Timer)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS plant_state (
        id INTEGER PRIMARY KEY,
        current_stage INTEGER, 
        total_study_time INTEGER 
      )
    ''');

    // Αρχικοποίηση με μηδενικές τιμές
    final plantStateCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM plant_state'),
    );
    if (plantStateCount == 0) {
      await db.insert('plant_state', {
        'id': 1,
        'current_stage': 0,
        'total_study_time': 0,
      });
    }

    // Πίνακας για τα Ολοκληρωμένα Φυτά (Άλμπουμ)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS completed_plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_image_path TEXT,
        plant_name TEXT,
        completion_date TEXT
      )
    ''');

    debugPrint('All tables created successfully');
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('onCreate called - creating database tables...');
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
    // ⚠️ VALIDATION: Ensure data consistency
    _validateTaskData(row);

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

  // Update entire task
  Future<int> updateTask(Map<String, dynamic> taskData) async {
    // ⚠️ VALIDATION: Ensure data consistency
    _validateTaskData(taskData);

    final db = await database;
    final id = taskData['id'];
    if (id == null) {
      throw Exception('Task ID is required for update');
    }
    return await db.update('tasks', taskData, where: 'id = ?', whereArgs: [id]);
  }

  // Validate task data before saving to database
  void _validateTaskData(Map<String, dynamic> taskData) {
    final type = taskData['type'] as String?;
    final scheduledDate = taskData['scheduled_date'] as String? ?? '';
    final scheduledTime = taskData['scheduled_time'] as String? ?? '';

    // For deadlines: MUST have both date and time
    if (type == 'deadline') {
      if (scheduledDate.isEmpty || scheduledTime.isEmpty) {
        throw Exception(
          'ERROR: Deadline MUST have both date and time. '
          'Date: "$scheduledDate", Time: "$scheduledTime"',
        );
      }
    }

    // Ensure consistency: both date and time must be set or both must be empty
    final dateEmpty = scheduledDate.isEmpty;
    final timeEmpty = scheduledTime.isEmpty;

    if (dateEmpty != timeEmpty) {
      throw Exception(
        'ERROR: Data inconsistency! Date and time must both be set or both be empty. '
        'Date: "$scheduledDate" (empty=$dateEmpty), Time: "$scheduledTime" (empty=$timeEmpty)',
      );
    }

    debugPrint(
      'Task Validation ✓: Type=$type, Planned=${!dateEmpty}, Date=$scheduledDate, Time=$scheduledTime',
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
      {
        'current_stage': newStage,
        'total_study_time': currentTotalTime + totalStudyMinutes,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> getPlantState() async {
    final db = await database;
    final result = await db.query(
      'plant_state',
      where: 'id = ?',
      whereArgs: [1],
    );
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
      final exactMatch = results
          .where((task) => task['scheduled_time'] == scheduledTime)
          .toList();
      return exactMatch.isNotEmpty ? exactMatch.first : null;
    }

    // Return first match if no time specified
    return results.isNotEmpty ? results.first : null;
  }

  // Διαγραφή Task με βάση το ID
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
