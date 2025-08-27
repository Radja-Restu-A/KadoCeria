import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
typedef StoryLoadedCallback = void Function();

class LayoutCalculationResult {
  final double headerHeight;
  final double contentHeight;
  final double footerHeight;
  final double? imageAspectRatio;

  LayoutCalculationResult({
    required this.headerHeight,
    required this.contentHeight,
    required this.footerHeight,
    this.imageAspectRatio,
  });
}

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
  bool _isPlayingBacksoundAudio = false;
  String? _error;

  // Layout calculation state
  double? _imageAspectRatio;
  bool _isCalculatingLayout = false;

  // Track currently playing object audio for multiple objects support
  String? _currentPlayingObjectAudio;

  // Navigation state to prevent double clicks
  bool _isNavigating = false;

  // Callbacks
  VoidCallback? _onAutoNavigate;
  AudioErrorCallback? _onAudioError;
  StoryLoadedCallback? _onStoryLoaded;

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
  bool get isPlayingBacksoundAudio => _isPlayingBacksoundAudio;
  String? get error => _error;
  bool get isNavigating => _isNavigating;
  String? get currentPlayingObjectAudio => _currentPlayingObjectAudio;
  bool get hasAnyAudioPlaying => _isPlayingPageAudio || _isPlayingFullBook;
  double? get imageAspectRatio => _imageAspectRatio;
  bool get isCalculatingLayout => _isCalculatingLayout;

  // Updated page checking logic to include last page widget
  bool get isFirstPage => _currentPage == 0;
  bool get isLastPage => _story != null ? _currentPage >= _story!.pages.length : false;

  // Dan update totalPages:
  int get totalPages => _story != null ? _story!.pages.length + 2 : 0; // +2 untuk senarai kata dan last page

  // Check if story is loaded and layout is ready
  bool get isReadyForDisplay => _story != null && _imageAspectRatio != null && !_isLoading;

  // Set callbacks
  void setAutoNavigationCallback(VoidCallback callback) {
    _onAutoNavigate = callback;
  }

  void setAudioErrorCallback(AudioErrorCallback callback) {
    _onAudioError = callback;
  }

  void setStoryLoadedCallback(StoryLoadedCallback callback) {
    _onStoryLoaded = callback;
  }

  // Public methods
  Future<void> loadStory(String storyId) async {
    _setLoading(true);
    _setError(null);

    // Reset current page when loading new story
    _currentPage = 0;
    _setNavigating(false);
    _currentPlayingObjectAudio = null;
    _imageAspectRatio = null;

    try {
      _story = await _storyRepository.getStory(storyId);

      // Calculate image aspect ratio after story is loaded
      await _calculateImageAspectRatio();

      // Notify that story is loaded
      if (_onStoryLoaded != null) {
        _onStoryLoaded!();
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load story: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Extract aspect ratio calculation logic from UI
  Future<void> _calculateImageAspectRatio() async {
    if (_story == null || _story!.pages.isEmpty) {
      _imageAspectRatio = 4 / 3; // fallback
      return;
    }

    _isCalculatingLayout = true;
    notifyListeners();

    try {
      final firstPage = _story!.pages.first;
      final firstPageImage = firstPage.image;

      // Pastikan image tidak null dan tidak kosong
      if (firstPageImage == null || firstPageImage.isEmpty) {
        _imageAspectRatio = 4 / 3; // fallback
        return;
      }

      // Create a completer to handle async image loading
      final completer = Completer<double>();

      final ImageStream stream = AssetImage(firstPageImage).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;

      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        final double ratio = info.image.width / info.image.height;
        stream.removeListener(listener);
        completer.complete(ratio);
      }, onError: (exception, stackTrace) {
        stream.removeListener(listener);
        completer.complete(4 / 3); // fallback on error
      });

      stream.addListener(listener);

      // Wait for the aspect ratio calculation with timeout
      _imageAspectRatio = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => 4 / 3, // fallback on timeout
      );

    } catch (e) {
      print('Error calculating aspect ratio: $e');
      _imageAspectRatio = 4 / 3; // fallback
    } finally {
      _isCalculatingLayout = false;
      notifyListeners();
    }
  }

  // Extract responsive layout calculation from UI
  LayoutCalculationResult calculateResponsiveLayout(BoxConstraints constraints) {
    if (_imageAspectRatio == null) {
      // Return default layout if aspect ratio not calculated yet
      return LayoutCalculationResult(
        headerHeight: constraints.maxHeight * 0.15,
        contentHeight: constraints.maxHeight * 0.70,
        footerHeight: constraints.maxHeight * 0.15,
        imageAspectRatio: _imageAspectRatio,
      );
    }

    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // Hitung tinggi content berdasarkan lebar dan aspect ratio
    final contentHeight = availableWidth / _imageAspectRatio!;

    // Pastikan content tidak melebihi 70% dari tinggi layar
    final maxContentHeight = availableHeight * 0.7;
    final finalContentHeight = contentHeight > maxContentHeight
        ? maxContentHeight
        : contentHeight;

    // Hitung sisa tinggi untuk header dan footer
    final remainingHeight = availableHeight - finalContentHeight;
    final headerHeight = remainingHeight * 0.3;
    final footerHeight = remainingHeight * 0.7;

    return LayoutCalculationResult(
      headerHeight: headerHeight,
      contentHeight: finalContentHeight,
      footerHeight: footerHeight,
      imageAspectRatio: _imageAspectRatio,
    );
  }

  // Check if we're on special pages
  bool get isOnSenaraiKataPage => _story != null && _currentPage == _story!.pages.length;
  bool get isOnCompletionPage => _story != null && _currentPage > _story!.pages.length;
  bool get isOnFinalCompletionPage => _story != null && _currentPage > _story!.pages.length;

  List<Map<String, String>> getSenaraiKata(String bookId) {
    switch (bookId) {
      case '1':
        return SakeclakSenaraiKata();
      case '2':
        return JanitiSenaraiKata();
      default:
        return standarSenaraiKata();
    }
  }

  List<Map<String, String>> SakeclakSenaraiKata() {
    return [
      {'indonesia': 'awan', 'sunda': 'awan'},
      {'indonesia': 'bambu', 'sunda': 'awi'},
      {'indonesia': 'kapal', 'sunda': 'parahu'},
      {'indonesia': 'kucing', 'sunda': 'ucing'},
      {'indonesia': 'layang-layang', 'sunda': 'langlayangan'},
      {'indonesia': 'matahari', 'sunda': 'panonpoé'},
      {'indonesia': 'ombak', 'sunda': 'ombak'},
      {'indonesia': 'orang-orangan sawah', 'sunda': 'bebegig sawah'},
      {'indonesia': 'panci', 'sunda': 'panci'},
      {'indonesia': 'rumah', 'sunda': 'imah'},
      {'indonesia': 'saung', 'sunda': 'saung'},
      {'indonesia': 'selokan', 'sunda': 'solokan'},
      {'indonesia': 'sungai', 'sunda': 'walungan'},
      {'indonesia': 'tempat sampah', 'sunda': 'wadah runtah'},
      {'indonesia': 'tungku api', 'sunda': 'hawu'},
    ];
  }

  List<Map<String, String>> JanitiSenaraiKata() {
    return [
      {'indonesia': 'anggur', 'sunda': 'anggur'},
      {'indonesia': 'apel', 'sunda': 'apel'},
      {'indonesia': 'beruang', 'sunda': 'biruang'},
      {'indonesia': 'buaya', 'sunda': 'buhaya'},
      {'indonesia': 'bunga', 'sunda': 'kembang'},
      {'indonesia': 'burung', 'sunda': 'manuk'},
      {'indonesia': 'gajah', 'sunda': 'gajah'},
      {'indonesia': 'jerapah', 'sunda': 'jarapah'},
      {'indonesia': 'kupu-kupu', 'sunda': 'kukupu'},
      {'indonesia': 'monyet', 'sunda': 'monyet'},
      {'indonesia': 'nanas', 'sunda': 'ganas'},
      {'indonesia': 'pisang', 'sunda': 'cau'},
      {'indonesia': 'rumah', 'sunda': 'imah'},
      {'indonesia': 'semangka', 'sunda': 'samangka'},
      {'indonesia': 'singa', 'sunda': 'singa'},
    ];
  }

  List<Map<String, String>> standarSenaraiKata() {
    // Return a default set or empty list
    return [
      {'indonesia': 'Ditunggu', 'sunda': 'Diantos'},
    ];
  }

  Future<void> playBacksoundAudio(String storyId) async {
    if (_story == null || _currentPage >= _story!.pages.length) return;

    final currentStorypage = _story!.pages[_currentPage];

    if (currentStorypage.backsound == null || currentStorypage.backsound!.isEmpty) {
      print("No backsound available for page ${_currentPage + 1}");
      return;
    }

    if (_isPlayingBacksoundAudio) {
      stopBacksoundAudio();
      return;
    }

    _setPlayingBacksound(true);

    try{
      final backsoundPath = currentStorypage.backsound!;

      print('Playing backsound: $backsoundPath');
      print('Current page: ${_currentPage + 1}');

      await _audioService.playAudioLoop(backsoundPath);
    }catch (e){
      print('Backsound playback error: $e');
      _setError('Failed to play backsound: $e');
      _setPlayingBacksound(false);
    }
  }

  void stopBacksoundAudio() {
    if (_isPlayingBacksoundAudio) {
      _audioService.stopBacksoundAudio(); // Anda perlu menambahkan ini di AudioService
      _setPlayingBacksound(false);
    }
  }

  // Audio control methods
  Future<void> playPageAudio(String storyId) async {
    if (_isPlayingPageAudio || _isPlayingFullBook || _story == null) return;

    _setPlayingPageAudio(true);

    try {
      final pageNumber = _currentPage + 1;
      final audioPaths = await _storyService.generateAudioNarationPaths(storyId, pageNumber, _selectedLanguage);

      print('Attempting to play audio from paths: $audioPaths');

      if (_selectedLanguage == Language.keduanya) {
        await _audioService.playSequentialAudio(audioPaths);
      } else {
        await _audioService.playAudio(audioPaths.first);
      }

    } catch (e, stackTrace) {
      print('Audio playback error: $e\n$stackTrace');

      if (_onAudioError != null) {
        _onAudioError!(AudioErrorType.pageAudio, e.toString());
      }
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  Future<void> playFullBookAudio(String storyId) async {
    if (_isPlayingFullBook || _isPlayingPageAudio || _story == null) return;

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
          final audioPaths = await _storyService.generateAudioNarationPaths(storyId, pageNumber, _selectedLanguage);

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

          if (_onAudioError != null) {
            _onAudioError!(AudioErrorType.fullBookAudio, e.toString());
            return;
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

    // Hanya lanjutkan playFullBookAudio jika masih ada story pages yang tersisa
    await playFullBookAudio(storyId);
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
      // Always generate both audio paths (Sunda first, then Indonesia)
      final audioPaths = await _storyService.generateObjectAudioPaths(storyId, audioFile);

      print('Playing object audio in both languages (Sunda -> Indonesia)');
      print('Object audio paths: $audioPaths');

      // Always play both languages sequentially
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
    if (_isNavigating || _story == null) return;

    // Allow navigation to completion page (one page beyond story pages and senarai kata)
    final maxAllowedPage = _story!.pages.length + 1; // +1 untuk completion page
    if (_currentPage >= maxAllowedPage) return;

    _setNavigating(true);
    _audioService.stopAudio();
    _setPlayingObjectAudio(false);
    _currentPlayingObjectAudio = null;

    _currentPage++;
    notifyListeners();

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
    stopBacksoundAudio();
    _setPlayingPageAudio(false);
    _setPlayingObjectAudio(false);
    _setPlayingFullBook(false);
    _currentPlayingObjectAudio = null;
  }

  // Layout calculation methods for interactive objects
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

  void _setPlayingBacksound(bool playing) {
    _isPlayingBacksoundAudio = playing;
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
    _imageAspectRatio = null;
    _story = null;

    // Dispose audio service
    _audioService.dispose();

    super.dispose();
  }
}