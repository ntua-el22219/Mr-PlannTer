class Task {
  // Πεδία
  int? id;
  String title;
  String description;
  String type; // 'task' ή 'deadline'
  bool isCompleted; // true ή false
  String scheduledDate; // π.χ. "2025-12-25"
  String scheduledTime; // π.χ. "10:30"
  int duration; // σε λεπτά
  int importance; // 1, 2, 3
  String? googleEventId; // Google Calendar event ID
  int? colorValue; // Color as int (0xFFRRGGBB)
  String
  recurrenceRule; // RRULE format or custom JSON (e.g., "FREQ=WEEKLY;BYDAY=MO,WE,FR")

  // Κατασκευαστής με προεπιλεγμένες τιμές
  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.type,
    this.isCompleted = false, // Από προεπιλογή είναι ατελείωτο
    required this.scheduledDate,
    required this.scheduledTime,
    this.duration = 30,
    this.importance = 1,
    this.googleEventId,
    this.colorValue,
    this.recurrenceRule = '',
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      type: map['type'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      scheduledDate: map['scheduled_date'],
      scheduledTime: map['scheduled_time'],
      duration: map['duration'] ?? 30,
      importance: map['importance'] ?? 1,
      googleEventId: map['google_event_id'],
      colorValue: map['color_value'],
      recurrenceRule: map['recurrence_rule'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      // Μετατρέπουμε το true σε 1 και το false σε 0 για τη βάση
      'is_completed': isCompleted ? 1 : 0,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'duration': duration,
      'importance': importance,
      'google_event_id': googleEventId,
      'color_value': colorValue,
      'recurrence_rule': recurrenceRule,
    };
  }
}
