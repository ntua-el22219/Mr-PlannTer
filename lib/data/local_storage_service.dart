import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _syncKey = 'isGoogleSyncEnabled';

  // Κρατάει το ID του calendar που δημιουργήθηκε για το Mr. PlannTer
  static const String _calendarIdKey = 'mrPlannTerCalendarId';

  // Κρατάει τα Google credentials
  static const String _credentialsKey = 'googleCredentials';

  late final SharedPreferences _prefs;

  // Singleton pattern για να υπάρχει μόνο μία περίπτωση του service
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  // Αρχικοποίηση
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Google Sync Toggle
  bool get isGoogleSyncEnabled => _prefs.getBool(_syncKey) ?? false;

  Future<void> setGoogleSyncEnabled(bool value) async {
    await _prefs.setBool(_syncKey, value);
  }

  //  Calendar ID
  String? get calendarId => _prefs.getString(_calendarIdKey);

  Future<void> setCalendarId(String id) async {
    await _prefs.setString(_calendarIdKey, id);
  }

  // Google Credentials
  String? get googleCredentials => _prefs.getString(_credentialsKey);

  Future<void> setGoogleCredentials(String credentialsJson) async {
    await _prefs.setString(_credentialsKey, credentialsJson);
  }

  // Song Selection
  String? getSelectedSong() => _prefs.getString('selectedSong') ?? 'No song';

  Future<void> setSelectedSong(String song) async {
    await _prefs.setString('selectedSong', song);
  }

  // Imported Song Path
  String? getImportedSongPath() => _prefs.getString('importedSongPath');

  Future<void> setImportedSongPath(String path) async {
    await _prefs.setString('importedSongPath', path);
  }

  Future<void> clearImportedSong() async {
    await _prefs.remove('importedSongPath');
    // Reset selected song to default if it was the imported song
    final selected = _prefs.getString('selectedSong');
    if (selected != null &&
        ![
          'No song',
          'Lo-fi Beats',
          'Classical Focus',
          'Ambient Calm',
          'Rain Sounds',
          'Nature Sounds',
        ].contains(selected)) {
      await _prefs.setString('selectedSong', 'Choose a song');
    }
  }

  // Connected Device
  String? getConnectedDevice() => _prefs.getString('connectedDevice');

  Future<void> setConnectedDevice(String device) async {
    await _prefs.setString('connectedDevice', device);
  }

  //  Sound Enabled
  bool get isSoundEnabled => _prefs.getBool('soundEnabled') ?? true;

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool('soundEnabled', value);
  }

  // Sound Effects Enabled (Timer sound effects)
  bool get isSoundEffectsEnabled =>
      _prefs.getBool('soundEffectsEnabled') ?? true;

  Future<void> setSoundEffectsEnabled(bool value) async {
    await _prefs.setBool('soundEffectsEnabled', value);
  }

  Future<void> clearGoogleCredentials() async {
    await _prefs.remove(_credentialsKey);
    await _prefs.remove(_calendarIdKey);
    await _prefs.remove(_syncKey);
  }

  // Selected Flower Color (for plant album)
  static const String _selectedFlowerColorKey = 'selectedFlowerColor';

  String get selectedFlowerColor =>
      _prefs.getString(_selectedFlowerColorKey) ?? 'DEFAULT';

  Future<void> setSelectedFlowerColor(String color) async {
    await _prefs.setString(_selectedFlowerColorKey, color);
  }
}
