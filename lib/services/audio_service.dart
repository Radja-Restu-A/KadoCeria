import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _audioBacksound = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;
  AudioPlayer get audioBacksound => _audioBacksound;

  String? _currentBacksoundPath;
  String? _currentAudioPath;

  //Backsound
  Future<void> playAudioLoop(String audioPath, {bool isBundled = true}) async {
    if (_currentBacksoundPath == audioPath && _audioBacksound.playing) {
      debugPrint('Backsound already playing: $audioPath');
      return;
    }

    try {
      if (await _audioExists(audioPath, isBundled)) {
        debugPrint('Stopping previous backsound...');
        await _audioBacksound.stop();
        
        _currentBacksoundPath = audioPath;
        if (isBundled) {
          await _audioBacksound.setAsset(audioPath);
        } else {
          await _audioBacksound.setFilePath(audioPath);
        }
        await _audioBacksound.setLoopMode(LoopMode.one);
        await _audioBacksound.setVolume(0.7);
        await _audioBacksound.play();
      }
    } catch (e) {
      debugPrint('Error playing loop audio: $e');
      _currentBacksoundPath = null;
      rethrow;
    }
  }

  Future<void> stopBacksoundAudio() async {
    try {
      await _audioBacksound.stop();
      _currentBacksoundPath = null;
      debugPrint('Success Stopping Audio');
    } catch (e) {
      debugPrint('Error stopping backsound: $e');
    }
  }

  Future<void> playAudio(String path, {bool isBundled = true}) async {
    if (_currentAudioPath == path && _audioPlayer.playing) {
      debugPrint('Audio already playing: $path');
      return;
    }

    try {
      debugPrint('Attempting to play audio from path: $path (isBundled: $isBundled)');
      
      // Ensure we stop and reset before playing new audio
      await _audioPlayer.stop();

      await _audioBacksound.setVolume(0.2);

      // Check if audio exists before trying to load it
      if (await _audioExists(path, isBundled)) {
        debugPrint('Audio source found, setting up player...');
        _currentAudioPath = path;
        
        if (isBundled) {
          await _audioPlayer.setAsset(path);
        } else {
          await _audioPlayer.setFilePath(path);
        }

        debugPrint('Starting audio playback...');
        await _audioPlayer.play();
        debugPrint('Audio playback started successfully');
        
        // Restore volume after playback finishes or if it's not sequential
        // Note: For sequential, playSequentialAudio handles volume restoration
      } else {
        debugPrint('Error: Audio source not found at path: $path');
        throw Exception('Audio source not found: $path');
      }
    } catch (e, stackTrace) {
      debugPrint('Error playing audio: $e');
      debugPrint('Stack trace: $stackTrace');
      _currentAudioPath = null;
      await _audioBacksound.setVolume(0.7);
      rethrow;
    }
  }

  Future<void> playSequentialAudio(List<String> paths, {bool isBundled = true}) async {
    debugPrint('Starting sequential audio playback for ${paths.length} files (isBundled: $isBundled)');

    await _audioBacksound.setVolume(0.2);
    try {
      for (String path in paths) {
        try {
          debugPrint('Playing sequential audio: $path');
          await playAudio(path, isBundled: isBundled);

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

  Future<bool> _audioExists(String path, bool isBundled) async {
    if (isBundled) {
      try {
        await rootBundle.load(path);
        debugPrint('Asset verification successful: $path');
        return true;
      } catch (e) {
        debugPrint('Asset verification failed: $path');
        return false;
      }
    } else {
      final file = File(path);
      final exists = await file.exists();
      if (exists) {
        debugPrint('File verification successful: $path');
      } else {
        debugPrint('File verification failed: $path');
      }
      return exists;
    }
  }

  Future<void> stopAudio() async {
    try {
      debugPrint('Stopping audio playback...');
      await _audioPlayer.stop();
      _currentAudioPath = null;
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
      _currentBacksoundPath = null;
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