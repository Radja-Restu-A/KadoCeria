import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_model_bundle.dart';
import '../services/audio_service.dart';
import '../services/book_service.dart';
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
  late BookService _bookService;
  late StoryRepository _storyRepository;

  // State variables
  BookModelBundle? _story;
  int _currentPage = 0;
  Language _selectedLanguage = Language.indonesia;
  bool _isLoading = false;
  bool _isPlayingPageAudio = false;
  bool _isPlayingObjectAudio = false;
  bool _isPlayingFullBook = false;
  bool _isPlayingBacksoundAudio = false;
  String? _error;
  String _currentBacksoundPath = '';

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
    _bookService = BookService();
    _storyRepository = StoryRepository();
  }

  // Getters
  BookModelBundle? get story => _story;
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
    debugPrint('[FlipbookViewModel] Loading story with ID: $storyId');
    _setLoading(true);
    _setError(null);

    // Reset current page when loading new story
    _currentPage = 0;
    _setNavigating(false);
    _currentPlayingObjectAudio = null;
    _imageAspectRatio = null;

    try {
      _story = await _storyRepository.getStory(storyId);
      debugPrint('[FlipbookViewModel] Story object retrieved. isBundled: ${_story?.isBundled}');

      // Calculate image aspect ratio after story is loaded
      await _calculateImageAspectRatio();

      // Notify that story is loaded
      if (_onStoryLoaded != null) {
        _onStoryLoaded!();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[FlipbookViewModel] ERROR loading story: $e');
      _setError('Failed to load story: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Extract aspect ratio calculation logic from UI
  Future<void> _calculateImageAspectRatio() async {
    debugPrint('[FlipbookViewModel] Starting aspect ratio calculation...');
    if (_story == null || _story!.pages.isEmpty) {
      debugPrint('[FlipbookViewModel] Story or pages is empty, using fallback ratio');
      _imageAspectRatio = 4 / 3; // fallback
      return;
    }

    _isCalculatingLayout = true;
    notifyListeners();

    try {
      final firstPage = _story!.pages.first;
      final firstPageImage = firstPage.image;
      debugPrint('[FlipbookViewModel] First page image path: $firstPageImage');

      // Pastikan image tidak null dan tidak kosong
      if (firstPageImage == null || firstPageImage.isEmpty) {
        debugPrint('[FlipbookViewModel] Image path is null/empty, using fallback');
        _imageAspectRatio = 4 / 3; // fallback
        return;
      }

      // Create a completer to handle async image loading
      final completer = Completer<double>();

      ImageProvider imageProvider;
      if (_story!.isBundled) {
        debugPrint('[FlipbookViewModel] Using AssetImage for aspect ratio');
        imageProvider = AssetImage(firstPageImage);
      } else {
        final localPath = '${_story!.localDirectoryPath}/$firstPageImage';
        debugPrint('[FlipbookViewModel] Using FileImage for aspect ratio at: $localPath');
        final file = File(localPath);
        if (!file.existsSync()) {
          debugPrint('[FlipbookViewModel] WARNING: Local image file does NOT exist!');
        }
        imageProvider = FileImage(file);
      }

      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;

      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        final double ratio = info.image.width / info.image.height;
        debugPrint('[FlipbookViewModel] Aspect ratio calculated: $ratio (synch: $synchronousCall)');
        stream.removeListener(listener);
        completer.complete(ratio);
      }, onError: (exception, stackTrace) {
        debugPrint('[FlipbookViewModel] ERROR in ImageStreamListener: $exception');
        stream.removeListener(listener);
        completer.complete(4 / 3); // fallback on error
      });

      stream.addListener(listener);

      // Wait for the aspect ratio calculation with timeout
      _imageAspectRatio = await completer.future.timeout(
        const Duration(seconds: 10), // Increased timeout to 10s for debugging
        onTimeout: () {
          debugPrint('[FlipbookViewModel] TIMEOUT during aspect ratio calculation');
          return 4 / 3;
        },
      );
      debugPrint('[FlipbookViewModel] Final aspect ratio set: $_imageAspectRatio');

    } catch (e) {
      debugPrint('[FlipbookViewModel] CRITICAL ERROR calculating aspect ratio: $e');
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
        return sakeclakSenaraiKata();
      case '2':
        return janitiSenaraiKata();
      default:
        return standarSenaraiKata();
    }
  }

  List<Map<String, String>> sakeclakSenaraiKata() {
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

  List<Map<String, String>> janitiSenaraiKata() {
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

  // Helper to resolve paths based on bundle status
  String _resolvePath(String? path) {
    if (path == null || path.isEmpty) return '';
    if (_story!.isBundled) return path;
    // Jika path sudah mengandung localDirectoryPath (absolut), jangan tambahkan lagi
    if (path.startsWith(_story!.localDirectoryPath!)) return path;
    return '${_story!.localDirectoryPath}/$path';
  }

  Future<void> playBacksoundAudio(String storyId) async {
    if (_story == null || _currentPage >= _story!.pages.length) return;

    if (isOnSenaraiKataPage || isOnCompletionPage) {
      if (_isPlayingBacksoundAudio) {
        debugPrint("On additional page, stopping backsound");
        stopBacksoundAudio();
      }
      return;
    }

    final currentStorypage = _story!.pages[_currentPage];

    // Jika page saat ini tidak ada backsound
    if (currentStorypage.backsound == null || currentStorypage.backsound!.isEmpty) {
      debugPrint("No backsound available for page ${_currentPage + 1}");
      if (_isPlayingBacksoundAudio) {
        stopBacksoundAudio();
      }
      return;
    }

    final currentBacksoundPath = _resolvePath(currentStorypage.backsound);

    try {
      // AudioService handles idempotency, but we keep state here for UI
      _currentBacksoundPath = currentBacksoundPath;
      _setPlayingBacksound(true);

      debugPrint('Playing backsound for page ${_currentPage + 1}: $currentBacksoundPath');

      // Gunakan AudioService yang sudah ada untuk play audio loop
      await _audioService.playAudioLoop(currentBacksoundPath, isBundled: _story!.isBundled);
    } catch (e) {
      debugPrint('Backsound playback error: $e');
      _setError('Failed to play backsound: $e');
      _setPlayingBacksound(false);
      _currentBacksoundPath = '';
    }
  }

// Update method stopBacksoundAudio untuk clear tracking path
  void stopBacksoundAudio() {
    if (_isPlayingBacksoundAudio) {
      debugPrint("Stopping backsound: $_currentBacksoundPath");
      _audioService.stopBacksoundAudio();
      _setPlayingBacksound(false);
      _currentBacksoundPath = ''; // Clear tracking path
    }
  }

  // Audio control methods
  Future<void> playPageAudio(String storyId) async {
    if (_isPlayingPageAudio || _isPlayingFullBook || _story == null) return;

    // Guard against additional pages (Senarai Kata or Completion Page)
    if (_currentPage >= _story!.pages.length) {
      debugPrint('No narration audio for special page index: $_currentPage');
      return;
    }

    _setPlayingPageAudio(true);

    try {
      final page = _story!.pages[_currentPage];
      final List<String> audioPaths = [];

      switch (_selectedLanguage) {
        case Language.indonesia:
          if (page.narationId != null) audioPaths.add(_resolvePath(page.narationId));
          break;

        case Language.sunda:
          if (page.narationSd != null) audioPaths.add(_resolvePath(page.narationSd));
          break;

        case Language.keduanya:
          if (page.narationSd != null) audioPaths.add(_resolvePath(page.narationSd));
          if (page.narationId != null) audioPaths.add(_resolvePath(page.narationId));
          break;
      }

      if (audioPaths.isEmpty) {
        debugPrint('No narration audio found for page ${_currentPage + 1}');
        _setPlayingPageAudio(false);
        return;
      }

      debugPrint('Playing page ${_currentPage + 1} audio: $audioPaths');

      if (_selectedLanguage == Language.keduanya) {
        await _audioService.playSequentialAudio(audioPaths, isBundled: _story!.isBundled);
      } else {
        await _audioService.playAudio(audioPaths.first, isBundled: _story!.isBundled);
      }

    } catch (e, stackTrace) {
      debugPrint('Audio playback error: $e\n$stackTrace');
      _onAudioError?.call(AudioErrorType.pageAudio, e.toString());
    } finally {
      _setPlayingPageAudio(false);
    }
  }

  Future<void> playFullBookAudio(String storyId) async {
    if (_isPlayingFullBook || _isPlayingPageAudio || _story == null) return;

    _setPlayingFullBook(true);

    try {
      for (int i = _currentPage; i < _story!.pages.length; i++) {
        if (!_isPlayingFullBook) break;

        final page = _story!.pages[i];
        final List<String> audioPaths = [];

        // Ambil path berdasarkan bahasa
        switch (_selectedLanguage) {
          case Language.indonesia:
            if (page.narationId != null) audioPaths.add(_resolvePath(page.narationId));
            break;
          case Language.sunda:
            if (page.narationSd != null) audioPaths.add(_resolvePath(page.narationSd));
            break;
          case Language.keduanya:
            if (page.narationSd != null) audioPaths.add(_resolvePath(page.narationSd));
            if (page.narationId != null) audioPaths.add(_resolvePath(page.narationId));
            break;
        }

        if (audioPaths.isEmpty) {
          debugPrint('Skipping page ${i + 1} — no narration audio.');
          continue;
        }

        debugPrint('Playing page ${i + 1} audio: $audioPaths');

        if (_selectedLanguage == Language.keduanya) {
          await _audioService.playSequentialAudio(audioPaths, isBundled: _story!.isBundled);
        } else {
          await _audioService.playAudio(audioPaths.first, isBundled: _story!.isBundled);
        }

        // Delay kecil agar tidak tumpang tindih
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigasi otomatis ke halaman berikutnya
        _currentPage = i + 1;
        notifyListeners();
        _onAutoNavigate?.call();

        await Future.delayed(const Duration(milliseconds: 800));
      }
    } catch (e) {
      debugPrint('Full book audio error: $e');
      _onAudioError?.call(AudioErrorType.fullBookAudio, e.toString());
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
      debugPrint('Reached last page, stopping full book audio');
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
    // Hentikan audio sebelumnya bila ada yang sedang dimainkan
    if (_isPlayingObjectAudio && _currentPlayingObjectAudio != null) {
      _audioService.stopAudio();
      _setPlayingObjectAudio(false);
      _currentPlayingObjectAudio = null;
    }

    _setPlayingObjectAudio(true);

    try {
      // Pastikan story sudah dimuat
      if (_story == null) {
        debugPrint('Story not loaded. Cannot play object audio.');
        return;
      }

      // Cari semua object interaktif di seluruh halaman
      final allObjects = _story!.pages.expand((page) => page.interactiveObjects).toList();

      // Temukan objek berdasarkan audioFile yang dikirim dari UI
      final matchedObject = allObjects.firstWhere(
            (obj) => obj.audioObjectId == audioFile || obj.audioObjectSd == audioFile,
        orElse: () => throw Exception('Interactive object not found for $audioFile'),
      );

      // Kumpulkan path audio yang akan diputar
      final List<String> audioPaths = [];

      if (matchedObject.audioObjectSd != null) {
        audioPaths.add(_resolvePath(matchedObject.audioObjectSd)); // Sunda dulu
      }

      if (matchedObject.audioObjectId != null) {
        audioPaths.add(_resolvePath(matchedObject.audioObjectId)); // Indonesia kemudian
      }

      if (audioPaths.isEmpty) {
        debugPrint('No audio paths found for object: $audioFile');
        return;
      }

      _currentPlayingObjectAudio = audioFile;
      debugPrint('Playing object audios sequentially (Sunda → Indonesia): $audioPaths');

      // Selalu mainkan dua bahasa berurutan
      await _audioService.playSequentialAudio(audioPaths, isBundled: _story!.isBundled);

      await Future.delayed(const Duration(milliseconds: 300));

    } catch (e) {
      debugPrint('Object audio playback error: $e');
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
    _setPlayingBacksound(false);
    _setPlayingPageAudio(false);
    _setPlayingObjectAudio(false);
    _setPlayingFullBook(false);
    _currentPlayingObjectAudio = null;
    _currentBacksoundPath = ''; // Clear tracking path
  }

  // Layout calculation methods for interactive objects
  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    return _bookService.calculatePageLayout(page, constraints);
  }

  List<PageLayout> calculateInteractiveObjectsLayout(StoryPage page, BoxConstraints constraints) {
    return _bookService.calculateInteractiveObjectsLayout(page, constraints);
  }

  // Helper methods for interactive objects
  bool hasInteractiveObjects(StoryPage page) {
    return _bookService.hasInteractiveObjects(page);
  }

  int getInteractiveObjectsCount(StoryPage page) {
    return _bookService.getInteractiveObjectsCount(page);
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