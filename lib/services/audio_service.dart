import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _audioBacksound = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;
  AudioPlayer get audioBacksound => _audioBacksound;

  //Backsound
  Future<void> playAudioLoop(String audioPath) async {
    try {
      if (await _assetExists(audioPath)) {
        await _audioBacksound.setAsset(audioPath);
        await _audioBacksound.setLoopMode(LoopMode.one);
        await _audioBacksound.setVolume(0.7);
        await _audioBacksound.play();
      }
    } catch (e) {
      print('Error playing loop audio: $e');
      rethrow;
    }
  }

  Future<void> stopBacksoundAudio() async {
    try {
      await _audioBacksound.stop();
      print('Success Stopping Audio');
    } catch (e) {
      print('Error stopping backsound: $e');
    }
  }

  Future<void> playAudio(String path) async {
    try {
      debugPrint('Attempting to play audio from path: $path');
      await _audioPlayer.stop();

      await _audioBacksound.setVolume(0.2);

      // Check if asset exists before trying to load it
      if (await _assetExists(path)) {
        debugPrint('Audio asset found, setting up player...');
        await _audioPlayer.setAsset(path);

        // Subscribe to player state changes
        _audioPlayer.playerStateStream.listen((state) {
          debugPrint('Player state changed: ${state.processingState}');
          if (state.processingState == ProcessingState.completed) {
            debugPrint('Audio playback completed');
          }
        });

        // Subscribe to position updates
        _audioPlayer.positionStream.listen((position) {
          debugPrint('Audio position: ${position.inSeconds}s');
        });

        debugPrint('Starting audio playback...');
        await _audioPlayer.play();
        debugPrint('Audio playback started successfully');
        await _audioBacksound.setVolume(0.7);
      } else {
        debugPrint('Error: Audio asset not found at path: $path');
        throw Exception('Audio asset not found: $path');
      }
    } catch (e, stackTrace) {
      debugPrint('Error playing audio: $e');
      debugPrint('Stack trace: $stackTrace');
      await _audioBacksound.setVolume(0.7);
      rethrow;
    }
  }

  Future<void> playSequentialAudio(List<String> paths) async {
    debugPrint('Starting sequential audio playback for ${paths.length} files');

    await _audioBacksound.setVolume(0.2);
    try {
      for (String path in paths) {
        try {
          debugPrint('Playing sequential audio: $path');
          await playAudio(path);

          debugPrint('Waiting for current audio to complete...');
          await _audioPlayer.playerStateStream
              .where((state) =>
          state.processingState == ProcessingState.completed)
              .first;
          debugPrint('Audio completed, moving to next file');
        } catch (e) {
          debugPrint('Error in sequential audio playback: $e');
          continue;
        }
      }
    }finally{
      await _audioBacksound.setVolume(0.7);
    }
    debugPrint('Sequential audio playback completed');
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      debugPrint('Asset verification successful: $path');
      return true;
    } catch (e) {
      debugPrint('Asset verification failed: $path');
      debugPrint('Error: $e');
      return false;
    }
  }

  Future<void> stopAudio() async {
    try {
      debugPrint('Stopping audio playback...');
      await _audioPlayer.stop();
      debugPrint('Audio playback stopped successfully');
      await _audioBacksound.setVolume(0.7);
    } catch (e, stackTrace) {
      debugPrint('Error stopping audio: $e');
      debugPrint('Stack trace: $stackTrace');
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
      debugPrint('Audio playback paused successfully');
    } catch (e, stackTrace) {
      debugPrint('Error pausing audio: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> resumeAudio() async {
    try {
      debugPrint('Resuming audio playback...');
      await _audioPlayer.play();
      debugPrint('Audio playback resumed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error resuming audio: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  bool get isPlaying => _audioPlayer.playing;

  void dispose() {
    debugPrint('Disposing audio player...');
    _audioPlayer.dispose();
    debugPrint('Audio player disposed successfully');
    debugPrint('Disposing backsound player...');
    _audioBacksound.dispose();
    debugPrint('Audio backsound disposed successfully');
  }
}