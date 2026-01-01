import 'dart:convert';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/local_storage_service.dart';


const _clientId = "YOUR_GOOGLE_CLIENT_ID"; // Client ID από Google Cloud
const _clientSecret = "YOUR_GOOGLE_CLIENT_SECRET"; // Client Secret από Google Cloud

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



  Future<void> createCalendarEvent({
    required String title,
    required DateTime startTime,
    required Duration duration,
  }) async {
    if (_calendarApi == null) return;
    
    final calendarId = await getOrCreateMrPlannTerCalendar();
    if (calendarId == null) return;

    final endTime = startTime.add(duration);
    
    final event = gcal.Event(
      summary: title,
      start: gcal.EventDateTime(dateTime: startTime, timeZone: 'Europe/Athens'),
      end: gcal.EventDateTime(dateTime: endTime, timeZone: 'Europe/Athens'),
      description: 'Automatically synced from Mr PlannTer app.',
    );

    try {
      await _calendarApi!.events.insert(event, calendarId);
      if (kDebugMode) print('Event "$title" created successfully.');
    } catch (e) {
      if (kDebugMode) print('Failed to create event: $e');
    }
  }
}