import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import '../core/assets_loader.dart';
import '../models/story_model.dart';
import 'package:just_audio/just_audio.dart';

// Constants
class FlipbookConstants {
  static const double headerPadding = 13.0;
  static const double controlPadding = 16.0;
  static const double borderRadius = 25.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 32.0;

  static const Color primaryColor = Color(0xFF4FC3F7);
  static const Color secondaryColor = Color(0xFF29B6F6);
  static const Color backgroundColor = Colors.white;

  static const String defaultLanguage = 'indonesia';
  static const int interactiveAreaOffset = 150;
  static const int tapFeedbackDuration = 200;
  static const int audioDelay = 500;
}

// Opsi bahasa
enum Language {
  indonesia('indonesia', 'Bahasa Indonesia'),
  sunda('sunda', 'Bahasa Sunda'),
  keduanya('keduanya', 'Kedua Bahasa');

  const Language(this.code, this.displayName);
  final String code;
  final String displayName;
}

class FlipbookScreen extends StatefulWidget {
  final String storyId;

  const FlipbookScreen({super.key, required this.storyId});

  @override
  State<FlipbookScreen> createState() => _FlipbookScreenState();
}

// Objek utama
class _FlipbookScreenState extends State<FlipbookScreen> {
  late Future<Story> _storyFuture;
  final _controller = GlobalKey<PageFlipWidgetState>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentPage = 0;
  Language _selectedLanguage = Language.indonesia;

