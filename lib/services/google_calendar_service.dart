import 'dart:convert';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/local_storage_service.dart';


// Load credentials from environment variables (secure approach)
// Create a .env file in project root with:
// GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
// GOOGLE_CLIENT_SECRET=your_client_secret
String get _clientId {
  final id = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  if (id.isEmpty) {
    debugPrint('WARNING: GOOGLE_CLIENT_ID not found in .env file');
  }
  return id;
}

String get _clientSecret {
  final secret = dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  if (secret.isEmpty) {
    debugPrint('WARNING: GOOGLE_CLIENT_SECRET not found in .env file');
  }
  return secret;
}

// Τα απαραίτητα Scopes
const _scopes = [gcal.CalendarApi.calendarScope];

class GoogleCalendarService {
  final LocalStorageService _localStorage = LocalStorageService();
  gcal.CalendarApi? _calendarApi;

  // Singleton pattern
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();

  factory GoogleCalendarService() {
    return _instance;
  }

  GoogleCalendarService._internal();

  // Επιστρέφει true αν ο χρήστης είναι συνδεδεμένος και το token είναι έγκυρο
  bool get isAuthenticated => _calendarApi != null;

  
  // Χειρίζεται τον έλεγχο ταυτότητας
  Future<gcal.CalendarApi?> authenticate() async {
    // Δοκιμάζουμε να φορτώσουμε αποθηκευμένα credentials
    final storedCredentials = _localStorage.googleCredentials;
    if (storedCredentials != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(storedCredentials);
        final auth.AccessCredentials credentials = auth.AccessCredentials.fromJson(json);
        
        // Ελέγχουμε αν το token έχει λήξει
        if (credentials.accessToken.expiry.isAfter(DateTime.now())) {
          _calendarApi = await _getCalendarApiFromCredentials(credentials);
          return _calendarApi;
        }
      } catch (e) {
        if (kDebugMode) print('Failed to load stored credentials: $e');
        await _localStorage.clearGoogleCredentials();
      }
    }
    
    //  Αν δεν υπάρχουν, ξεκινάμε νέο OAuth flow
    return await _startOAuthFlow();
  }

  // Ξεκινάει τη διαδικασία σύνδεσης μέσω browser
  Future<gcal.CalendarApi?> _startOAuthFlow() async {
    if (_clientId.isEmpty || _clientSecret.isEmpty) {
        if (kDebugMode) print("ERROR: Google Client ID/Secret not set.");
        return null;
    }

    final auth.ClientId clientId = auth.ClientId(_clientId, _clientSecret);
    
    // Αυτό το flow ανοίγει ένα παράθυρο browser για τον χρήστη
    try {
      final auth.AuthClient client = await auth.clientViaUserConsent(
        clientId,
        _scopes,
        (url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw 'Could not launch $url';
          }
        },
      );
      
      // Αποθηκεύουμε τα credentials για μελλοντική χρήση
      _localStorage.setGoogleCredentials(jsonEncode(client.credentials.toJson()));
      _calendarApi = gcal.CalendarApi(client);
      return _calendarApi;
    } catch (e) {
      if (kDebugMode) print('Authentication failed: $e');
      return null;
    }
  }

  Future<gcal.CalendarApi?> _getCalendarApiFromCredentials(auth.AccessCredentials credentials) async {
    final httpClient = http.Client();
    final client = auth.authenticatedClient(
      httpClient,
      credentials,
    );
    return gcal.CalendarApi(client);
  }


  // Βρίσκει ή δημιουργεί το ειδικό calendar για την εφαρμογή μας
  Future<String?> getOrCreateMrPlannTerCalendar() async {
    if (_calendarApi == null) return null;
    
    // Έλεγχος αν υπάρχει ήδη αποθηκευμένο ID
    final storedId = _localStorage.calendarId;
    if (storedId != null) {
      try {
        // Ελέγχουμε αν το calendar με αυτό το ID υπάρχει ακόμα
        await _calendarApi!.calendars.get(storedId);
        return storedId;
      } catch (e) {
        // Το calendar δεν υπάρχει πια, το διαγράφουμε από το local storage
        await _localStorage.setCalendarId('');
      }
    }
    
    //  Δημιουργία νέου calendar
    try {
      final newCalendar = gcal.Calendar(summary: 'Mr PlannTer Sessions & Deadlines');
      final createdCalendar = await _calendarApi!.calendars.insert(newCalendar);
      final newId = createdCalendar.id!;
      await _localStorage.setCalendarId(newId);
      return newId;
    } catch (e) {
      if (kDebugMode) print('Failed to create calendar: $e');
      return null;
    }
  }



  Future<String?> createCalendarEvent({
    required String title,
    required DateTime startTime,
    required Duration duration,
    String? description,
  }) async {
    if (_calendarApi == null) return null;
    
    final calendarId = await getOrCreateMrPlannTerCalendar();
    if (calendarId == null) return null;

    final endTime = startTime.add(duration);
    
    final event = gcal.Event(
      summary: title,
      start: gcal.EventDateTime(dateTime: startTime, timeZone: 'Europe/Athens'),
      end: gcal.EventDateTime(dateTime: endTime, timeZone: 'Europe/Athens'),
      description: description ?? 'Automatically synced from Mr PlannTer app.',
    );

    try {
      final createdEvent = await _calendarApi!.events.insert(event, calendarId);
      if (kDebugMode) print('Event "$title" created successfully with ID: ${createdEvent.id}');
      return createdEvent.id; // Return the event ID
    } catch (e) {
      if (kDebugMode) print('Failed to create event: $e');
      return null;
    }
  }

  // Update or delete an event by ID
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (_calendarApi == null) return false;
    
    final calendarId = await getOrCreateMrPlannTerCalendar();
    if (calendarId == null) return false;

    try {
      await _calendarApi!.events.delete(calendarId, eventId);
      if (kDebugMode) print('Event deleted successfully.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to delete event: $e');
      return false;
    }
  }

  // Fetch events from Google Calendar (from primary calendar by default)
  Future<List<gcal.Event>> fetchCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
  }) async {
    if (_calendarApi == null) return [];
    
    // Use primary calendar if no specific calendar is provided
    final targetCalendarId = calendarId ?? 'primary';

    try {
      final events = await _calendarApi!.events.list(
        targetCalendarId,
        timeMin: (startDate ?? DateTime.now().subtract(Duration(days: 30))),
        timeMax: (endDate ?? DateTime.now().add(Duration(days: 365))),
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      if (kDebugMode) print('Fetched ${events.items?.length ?? 0} events from Google Calendar ($targetCalendarId)');
      return events.items ?? [];
    } catch (e) {
      if (kDebugMode) print('Failed to fetch events: $e');
      return [];
    }
  }

  // Sign out and clear credentials
  Future<void> signOut() async {
    await _localStorage.clearGoogleCredentials();
    await _localStorage.setCalendarId('');
    _calendarApi = null;
  }
}