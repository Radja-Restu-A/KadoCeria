import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import '../models/book_model.dart';
import '../services/audio_service.dart';
import '../services/story_service.dart';
import '../repositories/story_repository.dart';

enum AudioErrorType {
  pageAudio,
  fullBookAudio,
}

typedef AudioErrorCallback = void Function(AudioErrorType errorType, String errorMessage);

class FlipbookViewModel extends ChangeNotifier {
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

  // Audio error modal
  AudioErrorCallback? _onAudioError;

  // Constructor
  FlipbookViewModel() {
    _audioService = AudioService();
    _storyService = StoryService();
    _storyRepository = StoryRepository();
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

  void setAudioErrorCallback(AudioErrorCallback callback) {
    _onAudioError = callback;
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
        await _audioService.playSequentialAudio(audioPaths);
      } else {
        await _audioService.playAudio(audioPaths.first);
      }

    } catch (e, stackTrace) {
      print('Audio playback error: $e\n$stackTrace');

      // ✅ MODIFIKASI: Panggil callback error invece of setting error state
      if (_onAudioError != null) {
        _onAudioError!(AudioErrorType.pageAudio, e.toString());
      }
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  Future<void> playFullBookAudio(String storyId) async {
    if (_isPlayingFullBook || _story == null) return;

    _setPlayingFullBook(true);

    try {
      // Start from current page, play all story pages
      for (int i = _currentPage; i < _story!.pages.length; i++) {
        if (!_isPlayingFullBook) {
          break;
        }

        try {
          // Play audio for current page FIRST
          final pageNumber = i + 1;
          final audioPaths = await _storyService.generateAudioPaths(storyId, pageNumber, _selectedLanguage);

          print('Playing page $pageNumber audio with language: $_selectedLanguage');
          print('Audio paths: $audioPaths');

          if (_selectedLanguage == Language.keduanya) {
            await _audioService.playSequentialAudio(audioPaths);
          } else {
            await _audioService.playAudio(audioPaths.first);
          }

          if (!_isPlayingFullBook) {
            break;
          }

          // Add small delay between pages for better UX
          await Future.delayed(const Duration(milliseconds: 500));

          // Navigate to next page
          _currentPage = i + 1;
          notifyListeners();

          if (_onAutoNavigate != null) {
            _onAutoNavigate!();
          } else {
            print('Warning: Auto navigation callback not set');
          }

          // Small delay after page flip
          await Future.delayed(const Duration(milliseconds: 800));

        } catch (e) {
          print('Error playing audio for page ${i + 1}: $e');

          // ✅ MODIFIKASI: Panggil callback error untuk full book
          if (_onAudioError != null) {
            _onAudioError!(AudioErrorType.fullBookAudio, e.toString());
            return; // Stop execution and wait for user decision
          }
        }
      }

      // Navigate to the last page if we finished all story pages
      if (_isPlayingFullBook && _currentPage < totalPages - 1) {
        print('Navigating to last page (buildLastPage)');

        // Update to last page
        _currentPage = _story!.pages.length;
        notifyListeners();

        // Trigger navigation to last page
        if (_onAutoNavigate != null) {
          _onAutoNavigate!();
        }
      }

    } catch (e) {
      print('Full book audio error: $e');

      // ✅ MODIFIKASI: Panggil callback error
      if (_onAudioError != null) {
        _onAudioError!(AudioErrorType.fullBookAudio, e.toString());
      }
    } finally {
      _setPlayingFullBook(false);
    }
  }

  Future<void> continueFullBookFromNextPage(String storyId) async {
    if (_story == null) {
      _setPlayingFullBook(false);
      return;
    }

    if (_currentPage >= _story!.pages.length) {
      _setPlayingFullBook(false);
      return;
    }

    // Move to next page
    _currentPage++;
    notifyListeners();

    if (_onAutoNavigate != null) {
      _onAutoNavigate!();
    }

    // Small delay after page flip
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentPage >= _story!.pages.length) {
      // Kita sudah sampai di last page, stop full book audio karena last page tidak memiliki audio
      print('Reached last page, stopping full book audio');
      _setPlayingFullBook(false);
      return;
    }

    // ✅ PERBAIKAN: Hanya lanjutkan playFullBookAudio jika masih ada story pages yang tersisa
    await playFullBookAudio(storyId);
  }

  void stopFullBookAudio() {
    _setPlayingFullBook(false);
    _audioService.stopAudio();
  }

  // ✅ MODIFIED: Updated playObjectAudio to always play both languages (Sunda first, then Indonesia)
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
      // ✅ NEW: Always generate both audio paths (Sunda first, then Indonesia)
      final audioPaths = await _storyService.generateObjectAudioPathsBothLanguages(storyId, audioFile);

      print('Playing object audio in both languages (Sunda -> Indonesia)');
      print('Object audio paths: $audioPaths');

      // ✅ NEW: Always play both languages sequentially
      await _audioService.playSequentialAudio(audioPaths);

      // Add delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

    } catch (e) {
      print('Object audio playback error: $e');
      _setError('Failed to play object audio: $e');
    } finally {
      _setPlayingObjectAudio(false);
      _currentPlayingObjectAudio = null;
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
    // await Future.delayed(const Duration(milliseconds: 600));
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
    // await Future.delayed(const Duration(milliseconds: 600));
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