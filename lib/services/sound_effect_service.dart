import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/local_storage_service.dart';

class SoundEffectService {
  static final AudioPlayer _soundPlayer = AudioPlayer();
  static bool _isInitialized = false;

  /// Initialize the audio player once (call this on app startup if possible)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _soundPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      await _soundPlayer.setVolume(0.6);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing sound player: $e');
    }
  }

  /// Play a pop sound effect if sound effects are enabled (non-blocking)
  static void playPopSound() {
    // Initialize if not already done
    if (!_isInitialized) {
      initialize();
    }
    
    // Check if sound effects are enabled (synchronous check from SharedPreferences cache)
    final storage = LocalStorageService();
    if (!storage.isSoundEffectsEnabled) {
      return;
    }

    // Play sound in the background without awaiting
    _soundPlayer.play(AssetSource('audio/pop-402324.mp3')).catchError((e) {
      debugPrint('Error playing pop sound: $e');
    });
  }

  /// Play a water sound effect if sound effects are enabled (non-blocking)
  static void playWaterSound() {
    // Initialize if not already done
    if (!_isInitialized) {
      initialize();
    }
    
    // Check if sound effects are enabled (synchronous check from SharedPreferences cache)
    final storage = LocalStorageService();
    if (!storage.isSoundEffectsEnabled) {
      return;
    }

    // Play sound in the background without awaiting
    _soundPlayer.play(AssetSource('audio/Flowing Water - Sound Effect (mp3cut.net).mp3')).catchError((e) {
      debugPrint('Error playing water sound: $e');
    });
  }

  /// Stop the sound
  static Future<void> stopSound() async {
    await _soundPlayer.stop();
  }

  /// Dispose of the sound player
  static Future<void> dispose() async {
    await _soundPlayer.dispose();
  }
}
