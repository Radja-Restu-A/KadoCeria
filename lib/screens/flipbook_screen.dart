import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import '../core/assets_loader.dart';
import '../models/story_model.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math' show cos, sin;

class FlipbookScreen extends StatefulWidget {
  final String storyId;

  const FlipbookScreen({super.key, required this.storyId});

  @override
  State<FlipbookScreen> createState() => _FlipbookScreenState();
}

class _FlipbookScreenState extends State<FlipbookScreen> {
  late Future<Story> _storyFuture;
  final _controller = GlobalKey<PageFlipWidgetState>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentPage = 0;
  String _selectedLanguage = 'indonesia'; // Default language

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _storyFuture = AssetsLoader.loadStory(widget.storyId);
  }

  Future<void> _playPageAudio() async {
    final int pageNum = _currentPage + 1;
    final String basePath = 'assets/${widget.storyId}';

    try {
      await _audioPlayer.stop();

      if (_selectedLanguage == 'indonesia') {
        final path = '$basePath/page${pageNum}_narasi_indonesia.mp3';
        await _audioPlayer.setAsset(path);
        await _audioPlayer.play();
      } else if (_selectedLanguage == 'sunda') {
        final path = '$basePath/page${pageNum}_narasi_sunda.mp3';
        await _audioPlayer.setAsset(path);
        await _audioPlayer.play();
      } else if (_selectedLanguage == 'keduanya') {
        final pathIndo = '$basePath/page${pageNum}_narasi_indonesia.mp3';
        final pathSunda = '$basePath/page${pageNum}_narasi_sunda.mp3';

        await _audioPlayer.setAsset(pathIndo);
        await _audioPlayer.play();

        _audioPlayer.playerStateStream.firstWhere(
              (state) => state.processingState == ProcessingState.completed,
        ).then((_) async {
          if (_selectedLanguage == 'keduanya') {
            await _audioPlayer.setAsset(pathSunda);
            await _audioPlayer.play();
          }
        });
      }
    } catch (e) {
      print('Gagal memutar audio: $e');
    }
  }

  Future<void> _playFullBookAudio() async {
    // TODO: Implement full book audio playback
    // This function should iterate through all pages and play audio based on selected language
    print('Playing full book audio in $_selectedLanguage');
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
          final screenSize = MediaQuery.of(context).size;

          final pages = story.pages.map((page) {
            final imageRatio = page.widthImage / page.heightImage;
            final screenRatio = screenSize.width / screenSize.height;

            double renderedWidth, renderedHeight;
            double imageOffsetX = 0, imageOffsetY = 0;

            // Hitung ukuran gambar yang sudah di-render dan offset-nya
            if (screenRatio > imageRatio) {
              // Gambar akan fit berdasarkan height, ada space di kiri-kanan
              renderedHeight = screenSize.height;
              renderedWidth = renderedHeight * imageRatio;
              imageOffsetX = (screenSize.width - renderedWidth) / 2;
              imageOffsetY = 0;
            } else {
              // Gambar akan fit berdasarkan width, ada space di atas-bawah
              renderedWidth = screenSize.width;
              renderedHeight = renderedWidth / imageRatio;
              imageOffsetX = 0;
              imageOffsetY = (screenSize.height - renderedHeight) / 2;
            }

            // Hitung skala dari ukuran asli ke ukuran yang di-render
            final scaleX = renderedWidth / page.widthImage;
            final scaleY = renderedHeight / page.heightImage;

            // Hitung posisi area interaktif relatif terhadap gambar yang sudah di-render
            final interactiveLeft = (page.x * scaleX) + imageOffsetX;
            final interactiveTop = (page.y * scaleY) + imageOffsetY;
            final interactiveWidth = page.width * scaleX;
            final interactiveHeight = page.height * scaleY;

            return Container(
              color: Colors.white,
              child: Stack(
                children: [
                  // Gambar background
                  Center(
                    child: Image.asset(
                      'assets/${widget.storyId}/${page.image}',
                      fit: BoxFit.contain,
                      width: screenSize.width,
                      height: screenSize.height,
                    ),
                  ),
                  // Area interaktif dengan animasi untuk anak-anak
                  Positioned(
                    left: interactiveLeft,
                    top: interactiveTop - 150,
                    width: interactiveWidth,
                    height: interactiveHeight,
                    child: _KidsInteractiveArea(
                      storyId: widget.storyId,
                      audioFile: page.audioObject,
                      audioPlayer: _audioPlayer,
                    ),
                  ),
                ],
              ),
            );
          }).toList();

          return SafeArea(
            child: Column(
              children: [
                // Header dengan dropdown bahasa
                Container(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      // Language dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4FC3F7)),
                            isExpanded: true,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLanguage = newValue!;
                              });
                            },
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'indonesia',
                                child: Text('Bahasa Indonesia'),
                              ),
                              DropdownMenuItem(
                                value: 'sunda',
                                child: Text('Bahasa Sunda'),
                              ),
                              DropdownMenuItem(
                                value: 'keduanya',
                                child: Text('Kedua Bahasa'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Settings/Profile button
                      IconButton(
                        onPressed: () {
                          // TODO: Implement settings
                        },
                        icon: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Main content area
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: PageFlipWidget(
                      key: _controller,
                      backgroundColor: Colors.white,
                      children: pages,
                      lastPage: Container(
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            'Selesai membaca!',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom control panel dengan SafeArea untuk menghindari system UI
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Full book audio button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _playFullBookAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: const Color(0xFF4FC3F7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Dengarkan Seluruh Buku',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bottom navigation row
                      Row(
                        children: [
                          // Previous button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _audioPlayer.stop();
                                _controller.currentState?.previousPage();
                                setState(() {
                                  if (_currentPage > 0) _currentPage--;
                                });
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFF4FC3F7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Current page audio button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _playPageAudio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: const Color(0xFF4FC3F7),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'Dengarkan Halaman Ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Next button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                _audioPlayer.stop();
                                _controller.currentState?.nextPage();
                                setState(() {
                                  _currentPage++;
                                });
                              },
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF4FC3F7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget area interaktif khusus untuk anak-anak
class _KidsInteractiveArea extends StatefulWidget {
  final String storyId;
  final String audioFile;
  final dynamic audioPlayer;

  const _KidsInteractiveArea({
    required this.storyId,
    required this.audioFile,
    required this.audioPlayer,
  });

  @override
  _KidsInteractiveAreaState createState() => _KidsInteractiveAreaState();
}

class _KidsInteractiveAreaState extends State<_KidsInteractiveArea>
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

    // Animasi scale (membesar-mengecil)
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Animasi perubahan warna (rainbow effect)
    _colorController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _colorAnimation = TweenSequence<Color?>([
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

    // Animasi tap feedback
    _tapController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _tapScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.elasticOut,
    ));

    // Mulai animasi
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

    // Animasi tap feedback
    await _tapController.forward();
    await _tapController.reverse();

    // Putar audio
    try {
      await widget.audioPlayer.stop();
      await widget.audioPlayer.setAsset('assets/${widget.storyId}/${widget.audioFile}');
      await widget.audioPlayer.play();
    } catch (e) {
      print('Gagal memutar audio objek: $e');
    }

    // Delay sebelum bisa di-tap lagi
    await Future.delayed(Duration(milliseconds: 500));
    setState(() => _isPlaying = false);
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
              // Glow effect dengan warna rainbow
              Container(
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
              ),

              // Main interactive area
              GestureDetector(
                onTap: _handleTap,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.transparent
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gambar penanda
                      Image.asset(
                        'assets/${widget.storyId}/penanda.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue.withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),

                      // Loading indicator saat audio diputar
                      if (_isPlaying)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}