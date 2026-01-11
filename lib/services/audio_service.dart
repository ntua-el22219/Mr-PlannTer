import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  late AudioPlayer _audioPlayer;
  late AudioPlayer _soundEffectPlayer;
  String? _currentSong;
  String? _currentSongPath;
  double _originalMusicVolume = 1.0;
  Timer? _volumeFadeTimer;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal() {
    _audioPlayer = AudioPlayer();
    _soundEffectPlayer = AudioPlayer();
    // Set up listener to replay when song completes
    _audioPlayer.onPlayerComplete.listen((_) {
      if (_currentSongPath != null && _currentSongPath!.isNotEmpty && _currentSong != null && _currentSong != 'No song') {
        _replaySong();
      }
    });
  }

  Future<void> playSong(String songName) async {
    try {
      // Stop current song if playing
      await _audioPlayer.stop();

      // Check if it's an imported song (has file path with extension)
      if (songName.contains('.mp3') || songName.contains('.m4a') || songName.contains('.wav')) {
        // It's an imported song, load from file path
        _currentSongPath = songName;
        _currentSong = songName;
        await _audioPlayer.setVolume(1.0);
        _originalMusicVolume = 1.0;
        await _audioPlayer.play(DeviceFileSource(songName), volume: 1.0);
      } else {
        // It's a predefined song, load from assets
        final songPath = _getSongPath(songName);

        if (songPath != null && songPath.isNotEmpty) {
          _currentSongPath = songPath;
          _currentSong = songName;
          await _audioPlayer.setVolume(1.0);
          _originalMusicVolume = 1.0;
          // Use ReleaseMode.loop for infinite looping
          await _audioPlayer.play(AssetSource(songPath), volume: 1.0);
          // Set looping after play starts
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        }
      }
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  Future<void> _replaySong() async {
    // Looping is now handled by ReleaseMode.loop, so this method is no longer needed
    // but kept for backward compatibility
    if (_currentSongPath != null && _currentSongPath!.isNotEmpty && _currentSong != 'No song') {
      print('Song should be looping with ReleaseMode.loop');
    }
  }

  Future<void> stopSong() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
      _currentSongPath = null;
    } catch (e) {
      print('Error stopping song: $e');
    }
  }

  // Fade out music volume
  Future<void> _fadeOutMusic() async {
    _volumeFadeTimer?.cancel();
    
    try {
      double currentVolume = _originalMusicVolume;
      const int fadeSteps = 15; // Number of steps for smooth fade
      const int fadeInterval = 50; // Milliseconds between each step (50ms * 15 = 750ms total)
      final double stepDecrement = currentVolume / fadeSteps;
      
      int stepCount = 0;
      _volumeFadeTimer = Timer.periodic(Duration(milliseconds: fadeInterval), (timer) {
        if (stepCount < fadeSteps) {
          currentVolume -= stepDecrement;
          if (currentVolume < 0) currentVolume = 0;
          _audioPlayer.setVolume(currentVolume);
          stepCount++;
        } else {
          _audioPlayer.setVolume(0);
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error fading out music: $e');
    }
  }

  // Fade in music volume
  Future<void> _fadeInMusic() async {
    _volumeFadeTimer?.cancel();
    
    try {
      double currentVolume = 0.0;
      const int fadeSteps = 15; // Number of steps for smooth fade
      const int fadeInterval = 50; // Milliseconds between each step
      final double stepIncrement = _originalMusicVolume / fadeSteps;
      
      int stepCount = 0;
      _volumeFadeTimer = Timer.periodic(Duration(milliseconds: fadeInterval), (timer) {
        if (stepCount < fadeSteps) {
          currentVolume += stepIncrement;
          if (currentVolume > _originalMusicVolume) currentVolume = _originalMusicVolume;
          _audioPlayer.setVolume(currentVolume);
          stepCount++;
        } else {
          _audioPlayer.setVolume(_originalMusicVolume);
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error fading in music: $e');
    }
  }

  // Sound Effects Methods
  Future<void> playStudyTimeStart() async {
    try {
      await _fadeOutMusic();
      // Wait for fade out to complete before playing sound effect
      await Future.delayed(const Duration(milliseconds: 800));
      await _soundEffectPlayer.play(AssetSource('audio/study_time_start.mp3'));
      // Wait for sound effect to finish, then fade music back in
      await Future.delayed(const Duration(milliseconds: 2500));
      await _fadeInMusic();
    } catch (e) {
      print('Error playing study time start sound: $e');
    }
  }

  Future<void> playBreakTimeStart() async {
    try {
      await _fadeOutMusic();
      await Future.delayed(const Duration(milliseconds: 800));
      await _soundEffectPlayer.play(AssetSource('audio/break_time_start.mp3'));
      await Future.delayed(const Duration(milliseconds: 2500));
      await _fadeInMusic();
    } catch (e) {
      print('Error playing break time start sound: $e');
    }
  }

  Future<void> playEndOfSessions() async {
    try {
      await _fadeOutMusic();
      await Future.delayed(const Duration(milliseconds: 800));
      await _soundEffectPlayer.play(AssetSource('audio/end_of_sessions.mp3'));
      await Future.delayed(const Duration(milliseconds: 3000));
      await _fadeInMusic();
    } catch (e) {
      print('Error playing end of sessions sound: $e');
    }
  }

  String? _getSongPath(String songName) {
    // Map song names to their asset paths
    // Adjust the paths based on where you store your MP3 files
    final Map<String, String> songMap = {
      'No song': '', // Empty means no song plays
      'Lo-fi Beats': 'audio/lofi_beats.mp3',
      'Classical Focus': 'audio/classical_focus.mp3',
      'Ambient Calm': 'audio/ambient_calm.mp3',
      'Rain Sounds': 'audio/rain_sounds.mp3',
      'Nature Sounds': 'audio/nature_sounds.mp3',
    };

    return songMap[songName];
  }

  String? get currentSong => _currentSong;

  Future<void> dispose() async {
    _volumeFadeTimer?.cancel();
    await _audioPlayer.dispose();
    await _soundEffectPlayer.dispose();
  }
}
