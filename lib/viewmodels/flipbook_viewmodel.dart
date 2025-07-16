import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../models/story_model.dart';
import '../services/audio_service.dart';
import '../services/story_service.dart';
import '../repositories/story_repository.dart';
import '../core/service_locator.dart';

class FlipbookViewModel extends ChangeNotifier {
  final ServiceLocator _serviceLocator = ServiceLocator();

  late AudioService _audioService;
  late StoryService _storyService;
  late StoryRepository _storyRepository;

  // State variables
  Story? _story;
  int _currentPage = 0;
  Language _selectedLanguage = Language.indonesia;
  bool _isLoading = false;
  bool _isPlayingPageAudio = false;
  bool _isPlayingObjectAudio = false;
  String? _error;

  // Constructor
  FlipbookViewModel() {
    _audioService = _serviceLocator.audioService;
    _storyService = _serviceLocator.storyService;
    _storyRepository = _serviceLocator.storyRepository;
  }

  // Getters
  Story? get story => _story;
  int get currentPage => _currentPage;
  Language get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;
  bool get isPlayingPageAudio => _isPlayingPageAudio;
  bool get isPlayingObjectAudio => _isPlayingObjectAudio;
  String? get error => _error;
  bool get isFirstPage => _storyService.isFirstPage(_currentPage);
  bool get isLastPage => _story != null ? _storyService.isLastPage(_currentPage, _story!.pages.length) : false;

  // Public methods
  Future<void> loadStory(String storyId) async {
    _setLoading(true);
    _setError(null);

    try {
      _story = await _storyRepository.getStory(storyId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load story: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> playPageAudio(String storyId) async {
    if (_isPlayingPageAudio || _story == null) return;

    _setPlayingPageAudio(true);

    try {
      final pageNumber = _currentPage + 1;
      final audioPaths = _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);

      if (_selectedLanguage == Language.keduanya) {
        await _audioService.playSequentialAudio(audioPaths);
      } else {
        await _audioService.playAudio(audioPaths.first);
      }

    } catch (e) {
      _setError('Failed to play page audio: $e');
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  Future<void> playObjectAudio(String storyId, String audioFile) async {
    if (_isPlayingObjectAudio) return;

    _setPlayingObjectAudio(true);

    try {
      final audioPath = _storyService.generateObjectAudioPath(storyId, audioFile);
      await _audioService.playAudio(audioPath);

      // Add delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      _setError('Failed to play object audio: $e');
    } finally {
      _setPlayingObjectAudio(false);
    }
  }

  Future<void> playFullBookAudio(String storyId) async {
    if (_story == null) return;

    _setPlayingPageAudio(true);

    try {
      final allAudioPaths = <String>[];

      for (int i = 0; i < _story!.pages.length; i++) {
        final pageNumber = i + 1;
        final audioPaths = _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);
        allAudioPaths.addAll(audioPaths);
      }

      await _audioService.playSequentialAudio(allAudioPaths);

    } catch (e) {
      _setError('Failed to play full book audio: $e');
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  void changeLanguage(Language newLanguage) {
    if (_selectedLanguage != newLanguage) {
      _selectedLanguage = newLanguage;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_story != null && _currentPage < _story!.pages.length - 1) {
      _audioService.stopAudio();
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _audioService.stopAudio();
      _currentPage--;
      notifyListeners();
    }
  }

  void setCurrentPage(int page) {
    if (page >= 0 && _story != null && page < _story!.pages.length) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void stopAudio() {
    _audioService.stopAudio();
    _setPlayingPageAudio(false);
    _setPlayingObjectAudio(false);
  }

  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    return _storyService.calculatePageLayout(page, constraints);
  }

  void clearError() {
    _setError(null);
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setPlayingPageAudio(bool playing) {
    _isPlayingPageAudio = playing;
    notifyListeners();
  }

  void _setPlayingObjectAudio(bool playing) {
    _isPlayingObjectAudio = playing;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}