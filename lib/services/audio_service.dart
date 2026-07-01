import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _audioBacksound = AudioPlayer();

  String? _currentBacksoundPath;
  String? _currentAudioPath;
  bool _isCancelled = false;

  Source _getSource(String path, bool isBundled) {
    if (isBundled) {
      final assetPath = path.startsWith('assets/') ? path.substring(7) : path;
      return AssetSource(assetPath);
    } else {
      return DeviceFileSource(path);
    }
  }

  Future<void> playAudioLoop(String audioPath, {bool isBundled = true}) async {
    if (_currentBacksoundPath == audioPath && _audioBacksound.state == PlayerState.playing) {
      return;
    }

    try {
      if (await _audioExists(audioPath, isBundled)) {
        await _audioBacksound.stop();
        _currentBacksoundPath = audioPath;

        await _audioBacksound.setReleaseMode(ReleaseMode.loop);
        await _audioBacksound.setVolume(0.7);
        await _audioBacksound.play(_getSource(audioPath, isBundled));
      }
    } catch (e) {
      debugPrint('Error playing loop audio: $e');
      _currentBacksoundPath = null;
    }
  }

  Future<void> stopBacksoundAudio() async {
    try {
      await _audioBacksound.stop();
      _currentBacksoundPath = null;
    } catch (e) {
      debugPrint('Error stopping backsound: $e');
    }
  }

  Future<void> playAudio(String path, {bool isBundled = true}) async {
    if (_currentAudioPath == path && _audioPlayer.state == PlayerState.playing) {
      return;
    }

    _isCancelled = false;
    try {
      await _audioPlayer.stop();
      await _audioBacksound.setVolume(0.2);

      if (await _audioExists(path, isBundled)) {
        _currentAudioPath = path;

        Completer<void> completer = Completer<void>();
        StreamSubscription? completeSub;

        completeSub = _audioPlayer.onPlayerComplete.listen((event) {
          if (!completer.isCompleted) completer.complete();
        });

        await _audioPlayer.play(_getSource(path, isBundled));

        await completer.future;
        completeSub.cancel();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _currentAudioPath = null;
    } finally {
      if (!_isCancelled) {
        await _audioBacksound.setVolume(0.7);
      }
    }
  }

  Future<void> playSequentialAudio(List<String> paths, {bool isBundled = true}) async {
    _isCancelled = false;
    try {
      await _audioPlayer.stop();
      await _audioBacksound.setVolume(0.2);

      for (String path in paths) {
        if (_isCancelled) break;

        if (await _audioExists(path, isBundled)) {
          _currentAudioPath = path;

          Completer<void> completer = Completer<void>();
          StreamSubscription? completeSub;

          completeSub = _audioPlayer.onPlayerComplete.listen((event) {
            if (!completer.isCompleted) completer.complete();
          });

          await _audioPlayer.play(_getSource(path, isBundled));

          await completer.future;
          completeSub.cancel();

          if (_isCancelled) break;
          await Future.delayed(const Duration(milliseconds: 200)); // Jeda antar bahasa
        }
      }
    } catch (e) {
      debugPrint('Error in sequential audio playback: $e');
    } finally {
      if (!_isCancelled) {
        await _audioBacksound.setVolume(0.7);
      }
    }
  }

  Future<void> stopAudio() async {
    _isCancelled = true;
    try {
      await _audioPlayer.stop();
      _currentAudioPath = null;
      await _audioBacksound.setVolume(0.7);
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  Future<bool> _audioExists(String path, bool isBundled) async {
    if (isBundled) {
      try {
        await rootBundle.load(path);
        return true;
      } catch (e) {
        return false;
      }
    } else {
      return await File(path).exists();
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
  }

  void dispose() {
    _audioPlayer.dispose();
    _audioBacksound.dispose();
  }
}