  @override
  void initState() {
    super.initState();
    _storyFuture = AssetsLoader.loadStory(widget.storyId);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Audio Management
  Future<void> _playPageAudio() async {
    final pageNum = _currentPage + 1;
    final basePath = 'assets/${widget.storyId}';

    try {
      await _audioPlayer.stop();
      await _playAudioByLanguage(basePath, pageNum);
    } catch (e) {
      _handleAudioError('Gagal memutar audio: $e');
    }
  }

  Future<void> _playAudioByLanguage(String basePath, int pageNum) async {
    switch (_selectedLanguage) {
      case Language.indonesia:
        await _playAudio('$basePath/page${pageNum}_narasi_indonesia.mp3');
        break;
      case Language.sunda:
        await _playAudio('$basePath/page${pageNum}_narasi_sunda.mp3');
        break;
      case Language.keduanya:
        await _playBothLanguages(basePath, pageNum);
        break;
    }
  }

  Future<void> _playAudio(String path) async {
    await _audioPlayer.setAsset(path);
    await _audioPlayer.play();
  }

  Future<void> _playBothLanguages(String basePath, int pageNum) async {
    final indonesiaPath = '$basePath/page${pageNum}_narasi_indonesia.mp3';
    final sundaPath = '$basePath/page${pageNum}_narasi_sunda.mp3';

    await _playAudio(indonesiaPath);

    _audioPlayer.playerStateStream
        .where((state) => state.processingState == ProcessingState.completed)
        .first
        .then((_) async {
      if (_selectedLanguage == Language.keduanya) {
        await _playAudio(sundaPath);
      }
    });
  }

  Future<void> _playFullBookAudio() async {
    // TODO: Implement full book audio playbook
    debugPrint('Playing full book audio in ${_selectedLanguage.displayName}');
  }

  void _handleAudioError(String error) {
    debugPrint(error);
    // TODO: Show user-friendly error message
  }

  // Navigation
  void _goToPreviousPage() {
    _audioPlayer.stop();
    _controller.currentState?.previousPage();
    setState(() {
      if (_currentPage > 0) _currentPage--;
    });
  }

  void _goToNextPage() {
    _audioPlayer.stop();
    _controller.currentState?.nextPage();
    setState(() {
      _currentPage++;
    });
  }

  // Page rendering
  List<Widget> _buildPages(Story story) {
    return story.pages.map((page) => _buildPage(page)).toList();
  }

  Widget _buildPage(StoryPage page) {
    return Container(
      color: FlipbookConstants.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageLayout = _calculatePageLayout(page, constraints);

          return Stack(
            children: [
              _buildPageImage(page),
              _buildInteractiveArea(page, pageLayout),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageImage(StoryPage page) {
    return Center(
      child: Image.asset(
        'assets/${widget.storyId}/${page.image}',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildInteractiveArea(StoryPage page, PageLayout layout) {
    return Positioned(
      left: layout.interactiveLeft,
      top: layout.interactiveTop - FlipbookConstants.interactiveAreaOffset + 150,
      width: layout.interactiveWidth,
      height: layout.interactiveHeight,
      child: KidsInteractiveArea(
        storyId: widget.storyId,
        audioFile: page.audioObject,
        audioPlayer: _audioPlayer,
      ),
    );
  }

  PageLayout _calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    final imageRatio = page.widthImage / page.heightImage;
    final screenRatio = constraints.maxWidth / constraints.maxHeight;

    double renderedWidth, renderedHeight;
    double imageOffsetX = 0, imageOffsetY = 0;

    if (screenRatio > imageRatio) {
      renderedHeight = constraints.maxHeight;
      renderedWidth = renderedHeight * imageRatio;
      imageOffsetX = (constraints.maxWidth - renderedWidth) / 2;
    } else {
      renderedWidth = constraints.maxWidth;
      renderedHeight = renderedWidth / imageRatio;
      imageOffsetY = (constraints.maxHeight - renderedHeight) / 2;
    }

    final scaleX = renderedWidth / page.widthImage;
    final scaleY = renderedHeight / page.heightImage;

    return PageLayout(
      interactiveLeft: (page.x * scaleX) + imageOffsetX,
      interactiveTop: (page.y * scaleY) + imageOffsetY,
      interactiveWidth: page.width * scaleX,
      interactiveHeight: page.height * scaleY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Story>(
        future: _storyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final story = snapshot.data!;
          return SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildMainContent(story),
                _buildBottomControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(FlipbookConstants.headerPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FlipbookConstants.primaryColor, FlipbookConstants.secondaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 8),
          _buildLanguageSelector(),
          const SizedBox(width: 8),
          _buildProfileButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _buildLanguageSelector() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(FlipbookConstants.borderRadius),
        ),
        height: 48,
        child: DropdownButton<Language>(
          value: _selectedLanguage,
          underline: Container(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FlipbookConstants.primaryColor),
          isExpanded: true,
          onChanged: (Language? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
              });
            }
          },
          style: const TextStyle(
            color: FlipbookConstants.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          items: Language.values.map((Language language) {
            return DropdownMenuItem<Language>(
              value: language,
              child: Text(language.displayName),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    return IconButton(
      onPressed: () {
        // TODO: Implement settings
      },
      icon: Image.asset('assets/${widget.storyId}/hadelogo.png'),
    );
  }

  Widget _buildMainContent(Story story) {
    return Expanded(
      child: Container(
        color: FlipbookConstants.backgroundColor,
        child: PageFlipWidget(
          key: _controller,
          backgroundColor: FlipbookConstants.backgroundColor,
          children: _buildPages(story),
          lastPage: _buildLastPage(),
        ),
      ),
    );
  }

  Widget _buildLastPage() {
    return Container(
      color: FlipbookConstants.backgroundColor,
      child: const Center(
        child: Text(
          'Selesai membaca!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(FlipbookConstants.controlPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FlipbookConstants.primaryColor, FlipbookConstants.secondaryColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFullBookButton(),
          const SizedBox(height: 12),
          _buildNavigationRow(),
        ],
      ),
    );
  }

  Widget _buildFullBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _playFullBookAudio,
        style: _getButtonStyle(),
        child: const Text(
          'Dengarkan Seluruh Buku',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNavigationRow() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none, // Memungkinkan overflow
        children: [
          // Audio button di tengah
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: _buildPageAudioButton(),
            ),
          ),

          // Previous button
          Positioned(
            left: -40,
            top: 0,
            bottom: 0,
            child: _buildNavigationButton(
              Icons.arrow_back_ios_new,
              _goToPreviousPage,
              isLeft: true,
            ),
          ),

          // Next button
          Positioned(
            right: -40,
            top: 0,
            bottom: 0,
            child: _buildNavigationButton(
              Icons.arrow_forward_ios,
              _goToNextPage,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

// Button navigation yang menembus tepi layar seperti pada gambar
  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed, {required bool isLeft}) {
    return Container(
      width: 100, // Lebar button
      height: 48, // Tinggi sama dengan audio button
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25), // Border radius penuh
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                // Offset icon sedikit ke arah dalam layar
                left: isLeft ? 8 : 0,
                right: isLeft ? 0 : 8,
              ),
              child: Icon(
                icon,
                color: FlipbookConstants.primaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageAudioButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: _playPageAudio,
        style: _getButtonStyle(),
        child: const Text(
          'Dengarkan Halaman Ini',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withOpacity(0.9),
      foregroundColor: FlipbookConstants.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FlipbookConstants.borderRadius),
      ),
    );
  }
}

// Data classes
class PageLayout {
  final double interactiveLeft;
  final double interactiveTop;
  final double interactiveWidth;
  final double interactiveHeight;

  PageLayout({
    required this.interactiveLeft,
    required this.interactiveTop,
    required this.interactiveWidth,
    required this.interactiveHeight,
  });
}

// Interactive area widget
class KidsInteractiveArea extends StatefulWidget {
  final String storyId;
  final String audioFile;
  final AudioPlayer audioPlayer;

  const KidsInteractiveArea({
    super.key,
    required this.storyId,
    required this.audioFile,
    required this.audioPlayer,
  });

  @override
  State<KidsInteractiveArea> createState() => _KidsInteractiveAreaState();
}

class _KidsInteractiveAreaState extends State<KidsInteractiveArea>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _tapController;

  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _tapScaleAnimation;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _tapController = AnimationController(
      duration: const Duration(milliseconds: FlipbookConstants.tapFeedbackDuration),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _colorAnimation = _createRainbowAnimation();

    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.elasticOut),
    );
  }

  Animation<Color?> _createRainbowAnimation() {
    return TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.red, end: Colors.orange),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.orange, end: Colors.yellow),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.yellow, end: Colors.green),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.green, end: Colors.blue),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.blue, end: Colors.purple),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.purple, end: Colors.red),
        weight: 1.0,
      ),
    ]).animate(_colorController);
  }

  void _startAnimations() {
    _scaleController.repeat(reverse: true);
    _colorController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);

    try {
      await _playTapAnimation();
      await _playAudio();
      await _addDelay();
    } catch (e) {
      debugPrint('Gagal memutar audio objek: $e');
    } finally {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playTapAnimation() async {
    await _tapController.forward();
    await _tapController.reverse();
  }

  Future<void> _playAudio() async {
    await widget.audioPlayer.stop();
    await widget.audioPlayer.setAsset('assets/${widget.storyId}/${widget.audioFile}');
    await widget.audioPlayer.play();
  }

  Future<void> _addDelay() async {
    await Future.delayed(const Duration(milliseconds: FlipbookConstants.audioDelay));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _colorController,
        _tapController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _tapScaleAnimation.value,
          child: Stack(
            children: [
              _buildGlowEffect(),
              _buildInteractiveContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (_colorAnimation.value ?? Colors.blue).withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveContent() {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
        ),
        child: Stack(
          children: [
            _buildMarkerImage(),
            if (_isPlaying) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerImage() {
    return Image.asset(
      'assets/${widget.storyId}/penanda.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackMarker();
      },
    );
  }

  Widget _buildFallbackMarker() {
    return Container(
      color: Colors.blue.withOpacity(0.3),
      child: const Center(
        child: Icon(
          Icons.touch_app,
          color: Colors.white,
          size: FlipbookConstants.iconSize,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}