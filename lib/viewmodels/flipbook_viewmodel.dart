import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../models/book_model.dart';
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
  BookModel? _story;
  int _currentPage = 0;
  Language _selectedLanguage = Language.indonesia;
  bool _isLoading = false;
  bool _isPlayingPageAudio = false;
  bool _isPlayingObjectAudio = false;
  bool _isPlayingFullBook = false;
  String? _error;

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
        await _audioService.playAudio(audioPaths.first);
      } else {
        await _audioService.playAudio(audioPaths.first);
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
        // Play audio for current page FIRST
        final pageNumber = i + 1;
        final audioPaths = await _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);

        if (_selectedLanguage == Language.keduanya) {
          await _audioService.playSequentialAudio(audioPaths);
        } else {
          await _audioService.playAudio(audioPaths.first);
        }

        // Check if user stopped the playback
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

          // Trigger page flip animation
          if (_onAutoNavigate != null) {
            _onAutoNavigate!();
          }

          // Small delay after page flip
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      _setError('Failed to play full book audio: $e');
    } finally {
      _setPlayingFullBook(false);
    }
  }

  void stopFullBookAudio() {
    _setPlayingFullBook(false);
    _audioService.stopAudio();
  }

  Future<void> playObjectAudio(String storyId, String audioFile) async {
    if (_isPlayingObjectAudio) return;

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

    _currentPage--;
    notifyListeners();

    // Wait for animation to complete before allowing next navigation
    await Future.delayed(const Duration(milliseconds: 600));
    _setNavigating(false);
  }

  void setCurrentPage(int page) {
    if (page >= 0 && _story != null && page <= _story!.pages.length) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void stopAudio() {
    _audioService.stopAudio();
    _setPlayingPageAudio(false);
    _setPlayingObjectAudio(false);
    _setPlayingFullBook(false);
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

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}