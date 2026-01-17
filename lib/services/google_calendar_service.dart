import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../data/local_storage_service.dart';

class GoogleCalendarService {
  final LocalStorageService _localStorage = LocalStorageService();
  gcal.CalendarApi? _calendarApi;

  // Singleton pattern
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gcal.CalendarApi.calendarScope],
  );

  bool get isAuthenticated => _calendarApi != null;

  /// Authenticate user with Google
  Future<gcal.CalendarApi?> authenticate() async {
    try {
      // Sign in user
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // user cancelled

      // Get auth tokens
      final authTokens = await account.authentication;

      // Use access token for API calls
      final client = _GoogleSignInAuthClient(authTokens.accessToken!);
      _calendarApi = gcal.CalendarApi(client);
      return _calendarApi;
    } catch (e) {
      if (kDebugMode) print('Google sign-in failed: $e');
      return null;
    }
  }

  /// Get or create the app-specific calendar
  Future<String?> getOrCreateMrPlannTerCalendar() async {
    if (_calendarApi == null) return null;

    final storedId = _localStorage.calendarId;
    if (storedId != null && storedId.isNotEmpty) {
      try {
        await _calendarApi!.calendars.get(storedId);
        return storedId;
      } catch (_) {
        await _localStorage.setCalendarId('');
      }
    }

    try {
      final newCal = gcal.Calendar(summary: 'Mr PlannTer Sessions & Deadlines');
      final created = await _calendarApi!.calendars.insert(newCal);
      final newId = created.id!;
      await _localStorage.setCalendarId(newId);
      return newId;
    } catch (e) {
      if (kDebugMode) print('Failed to create calendar: $e');
      return null;
    }
  }

  /// Create a calendar event
  Future<String?> createCalendarEvent({
    required String title,
    required DateTime startTime,
    required Duration duration,
    String? description,
    String? recurrenceRule, // RRULE format
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

    if (recurrenceRule != null && recurrenceRule.isNotEmpty && recurrenceRule != 'NONE') {
      event.recurrence = ['RRULE:$recurrenceRule'];
    }

    try {
      final createdEvent = await _calendarApi!.events.insert(event, calendarId);
      if (kDebugMode) print('Event "$title" created: ${createdEvent.id}');
      return createdEvent.id;
    } catch (e) {
      if (kDebugMode) print('Failed to create event: $e');
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteCalendarEvent(String eventId) async {
    if (_calendarApi == null) return false;
    final calendarId = await getOrCreateMrPlannTerCalendar();
    if (calendarId == null) return false;

    try {
      await _calendarApi!.events.delete(calendarId, eventId);
      if (kDebugMode) print('Event deleted.');
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to delete event: $e');
      return false;
    }
  }

  /// Fetch events
  Future<List<gcal.Event>> fetchCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
  }) async {
    if (_calendarApi == null) return [];
    final targetId = calendarId ?? 'primary';

    try {
      final events = await _calendarApi!.events.list(
        targetId,
        timeMin: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        timeMax: endDate ?? DateTime.now().add(Duration(days: 365)),
        singleEvents: true,
        orderBy: 'startTime',
      );
      if (kDebugMode) print('Fetched ${events.items?.length ?? 0} events from $targetId');
      return events.items ?? [];
    } catch (e) {
      if (kDebugMode) print('Failed to fetch events: $e');
      return [];
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _localStorage.setCalendarId('');
    _calendarApi = null;
  }
}

/// Helper HTTP client for GoogleSignIn access token
class _GoogleSignInAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _GoogleSignInAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}
