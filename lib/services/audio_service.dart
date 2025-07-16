import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> playAudio(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
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
        break;
      }
    }
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.play();
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  bool get isPlaying => _audioPlayer.playing;

  void dispose() {
    _audioPlayer.dispose();
  }
}