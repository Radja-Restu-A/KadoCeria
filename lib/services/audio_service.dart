import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.stop();

      // Check if asset exists before trying to load it
      if (await _assetExists(path)) {
        await _audioPlayer.setAsset(path);
        await _audioPlayer.play();
      } else {
        throw Exception('Audio asset not found: $path');
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> playSequentialAudio(List<String> paths) async {
    for (String path in paths) {
      try {
        await playAudio(path);

        // Wait for audio to complete before playing next
        await _audioPlayer.playerStateStream
            .where((state) => state.processingState == ProcessingState.completed)
            .first;

      } catch (e) {
        debugPrint('Error in sequential audio playback: $e');
        // Continue to next audio file instead of breaking
        continue;
      }
    }
  }

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      debugPrint('Asset does not exist: $path');
      return false;
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  bool get isPlaying => _audioPlayer.playing;

  void dispose() {
    _audioPlayer.dispose();
  }
}