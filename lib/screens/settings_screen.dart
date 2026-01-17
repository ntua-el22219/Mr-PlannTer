import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../data/local_storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/cloudy_background.dart';
import '../theme/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _soundEffectsEnabled = true;
  String _selectedSong = 'No song';
  bool _bluetoothEnabled = false;
  
  static const platform = MethodChannel('com.example.app_mr_plannter/bluetooth');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _initBluetooth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  void _loadSettings() {
    final storage = LocalStorageService();
    setState(() {
      _selectedSong = storage.getSelectedSong() ?? 'No song';
      _soundEffectsEnabled = storage.isSoundEffectsEnabled;
    });
  }

  void _initBluetooth() {
    try {
      FlutterBluePlus.adapterState.listen((state) {
        if (mounted) {
          setState(() {
            _bluetoothEnabled = state == BluetoothAdapterState.on;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
    }
  }

  Future<void> _handleBluetoothTap() async {
    try {
      if (!_bluetoothEnabled) {
        await FlutterBluePlus.turnOn();
      }
      _openBluetoothSettings();
    } catch (e) {
      debugPrint('Error handling Bluetooth: $e');
    }
  }

  void _openBluetoothSettings() {
    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      flags: <int>[268435456], // FLAG_ACTIVITY_NEW_TASK = 0x10000000
      package: 'com.android.settings',
      componentName: 'com.android.settings.bluetooth.BluetoothSettings',
    );
    intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CloudyAnimatedBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = (constraints.maxHeight / 917.0).clamp(0.7, 1.4);

            return Stack(
              alignment: Alignment.topCenter,
              children: [
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
                      onTap: () async {
                        setState(
                          () => _soundEffectsEnabled = !_soundEffectsEnabled,
                        );
                        await LocalStorageService().setSoundEffectsEnabled(
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
                      icon: _bluetoothEnabled ? Icons.bluetooth_connected : Icons.bluetooth,
                      label: 'Bluetooth',
                      value: _bluetoothEnabled ? 'Enabled' : 'Disabled',
                      onTap: _handleBluetoothTap,
                      isActive: _bluetoothEnabled,
                    ),
                  ],
                ),
              ),
            ),

              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isActive = false,
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
          Stack(
            children: [
              Icon(icon, size: 40, color: Colors.black),
              if (isActive)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSongState();
  }

  Future<void> _loadSongState() async {
    final storage = LocalStorageService();

    final importedPath = storage.getImportedSongPath();
    final importedName = storage.getImportedSongName();
    final selectedSong = storage.getSelectedSong() ?? 'No song';

    if (mounted) {
      setState(() {
        _nowPlaying = selectedSong;
        if (importedPath != null && importedPath.isNotEmpty && importedName != null) {
          _importedSongPath = importedPath;
          _importedSongName = importedName;
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
                      _buildSongItem(context, 'Nature Sounds'),
                      _buildSongItem(context, 'Rain Sounds'),
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
        await LocalStorageService().setImportedSongName(fileName);

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
