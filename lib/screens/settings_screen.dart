import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../data/local_storage_service.dart';
import '../services/google_calendar_service.dart';
import '../services/audio_service.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isGoogleSyncEnabled = false;
  bool _soundEffectsEnabled = true;
  String _selectedSong = 'No song';
  String? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  Future<void> _initializeSettings() async {
    await LocalStorageService().init();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = LocalStorageService();
    setState(() {
      _selectedSong = storage.getSelectedSong() ?? 'No song';
      _connectedDevice = storage.getConnectedDevice();
      _isGoogleSyncEnabled = storage.isGoogleSyncEnabled;
      _soundEffectsEnabled = storage.isSoundEffectsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 50,
              left: 20,
              child: Icon(
                Icons.settings,
                size: 40,
                color: Colors.brown.shade900,
              ),
            ),
            Positioned(
              top: 200,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: const Icon(Icons.close, size: 40, color: Colors.black),
                ),
              ),
            ),
            Positioned(
              top: 280,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSettingsItem(
                      icon: _soundEffectsEnabled
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                      label: 'Sound',
                      value: _soundEffectsEnabled ? 'On' : 'Off',
                      onTap: () {
                        setState(
                          () => _soundEffectsEnabled = !_soundEffectsEnabled,
                        );
                        LocalStorageService().setSoundEffectsEnabled(
                          _soundEffectsEnabled,
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.music_note,
                      label: 'Music',
                      value: 'Choose a song',
                      onTap: () => _showSongsList(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.bluetooth,
                      label: 'Bluetooth',
                      value: _connectedDevice != null
                          ? 'Connected'
                          : 'Connect\nto\nDevice',
                      onTap: () => _showDeviceList(context),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              child: Opacity(
                opacity: 0.8,
                child: ElevatedButton.icon(
                  onPressed: () => _handleGoogleSync(context),
                  icon: Icon(
                    _isGoogleSyncEnabled ? Icons.sync : Icons.sync_disabled,
                  ),
                  label: Text(
                    _isGoogleSyncEnabled
                        ? 'Google Sync: ON'
                        : 'Enable Google Sync',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.footerInElement.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 10),
          Icon(icon, size: 40, color: Colors.black),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.taskHour.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSync(BuildContext context) async {
    final newState = !_isGoogleSyncEnabled;
    setState(() => _isGoogleSyncEnabled = newState);
    await LocalStorageService().setGoogleSyncEnabled(newState);

    if (newState) {
      try {
        final api = await GoogleCalendarService().authenticate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              api != null ? 'Connected to Google Calendar!' : 'Connection Failed - Check logs for details',
            ),
            backgroundColor: api != null ? Colors.green : Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Google Calendar authentication error: $e');
      }
    }
  }

  void _showDeviceList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => PlaceholderDeviceScreen(
          onSelectDevice: (device) {
            setState(() => _connectedDevice = device);
            LocalStorageService().setConnectedDevice(device);
          },
          currentDevice: _connectedDevice,
        ),
      ),
    );
  }

  void _showSongsList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => PlaceholderSongsScreen(
          onSelectSong: (song) async {
            setState(() => _selectedSong = song);
            await LocalStorageService().setSelectedSong(song);
          },
          currentSong: _selectedSong,
        ),
      ),
    );
  }
}

class PlaceholderDeviceScreen extends StatelessWidget {
  const PlaceholderDeviceScreen({
    super.key,
    required this.onSelectDevice,
    required this.currentDevice,
  });

  final Function(String) onSelectDevice;
  final String? currentDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: Center(
          child: Container(
            width: 300,
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Bluetooth',
                      style: AppTextStyles.settingsHeader.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDeviceItem(context, 'Headphones'),
                      _buildDeviceItem(context, 'Speaker'),
                      _buildDeviceItem(context, 'Smartwatch'),
                      _buildDeviceItem(context, 'Car Audio'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, String name) {
    final bool isConnected = currentDevice == name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          onSelectDevice(name);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.transparent,
            border: Border.all(color: const Color(0xFF0D47A1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              name,
              style: AppTextStyles.footerInElement.copyWith(
                color: isConnected ? Colors.white : const Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderSongsScreen extends StatefulWidget {
  const PlaceholderSongsScreen({
    super.key,
    required this.onSelectSong,
    required this.currentSong,
  });

  final Function(String) onSelectSong;
  final String currentSong;

  @override
  State<PlaceholderSongsScreen> createState() => _PlaceholderSongsScreenState();
}

class _PlaceholderSongsScreenState extends State<PlaceholderSongsScreen> {
  late AudioService _audioService;
  late String _nowPlaying;
  String? _importedSongName;
  String? _importedSongPath;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _nowPlaying = widget.currentSong;
    _loadSongState();
  }

  Future<void> _loadSongState() async {
    final storage = LocalStorageService();
    await storage.init();

    final importedPath = storage.getImportedSongPath();
    final selectedSong = storage.getSelectedSong() ?? 'No song';

    if (mounted) {
      setState(() {
        _nowPlaying = selectedSong;
        if (importedPath != null && importedPath.isNotEmpty) {
          _importedSongPath = importedPath;
          _importedSongName = selectedSong;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: Center(
          child: Container(
            width: 300,
            height: 500,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Songs',
                      style: AppTextStyles.settingsHeader.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSongItem(context, 'No song'),
                      _buildSongItem(context, 'Lo-fi Beats'),
                      _buildSongItem(context, 'Classical Focus'),
                      _buildSongItem(context, 'Ambient Calm'),
                      _buildSongItem(context, 'Rain Sounds'),
                      _buildSongItem(context, 'Nature Sounds'),
                      if (_importedSongName != null)
                        _buildSongItem(
                          context,
                          _importedSongName!,
                          isImported: true,
                        ),
                      _buildSongItem(context, 'Import a song'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    String name, {
    bool isImported = false,
  }) {
    final bool isSelected = _nowPlaying == name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          if (name == 'Import a song') {
            await _importSongFromFiles(context);
          } else {
            setState(() => _nowPlaying = name);

            // Play the song
            if (name != 'No song') {
              if (isImported && _importedSongPath != null) {
                await _audioService.playSong(_importedSongPath!);
              } else {
                await _audioService.playSong(name);
              }
            } else {
              await _audioService.stopSong();
            }

            // Update parent
            widget.onSelectSong(name);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            border: Border.all(color: const Color(0xFF0D47A1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: AppTextStyles.footerInElement.copyWith(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF0D47A1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (isImported)
                GestureDetector(
                  onTap: () async {
                    await _deleteImportedSong(context);
                  },
                  child: Icon(
                    Icons.close,
                    color: isSelected ? Colors.white : const Color(0xFF0D47A1),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteImportedSong(BuildContext context) async {
    try {
      await LocalStorageService().clearImportedSong();
      await _audioService.stopSong();

      setState(() {
        _nowPlaying = 'No song';
        _importedSongName = null;
        _importedSongPath = null;
      });

      widget.onSelectSong('No song');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Imported song removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing song: $e')));
    }
  }

  Future<void> _importSongFromFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;

        setState(() {
          _nowPlaying = fileName;
          _importedSongName = fileName;
          _importedSongPath = filePath;
        });

        // Store imported song info
        await LocalStorageService().setSelectedSong(fileName);
        await LocalStorageService().setImportedSongPath(filePath);

        // Play the imported song immediately
        await _audioService.playSong(filePath);

        // Notify parent
        widget.onSelectSong(fileName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported and playing: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
    }
  }
}
