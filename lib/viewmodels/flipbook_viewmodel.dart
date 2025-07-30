import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../models/book_model.dart';
import '../services/audio_service.dart';
import '../services/story_service.dart';
import '../repositories/story_repository.dart';
import '../provider/service_locator.dart';

class FlipbookViewModel extends ChangeNotifier {
  final ServiceLocator _serviceLocator = ServiceLocator();

  late AudioService _audioService;
  late StoryService _storyService;
  late StoryRepository _storyRepository;

  // State variables
  BookModel? _story;
  int _currentPage = 0;
  Language _selectedLanguage = Language.indonesia;
  bool _isLoading = false;
  bool _isPlayingPageAudio = false;
  bool _isPlayingObjectAudio = false;
  bool _isPlayingFullBook = false;
  String? _error;

  // Track currently playing object audio for multiple objects support
  String? _currentPlayingObjectAudio;

  // Navigation state to prevent double clicks
  bool _isNavigating = false;

  // Callback for auto-navigation
  VoidCallback? _onAutoNavigate;

  // Constructor
  FlipbookViewModel() {
    _audioService = _serviceLocator.audioService;
    _storyService = _serviceLocator.storyService;
    _storyRepository = _serviceLocator.storyRepository;
  }

  // Getters
  BookModel? get story => _story;
  int get currentPage => _currentPage;
  Language get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;
  bool get isPlayingPageAudio => _isPlayingPageAudio;
  bool get isPlayingObjectAudio => _isPlayingObjectAudio;
  bool get isPlayingFullBook => _isPlayingFullBook;
  String? get error => _error;
  bool get isNavigating => _isNavigating;
  String? get currentPlayingObjectAudio => _currentPlayingObjectAudio;

  // Updated page checking logic to include last page widget
  bool get isFirstPage => _currentPage == 0;
  bool get isLastPage => _story != null ? _currentPage >= _story!.pages.length : false;

  // Total pages including the last page widget
  int get totalPages => _story != null ? _story!.pages.length + 1 : 0;

  // Set auto-navigation callback
  void setAutoNavigationCallback(VoidCallback callback) {
    _onAutoNavigate = callback;
  }

  // Public methods
  Future<void> loadStory(String storyId) async {
    _setLoading(true);
    _setError(null);

    // Reset current page when loading new story
    _currentPage = 0;
    _setNavigating(false);
    _currentPlayingObjectAudio = null;

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
      final audioPaths = await _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);

      print('Attempting to play audio from paths: $audioPaths');

