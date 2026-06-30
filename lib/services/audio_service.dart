import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _audioBacksound = AudioPlayer();

  // Subscriptions management to prevent memory leaks and audio distortion
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  AudioPlayer get audioPlayer => _audioPlayer;
  AudioPlayer get audioBacksound => _audioBacksound;

  AudioService() {
    _initListeners();
  }

  void _initListeners() {
    // Shared listeners can be added here if needed
  }

  void _clearSubscriptions() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  //Backsound
  Future<void> playAudioLoop(String audioPath, {required bool isBundled}) async {
    try {
      debugPrint('[AudioService] PlayBacksound Start: $audioPath');
      debugPrint('[AudioService] Current Backsound Speed: ${_audioBacksound.speed}');
      
      await _audioBacksound.stop();
      // Reset speed dan pitch ke normal untuk mencegah percepatan audio
      await _audioBacksound.setSpeed(1.0);
      await _audioBacksound.setPitch(1.0);

      if (isBundled) {
        if (await _assetExists(audioPath)) {
          await _audioBacksound.setAsset(audioPath);
        } else {
          throw Exception('Backsound asset not found: $audioPath');
        }
      } else {
        if (File(audioPath).existsSync()) {
          await _audioBacksound.setFilePath(audioPath);
        } else {
          throw Exception('Local backsound file not found: $audioPath');
        }
      }

      await _audioBacksound.setLoopMode(LoopMode.one);
      await _audioBacksound.setVolume(0.7);
      
      debugPrint('[AudioService] Waiting for Backsound to be ready...');
      await _audioBacksound.play();
      debugPrint('[AudioService] Backsound is playing');
    } catch (e) {
      debugPrint('[AudioService] Error playing loop audio: $e');
      rethrow;
    }
  }

  Future<void> stopBacksoundAudio() async {
    try {
      await _audioBacksound.stop();
      debugPrint('[AudioService] Success Stopping Backsound');
    } catch (e) {
      debugPrint('Error stopping backsound: $e');
    }
  }

  Future<void> playAudio(String path, {required bool isBundled}) async {
    try {
      debugPrint('[AudioService] PlayNarration Start: $path');
      debugPrint('[AudioService] Current Narration Speed: ${_audioPlayer.speed}');
      
      // Stop and clear current subscriptions before playing new one
      await stopAudio();
      _clearSubscriptions();

      // Reset speed dan pitch ke normal
      await _audioPlayer.setSpeed(1.0);
      await _audioPlayer.setPitch(1.0);

      // Turunkan volume backsound saat narasi berbicara
      await _audioBacksound.setVolume(0.2);

      bool canPlay = false;

      if (isBundled) {
        if (await _assetExists(path)) {
          canPlay = true;
          debugPrint('[AudioService] Loading asset...');
          await _audioPlayer.setAsset(path);
        }
      } else {
        if (File(path).existsSync()) {
          canPlay = true;
          debugPrint('[AudioService] Loading file...');
          await _audioPlayer.setFilePath(path);
        }
      }

      if (canPlay) {
        // Managed listeners for debugging (prevents leak)
        _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
          debugPrint('[AudioService] Player State: ${state.processingState}, playing: ${state.playing}');
          if (state.processingState == ProcessingState.completed) {
            debugPrint('[AudioService] Narration completed');
          }
        });

        _positionSubscription = _audioPlayer.positionStream.listen((position) {
          // Log periodically
          if (position.inMilliseconds % 2000 < 100) {
             debugPrint('[AudioService] Position: ${position.inSeconds}s');
          }
        });

        debugPrint('[AudioService] Starting playback...');
        await _audioPlayer.play();
        debugPrint('[AudioService] Playback started');
        
      } else {
        throw Exception('Audio file not found: $path');
      }
    } catch (e, stackTrace) {
      debugPrint('[AudioService] ERROR playing narration: $e');
      await _audioBacksound.setVolume(0.7);
      rethrow;
    }
  }

  Future<void> playSequentialAudio(List<String> paths, {bool isBundled = true}) async {
    debugPrint('[AudioService] Sequential playback started for ${paths.length} files');

    try {
      for (String path in paths) {
        await playAudio(path, isBundled: isBundled);
        
        // Wait for completion specifically for sequential
        await _audioPlayer.playerStateStream
            .where((state) => state.processingState == ProcessingState.completed)
            .first;
            
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      await _audioBacksound.setVolume(0.7);
      debugPrint('[AudioService] Sequential playback finished');
    }
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      debugPrint('[AudioService] Asset NOT found: $path');
      return false;
    }
  }

  Future<void> stopAudio() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      // Reset volume in case it was lowered
      await _audioBacksound.setVolume(0.7);
      _clearSubscriptions();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> stopBacksound() async {
    try{
      await _audioBacksound.stop();
    } catch (e, stackTrace) {
      debugPrint('Error stopping backsound: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> pauseAudio() async {
    try {
      debugPrint('Pausing audio playback...');
      await _audioPlayer.pause();
    } catch (e, stackTrace) {
      debugPrint('Error pausing audio: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> resumeAudio() async {
    try {
      debugPrint('Resuming audio playback...');
      await _audioPlayer.play();
    } catch (e, stackTrace) {
      debugPrint('Error resuming audio: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  bool get isPlaying => _audioPlayer.playing;

  void dispose() {
    debugPrint('Disposing audio player...');
    _clearSubscriptions();
    _audioPlayer.dispose();
    debugPrint('Audio player disposed successfully');
    debugPrint('Disposing backsound player...');
    _audioBacksound.dispose();
    debugPrint('Audio backsound disposed successfully');
  }
}
