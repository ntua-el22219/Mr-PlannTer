import 'package:flutter/material.dart';

import '../data/local_storage_service.dart';
import '../services/google_calendar_service.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isGoogleSyncEnabled = false;
  bool _soundEnabled = true;
  String _selectedSong = 'Choose a song';
  String? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await LocalStorageService().init();
    final storage = LocalStorageService();
    setState(() {
      _selectedSong = storage.getSelectedSong() ?? 'Choose a song';
      _connectedDevice = storage.getConnectedDevice();
      _isGoogleSyncEnabled = storage.isGoogleSyncEnabled;
      _soundEnabled = storage.isSoundEnabled;
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
              child: Icon(Icons.settings, size: 40, color: Colors.brown.shade900),
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
                      icon: _soundEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                      label: 'Sound',
                      value: _soundEnabled ? 'On' : 'Off',
                      onTap: () {
                        setState(() => _soundEnabled = !_soundEnabled);
                        LocalStorageService().setSoundEnabled(_soundEnabled);
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.music_note,
                      label: 'Music',
                      value: _selectedSong == 'Choose a song' ? 'Choose\na song' : 'Change\nSong',
                      onTap: () => _showSongsList(context),
                    ),
                    _buildSettingsItem(
                      icon: Icons.bluetooth,
                      label: 'Bluetooth',
                      value: _connectedDevice != null ? 'Connected' : 'Connect\nto\nDevice',
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
                  icon: Icon(_isGoogleSyncEnabled ? Icons.sync : Icons.sync_disabled),
                  label: Text(_isGoogleSyncEnabled ? 'Google Sync: ON' : 'Enable Google Sync'),
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
          Text(label, style: AppTextStyles.footerInElement.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
          const SizedBox(height: 10),
          Icon(icon, size: 40, color: Colors.black),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.taskHour.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
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
      final api = await GoogleCalendarService().authenticate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(api != null ? 'Connected to Google Calendar!' : 'Connection Failed')),
      );
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
          onSelectSong: (song) {
            setState(() => _selectedSong = song);
            LocalStorageService().setSelectedSong(song);
          },
          currentSong: _selectedSong,
        ),
      ),
    );
  }
}

class PlaceholderDeviceScreen extends StatelessWidget {
  const PlaceholderDeviceScreen({super.key, required this.onSelectDevice, required this.currentDevice});

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
                    Text('Bluetooth', style: AppTextStyles.settingsHeader.copyWith(fontWeight: FontWeight.bold)),
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
                )
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

class PlaceholderSongsScreen extends StatelessWidget {
  const PlaceholderSongsScreen({super.key, required this.onSelectSong, required this.currentSong});

  final Function(String) onSelectSong;
  final String currentSong;

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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('Songs', style: AppTextStyles.settingsHeader.copyWith(fontWeight: FontWeight.bold)),
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
                      _buildSongItem(context, 'White Noise'),
                      _buildSongItem(context, 'Import a new song'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongItem(BuildContext context, String name) {
    final bool isSelected = currentSong == name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () {
          onSelectSong(name);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            border: Border.all(color: const Color(0xFF0D47A1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              name,
              style: AppTextStyles.footerInElement.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}