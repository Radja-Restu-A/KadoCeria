import 'package:flutter/material.dart';
import 'package:kado_ceria/provider/teks_provider.dart';
import 'package:provider/provider.dart';
import 'package:page_flip/page_flip.dart';
import '../../provider/language_provider.dart';
import '../../viewmodels/flipbook_viewmodel.dart';
import '../../models/book_model.dart';
import '../widgets/kids_interactive_area_widget.dart';

class FlipbookScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final Color bookPrimaryColor;
  final Color bookSecondaryColor;

  const FlipbookScreen({super.key, required this.bookId, required this.bookTitle, required this.bookPrimaryColor, required this.bookSecondaryColor});

  @override
  State<FlipbookScreen> createState() => _FlipbookScreenState();
}

class _FlipbookScreenState extends State<FlipbookScreen> {
  late FlipbookViewModel _viewModel;
  final _controller = GlobalKey<PageFlipWidgetState>();
  bool _isLanguageDropdownOpen = false;
  double? imageAspectRatio;

  @override
  void initState() {
    super.initState();

    // Reset view model state
    _viewModel = FlipbookViewModel();
    _viewModel.stopAudio();

    // ✅ PERBAIKAN: Set callback untuk auto-navigation
    _viewModel.setAutoNavigationCallback(() {
      _controller.currentState?.nextPage();
    });

    // ✅ TAMBAHAN: Set callback untuk audio error
    _viewModel.setAudioErrorCallback((errorType, errorMessage) {
      _showAudioErrorModal(errorType, errorMessage);
    });

    // Setup listeners
    _viewModel.addListener(_onStoryLoaded);
    _viewModel.loadStory(widget.bookId);
  }