      if (_selectedLanguage == Language.keduanya) {
        await _audioService.playSequentialAudio(audioPaths); // Memutar semua audio secara berurutan
      } else {
        await _audioService.playAudio(audioPaths.first); // Memutar audio tunggal
      }

    } catch (e, stackTrace) {
      print('Audio playback error: $e\n$stackTrace');
      _setError('Failed to play page audio: $e');
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  Future<void> playFullBookAudio(String storyId) async {
    if (_isPlayingFullBook || _story == null) return;

    _setPlayingFullBook(true);

    try {
      // Start from current page, but only play story pages (not the last page widget)
      for (int i = _currentPage; i < _story!.pages.length; i++) {
        // ✅ Check if user stopped the playbook BEFORE playing audio
        if (!_isPlayingFullBook) {
          break;
        }

        // Play audio for current page FIRST
        final pageNumber = i + 1;
        final audioPaths = await _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);

        print('Playing page $pageNumber audio with language: $_selectedLanguage');
        print('Audio paths: $audioPaths');

        // ✅ PERBAIKAN: Konsisten dengan playPageAudio method
        if (_selectedLanguage == Language.keduanya) {
          await _audioService.playSequentialAudio(audioPaths);
        } else {
          await _audioService.playAudio(audioPaths.first);
        }

        // ✅ Check again after audio playback
        if (!_isPlayingFullBook) {
          break;
        }

        // Add small delay between pages for better UX
        await Future.delayed(const Duration(milliseconds: 500));

        // Only navigate to next page if not the last story page
        if (i < _story!.pages.length - 1) {
          // Update current page
          _currentPage = i + 1;
          notifyListeners();

          // ✅ PERBAIKAN: Trigger page flip animation dengan null check
          if (_onAutoNavigate != null) {
            _onAutoNavigate!();
          } else {
            print('Warning: Auto navigation callback not set');
          }

          // Small delay after page flip
          await Future.delayed(const Duration(milliseconds: 800)); // ✅ Increased delay
        }
      }
    } catch (e) {
      print('Full book audio error: $e');
      _setError('Failed to play full book audio: $e');
    } finally {
      // ✅ PERBAIKAN: Pastikan state di-reset dengan benar
      _setPlayingFullBook(false);
    }
  }

  void stopFullBookAudio() {
    _setPlayingFullBook(false);
    _audioService.stopAudio();
  }

  Future<void> playObjectAudio(String storyId, String audioFile) async {
    // Stop current object audio if different audio is requested
    if (_isPlayingObjectAudio && _currentPlayingObjectAudio != audioFile) {
      _audioService.stopAudio();
      _setPlayingObjectAudio(false);
      _currentPlayingObjectAudio = null;
    }

    if (_isPlayingObjectAudio && _currentPlayingObjectAudio == audioFile) {
      // If same audio is already playing, stop it
      _audioService.stopAudio();
      _setPlayingObjectAudio(false);
      _currentPlayingObjectAudio = null;
      return;
    }

    _setCurrentPlayingObjectAudio(audioFile);
    _setPlayingObjectAudio(true);

    try {
      final audioPath = await _storyService.generateObjectAudioPath(storyId, audioFile);
      await _audioService.playAudio(audioPath);

      // Add delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      _setError('Failed to play object audio: $e');
    } finally {
      _setPlayingObjectAudio(false);
      _currentPlayingObjectAudio = null;
    }
  }

  // New method to play all interactive object audios in sequence for current page
  Future<void> playAllObjectAudiosInPage(String storyId) async {
    if (_story == null || _currentPage >= _story!.pages.length) return;

    final currentStoryPage = _story!.pages[_currentPage];

    if (currentStoryPage.interactiveObjects.isEmpty) return;

    for (final obj in currentStoryPage.interactiveObjects) {
      if (obj.audioObject != null && obj.audioObject!.isNotEmpty) {
        await playObjectAudio(storyId, obj.audioObject!);

        // Wait for audio to finish before playing next
        while (_isPlayingObjectAudio) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Small delay between objects
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  void changeLanguage(Language newLanguage) {
    if (_selectedLanguage != newLanguage) {
      _selectedLanguage = newLanguage;
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (_isNavigating || _story == null || _currentPage >= _story!.pages.length) return;

    _setNavigating(true);
    _audioService.stopAudio();
    _setPlayingObjectAudio(false);
    _currentPlayingObjectAudio = null;

    _currentPage++;
    notifyListeners();

    // Wait for animation to complete before allowing next navigation
    await Future.delayed(const Duration(milliseconds: 600));
    _setNavigating(false);
  }

  Future<void> previousPage() async {
    if (_isNavigating || _currentPage <= 0) return;

    _setNavigating(true);
    _audioService.stopAudio();
    _setPlayingObjectAudio(false);
    _currentPlayingObjectAudio = null;

    _currentPage--;
    notifyListeners();

    // Wait for animation to complete before allowing next navigation
    await Future.delayed(const Duration(milliseconds: 600));
    _setNavigating(false);
  }

  void setCurrentPage(int page) {
    if (page >= 0 && _story != null && page <= _story!.pages.length) {
      _currentPage = page;
      _currentPlayingObjectAudio = null;
      notifyListeners();
    }
  }

  void stopAudio() {
    _audioService.stopAudio();
    _setPlayingPageAudio(false);
    _setPlayingObjectAudio(false);
    _setPlayingFullBook(false);
    _currentPlayingObjectAudio = null;
  }

  // Updated methods for multiple interactive objects support
  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    return _storyService.calculatePageLayout(page, constraints);
  }

  List<PageLayout> calculateInteractiveObjectsLayout(StoryPage page, BoxConstraints constraints) {
    return _storyService.calculateInteractiveObjectsLayout(page, constraints);
  }

  // Helper methods for interactive objects
  bool hasInteractiveObjects(StoryPage page) {
    return _storyService.hasInteractiveObjects(page);
  }

  int getInteractiveObjectsCount(StoryPage page) {
    return _storyService.getInteractiveObjectsCount(page);
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

  void _setPlayingFullBook(bool playing) {
    _isPlayingFullBook = playing;
    notifyListeners();
  }

  void _setNavigating(bool navigating) {
    _isNavigating = navigating;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setCurrentPlayingObjectAudio(String? audioFile) {
    _currentPlayingObjectAudio = audioFile;
    notifyListeners();
  }

  @override
  void dispose() {
    // Stop semua audio yang sedang berjalan
    stopAudio();

    // Reset semua state
    _currentPage = 0;
    _isPlayingPageAudio = false;
    _isPlayingObjectAudio = false;
    _isPlayingFullBook = false;
    _currentPlayingObjectAudio = null;
    _story = null;

    // Dispose audio service
    _audioService.dispose();

    super.dispose();
  }
}