  void _showAudioErrorModal(AudioErrorType errorType, String errorMessage) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 350,
                  minHeight: 250,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.bookPrimaryColor,
                      widget.bookPrimaryColor.withValues(alpha :0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha :0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: widget.bookPrimaryColor.withValues(alpha :0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Animated icon dengan background circle
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha :0.2),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha :0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.volume_off_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Title dengan shadow effect
                          Text(
                            'Ups, Ada Gangguan Audio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha :0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Content area
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha :0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha :0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        TeksProvider.getString('audioError', languageProvider.selectedLanguage),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions dengan styling menarik
                    Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildModalActions(errorType, languageProvider),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildModalActions(AudioErrorType errorType, LanguageProvider languageProvider) {
    switch (errorType) {
      case AudioErrorType.pageAudio:
        return [
          _buildActionButton(
            text: TeksProvider.getString('ok', languageProvider.selectedLanguage),
            icon: null,
            isOutlined: false,
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.clearError();
            },
          ),
        ];

      case AudioErrorType.fullBookAudio:
        return [
          _buildActionButton(
            text: TeksProvider.getString('stop', languageProvider.selectedLanguage),
            icon: Icons.stop_circle_rounded,
            isOutlined: true,
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.stopFullBookAudio();
              _viewModel.clearError();
            },
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            text: TeksProvider.getString('continue', languageProvider.selectedLanguage),
            icon: Icons.skip_next_rounded,
            isOutlined: false,
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.continueFullBookFromNextPage(widget.bookId);
              _viewModel.clearError();
            },
          ),
        ];
    }
  }

  Widget _buildActionButton({
    required String text,
    required IconData? icon,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 48,
        child: isOutlined
            ? (icon != null
            ? OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha :0.7), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )
            : OutlinedButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha :0.7), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ))
            : (icon != null
            ? ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: widget.bookPrimaryColor,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha :0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )
            : ElevatedButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: widget.bookPrimaryColor,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha :0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )),
      ),
    );
  }

  void _onStoryLoaded() {
    // Ketika story sudah dimuat dan ada pages, hitung aspect ratio
    if (_viewModel.story != null &&
        _viewModel.story!.pages.isNotEmpty &&
        imageAspectRatio == null) {
      _getImageAspectRatio();
    }
  }

  Future<void> _getImageAspectRatio() async {
    try {
      // Gunakan gambar dari page pertama story dengan null check
      final firstPage = _viewModel.story?.pages.first;
      final firstPageImage = firstPage?.image;

      // Pastikan image tidak null dan tidak kosong
      if (firstPageImage == null || firstPageImage.isEmpty) {
        // Set fallback aspect ratio jika image null
        if (mounted) {
          setState(() {
            imageAspectRatio = 4 / 3;
          });
        }
        return;
      }

      final ImageStream stream = AssetImage(firstPageImage).resolve(ImageConfiguration.empty);
      stream.addListener(ImageStreamListener((ImageInfo info, bool synchronousCall) {
        final double ratio = info.image.width / info.image.height;
        if (mounted) {
          setState(() {
            imageAspectRatio = ratio;
          });
        }
      }));
    } catch (e) {
      // Fallback aspect ratio jika gambar tidak dapat dimuat
      if (mounted) {
        setState(() {
          imageAspectRatio = 4 / 3;
        });
      }
    }
  }

  @override
  void dispose() {
    // Pastikan _viewModel tidak null
    // Hentikan audio jika sedang diputar
    _viewModel.stopAudio();

    // Hapus listener jika sebelumnya ditambahkan
    _viewModel.removeListener(_onStoryLoaded);

    // Hapus callback navigasi otomatis
    _viewModel.setAutoNavigationCallback(() {});

    // Panggil dispose() milik superclass
    super.dispose();
  }

  void _toggleLanguageDropdown() {
    setState(() {
      _isLanguageDropdownOpen = !_isLanguageDropdownOpen;
    });
  }

  void _closeLanguageDropdown() {
    if (_isLanguageDropdownOpen) {
      setState(() {
        _isLanguageDropdownOpen = false;
      });
    }
  }

  void _selectLanguage(Language language) {
    _viewModel.changeLanguage(language);
    _closeLanguageDropdown();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        body: GestureDetector(
          onTap: _closeLanguageDropdown,
          child: Consumer<FlipbookViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading || imageAspectRatio == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (viewModel.story == null) {
                return const Center(child: Text('No story loaded'));
              }

              return Container(
                color: widget.bookPrimaryColor,
                child: SafeArea(
                  child: _buildResponsiveLayout(viewModel),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(FlipbookViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Hitung tinggi content berdasarkan lebar dan aspect ratio
        final contentHeight = availableWidth / imageAspectRatio!;

        // Pastikan content tidak melebihi 70% dari tinggi layar
        final maxContentHeight = availableHeight * 0.7;
        final finalContentHeight = contentHeight > maxContentHeight
            ? maxContentHeight
            : contentHeight;

        // Hitung sisa tinggi untuk header dan footer
        final remainingHeight = availableHeight - finalContentHeight;
        final headerHeight = remainingHeight * 0.3;
        final footerHeight = remainingHeight * 0.7;

        return Stack(
          children: [
            Column(
              children: [
                // AREA HEADER
                SizedBox(
                  width: double.infinity,
                  height: headerHeight,
                  child: _buildHeader(viewModel),
                ),

                // AREA CONTENT
                SizedBox(
                  width: double.infinity,
                  height: finalContentHeight,
                  child: _buildMainContent(viewModel),
                ),

                // AREA FOOTER
                SizedBox(
                  width: double.infinity,
                  height: footerHeight,
                  child: _buildBottomControls(viewModel),
                ),
              ],
            ),

            // Language dropdown overlay
            if (_isLanguageDropdownOpen)
              _buildLanguageDropdownOverlay(viewModel, headerHeight),
          ],
        );
      },
    );
  }

  Widget _buildHeader(FlipbookViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.bookPrimaryColor,
      ),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 12),
          Expanded(child: _buildLanguageSelector(viewModel)),
          const SizedBox(width: 12),
          _buildProfileButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLanguageSelector(FlipbookViewModel viewModel) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        // ✅ TAMBAHAN: Check apakah audio sedang diputar
        final bool isAudioPlaying = viewModel.isPlayingPageAudio || viewModel.isPlayingFullBook;

        return GestureDetector(
          onTap: isAudioPlaying ? null : () {  // ✅ DISABLE tap jika audio sedang diputar
            _toggleLanguageDropdown();
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAudioPlaying
                  ? widget.bookSecondaryColor.withValues(alpha: 0.5)  // ✅ Ubah opacity jika disabled
                  : widget.bookSecondaryColor,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    viewModel.selectedLanguage.getDisplayName(languageProvider.selectedLanguage),
                    style: TextStyle(
                      color: isAudioPlaying
                          ? Colors.white.withValues(alpha :0.5)  // ✅ Ubah opacity text jika disabled
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isLanguageDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isAudioPlaying
                      ? Colors.white.withValues(alpha :0.5)  // ✅ Ubah opacity icon jika disabled
                      : Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageDropdownOverlay(FlipbookViewModel viewModel, double headerHeight) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Positioned(
          top: headerHeight,
          left: 0,
          right: 0,
          child: Material(
            elevation: 8,
            child: Container(
              decoration: BoxDecoration(
                color: widget.bookPrimaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: Language.values.map((language) {
                  bool isFirst = language == Language.values.first;
                  bool isLast = language == Language.values.last;

                  return GestureDetector(
                    onTap: () => _selectLanguage(language),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: widget.bookPrimaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                          topRight: isFirst ? const Radius.circular(12) : Radius.zero,
                          bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          language.getDisplayName(languageProvider.selectedLanguage),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileButton() {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: IconButton(
        onPressed: () {
          // TODO: Implement settings
        },
        icon: Image.asset(
          'assets/logo/hade.png',
          width: 50,
          height: 50,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMainContent(FlipbookViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          // PageFlipWidget tetap sama seperti aslinya
          PageFlipWidget(
            key: _controller,
            backgroundColor: Colors.white,
            children: _buildPages(viewModel),
            lastPage: _buildLastPage(),
            onPageFlipped: (index) {
              // ✅ PERBAIKAN: Stop audio saat page flip manual HANYA jika bukan full book mode
              if (!viewModel.isPlayingFullBook &&
                  (viewModel.isPlayingPageAudio || viewModel.isPlayingObjectAudio)) {
                viewModel.stopAudio();
              }

              // Update viewModel current page when flip animation completes
              _viewModel.setCurrentPage(index);
            },
          ),

          // ✅ TAMBAHAN: Overlay untuk memblokir gesture saat full book audio diputar
          if (viewModel.isPlayingFullBook)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPages(FlipbookViewModel viewModel) {
    return viewModel.story!.pages.map((page) => _buildPage(page, viewModel)).toList();
  }

  Widget _buildPage(StoryPage page, FlipbookViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Gunakan calculateInteractiveObjectsLayout untuk multiple objects
            final pageLayouts = viewModel.calculateInteractiveObjectsLayout(page, constraints);

            return Stack(
              children: [
                _buildPageImage(page),
                // Gunakan _buildInteractiveAreas yang sudah Anda buat
                ..._buildInteractiveAreas(page, pageLayouts, viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageImage(StoryPage page) {
    // Handle null image dengan fallback
    final imagePath = page.image;

    if (imagePath == null || imagePath.isEmpty) {
      // Tampilkan placeholder jika image null
      return Positioned.fill(
        child: Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Handle error loading image
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildInteractiveAreas(StoryPage page, List<PageLayout> layouts, FlipbookViewModel viewModel) {
    List<Widget> interactiveWidgets = [];

    // Cek apakah page memiliki data yang valid untuk interactive areas
    final hasValidImageDimensions = page.widthImage != null &&
        page.heightImage != null &&
        page.widthImage! > 0 &&
        page.heightImage! > 0;

    if (!hasValidImageDimensions) {
      return interactiveWidgets; // Return empty list
    }

    // Loop through all interactive objects and their corresponding layouts
    for (int i = 0; i < page.interactiveObjects.length && i < layouts.length; i++) {
      final obj = page.interactiveObjects[i];
      final layout = layouts[i];

      // Cek apakah object memiliki data yang valid
      final hasValidObjectDimensions = obj.x != null &&
          obj.y != null &&
          obj.width != null &&
          obj.height != null &&
          obj.width! > 0 &&
          obj.height! > 0;

      if (!hasValidObjectDimensions) {
        continue; // Skip object ini jika tidak valid
      }

      // Cek apakah audioObject ada dan tidak null
      final audioObject = obj.audioObject;
      if (audioObject == null || audioObject.isEmpty) {
        continue; // Skip object ini jika tidak ada audio
      }

      // Create interactive widget untuk object ini
      interactiveWidgets.add(
        Positioned(
          left: layout.interactiveLeft,
          top: layout.interactiveTop,
          width: layout.interactiveWidth,
          height: layout.interactiveHeight,
          child: KidsInteractiveArea(
            key: Key('interactive_${i}_$audioObject'), // Unique key for each object
            storyId: widget.bookId,
            audioFile: audioObject,
            isPlaying: viewModel.isPlayingObjectAudio && viewModel.currentPlayingObjectAudio == audioObject,
            onTap: () => viewModel.playObjectAudio(widget.bookId, audioObject),
            primaryColor: widget.bookPrimaryColor,
            secondaryColor: widget.bookPrimaryColor,
          ),
        ),
      );
    }

    return interactiveWidgets;
  }

  Widget _buildLastPage() {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final imageSize = (availableHeight * 0.6).clamp(200.0, 400.0);

          return Stack(
            children: [
              // Background decorative elements
              _buildBackgroundDecorations(constraints),

              // Main content - Logo only
              Center(
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.bookPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.bookPrimaryColor.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/logo/badanbahasa.jpg',
                        width: imageSize - 16,
                        height: imageSize - 16,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              size: imageSize * 0.3,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundDecorations(BoxConstraints constraints) {
    return Stack(
      children: [
        // Decorative circles in corners
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bookPrimaryColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bookSecondaryColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          top: constraints.maxHeight * 0.3,
          left: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bookPrimaryColor.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: constraints.maxHeight * 0.6,
          right: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bookSecondaryColor.withValues(alpha: 0.05),
            ),
          ),
        ),

        // Subtle pattern dots
        ...List.generate(20, (index) {
          return Positioned(
            top: (constraints.maxHeight * (index * 0.15) % 1),
            left: (constraints.maxWidth * (index * 0.23) % 1),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.bookPrimaryColor.withValues(alpha: 0.1),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomControls(FlipbookViewModel viewModel) {
    // Check if we're on the last page (completion page)
    final bool isOnLastPage = viewModel.story != null &&
        viewModel.currentPage >= viewModel.story!.pages.length;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.bookPrimaryColor,
      ),
      child: Column(
        children: [
          // Row 1 - Full Book Button or Empty Space (30% of footer height)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: isOnLastPage
                  ? const SizedBox.shrink() // Hide full book button on last page
                  : _buildFullBookButton(viewModel),
            ),
          ),

          // Row 2 - Navigation Controls (70% of footer height)
          Expanded(
            flex: 5,
            child: _buildNavigationRow(viewModel), // Always show navigation row
          ),
        ],
      ),
    );
  }

  Widget _buildFullBookButton(FlipbookViewModel viewModel) {
    return Consumer2<FlipbookViewModel, LanguageProvider>(
        builder: (context, flipbookViewModel, languageProvider, child) {
          final bool isPlaying = viewModel.isPlayingFullBook;
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: isPlaying
                  ? () => viewModel.stopFullBookAudio()
                  : () => viewModel.playFullBookAudio(widget.bookId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying
                    ? Colors.grey.withValues(alpha: 0.5)
                    : widget.bookSecondaryColor,
                foregroundColor: Color(0xFF4FC3F7),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
              child: Text(
                isPlaying
                    ? TeksProvider.getString('stop', languageProvider.selectedLanguage)
                    : TeksProvider.getString('fullbook', languageProvider.selectedLanguage),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          );
        }
    );
  }

  Widget _buildNavigationRow(FlipbookViewModel viewModel) {
    const double buttonHeight = 56;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Audio button in center
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              height: buttonHeight,
              child: _buildPageAudioButton(viewModel),
            ),
          ),

          // Previous button
          Positioned(
            left: -45,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                height: buttonHeight,
                child: _buildNavigationButton(
                  Icons.arrow_back_ios_new,
                  // Disable when first page, full book playing, navigating, or page audio playing
                  (viewModel.isFirstPage ||
                      viewModel.isPlayingFullBook ||
                      viewModel.isNavigating ||
                      viewModel.isPlayingPageAudio)  // Added this condition
                      ? null
                      : () async {
                    await viewModel.previousPage();
                    _controller.currentState?.previousPage();
                  },
                  isLeft: true,
                ),
              ),
            ),
          ),

          // Next button
          Positioned(
            right: -45,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                height: buttonHeight,
                child: _buildNavigationButton(
                  Icons.arrow_forward_ios,
                  // Disable when last page, full book playing, navigating, or page audio playing
                  (viewModel.isLastPage ||
                      viewModel.isPlayingFullBook ||
                      viewModel.isNavigating ||
                      viewModel.isPlayingPageAudio)  // Added this condition
                      ? null
                      : () async {
                    await viewModel.nextPage();
                    _controller.currentState?.nextPage();
                  },
                  isLeft: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback? onPressed, {required bool isLeft}) {
    return Container(
      width: 100, // Made it square for better proportion
      height: 56,
      decoration: BoxDecoration(
        color: onPressed != null ? widget.bookSecondaryColor : Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28), // Half of width/height for perfect circle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: isLeft ? 8 : 0, // Reduced padding for better centering
                right: isLeft ? 0 : 8,
              ),
              child: Icon(
                icon,
                color: onPressed != null ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageAudioButton(FlipbookViewModel viewModel) {
    // Check if we're on the last page (completion page)
    final bool isOnLastPage = viewModel.story != null &&
        viewModel.currentPage >= viewModel.story!.pages.length;

    // Show completion button on last page
    if (isOnLastPage) {
      return Consumer2<FlipbookViewModel, LanguageProvider>(
          builder: (context, flipbookViewModel, languageProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Stop any playing audio
                  viewModel.stopAudio();
                  // Navigate back to dashboard
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.bookSecondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      TeksProvider.getString('endreading', languageProvider.selectedLanguage),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      );
    }

    return Consumer2<FlipbookViewModel, LanguageProvider>(
        builder: (context, viewModel, languageProvider, child) {
          final bool isPlayingPageAudio = viewModel.isPlayingPageAudio;
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: isPlayingPageAudio
                  ? () => viewModel.stopAudio()
                  : () => viewModel.playPageAudio(widget.bookId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlayingPageAudio
                    ? Colors.grey.withValues(alpha: 0.5)
                    : widget.bookSecondaryColor,
                foregroundColor: Color(0xFF4FC3F7),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                isPlayingPageAudio
                    ? TeksProvider.getString('stop', languageProvider.selectedLanguage)
                    : TeksProvider.getString('onepage', languageProvider.selectedLanguage),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white
                ),
              ),
            ),
          );
        }
    );
  }}