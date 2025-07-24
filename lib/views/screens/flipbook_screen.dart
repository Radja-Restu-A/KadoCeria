import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:page_flip/page_flip.dart';
import '../../viewmodels/flipbook_viewmodel.dart';
import '../../models/book_model.dart';
import '../widgets/kids_interactive_area.dart';
import '../../core/constants.dart';

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
    _viewModel = FlipbookViewModel();

    // Add listener untuk menunggu story dimuat
    _viewModel.addListener(_onStoryLoaded);
    _viewModel.loadStory(widget.bookId);

    // Set auto-navigation callback
    _viewModel.setAutoNavigationCallback(() {
      if (_controller.currentState != null) {
        _controller.currentState!.nextPage();
      }
    });
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
      // Gunakan gambar dari page pertama story
      final firstPageImage = _viewModel.story!.pages.first.image;

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
    _viewModel.dispose();
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

              if (viewModel.error != null) {
                return _buildErrorWidget(viewModel.error!);
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _viewModel.loadStory(widget.bookId),
            child: const Text('Retry'),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () {
        _toggleLanguageDropdown();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.bookSecondaryColor,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                viewModel.selectedLanguage.displayName,
                style: const TextStyle(
                  color: Colors.white,
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
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageDropdownOverlay(FlipbookViewModel viewModel, double headerHeight) {
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
                      language.displayName,
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
      color: FlipbookConstants.backgroundColor,
      child: PageFlipWidget(
        key: _controller,
        backgroundColor: FlipbookConstants.backgroundColor,
        children: _buildPages(viewModel),
        lastPage: _buildLastPage(),
        onPageFlipped: (index) {
          // Update viewModel current page when flip animation completes
          _viewModel.setCurrentPage(index);
        },
      ),
    );
  }

  List<Widget> _buildPages(FlipbookViewModel viewModel) {
    return viewModel.story!.pages.map((page) => _buildPage(page, viewModel)).toList();
  }

  Widget _buildPage(StoryPage page, FlipbookViewModel viewModel) {
    return Container(
      color: FlipbookConstants.backgroundColor,
      child: ClipRect( // ← Tambahkan ClipRect di sini
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageLayout = viewModel.calculatePageLayout(page, constraints);

            return Stack(
              children: [
                _buildPageImage(page),
                _buildInteractiveArea(page, pageLayout, viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageImage(StoryPage page) {
    return Positioned.fill(
      child: Image.asset(
        page.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildInteractiveArea(StoryPage page, PageLayout layout, FlipbookViewModel viewModel) {
    return Positioned(
      left: layout.interactiveLeft,
      top: layout.interactiveTop - FlipbookConstants.interactiveAreaOffset + 150,
      width: layout.interactiveWidth,
      height: layout.interactiveHeight,
      child: KidsInteractiveArea(
        storyId: widget.bookId,
        audioFile: page.audioObject,
        isPlaying: viewModel.isPlayingObjectAudio,
        onTap: () => viewModel.playObjectAudio(widget.bookId, page.audioObject),
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

  Widget _buildBottomControls(FlipbookViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.bookPrimaryColor,
      ),
      child: Column(
        children: [
          // Row 1 - Full Book Button (30% of footer height)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFullBookButton(viewModel),
            ),
          ),

          // Row 2 - Navigation Controls (70% of footer height)
          Expanded(
            flex: 5,
            child: _buildNavigationRow(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBookButton(FlipbookViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isPlayingFullBook
            ? () => viewModel.stopFullBookAudio()
            : () => viewModel.playFullBookAudio(widget.bookId),
        style: _getButtonStyleAudioFull(),
        child: Text(
          viewModel.isPlayingFullBook ? 'Hentikan' : 'Dengarkan Seluruh Buku',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildNavigationRow(FlipbookViewModel viewModel) {
    const double buttonHeight = 56; // Consistent height for all buttons

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Audio button di tengah
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              height: buttonHeight, // Fixed height
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
                height: buttonHeight, // Same height as audio button
                child: _buildNavigationButton(
                  Icons.arrow_back_ios_new,
                  (viewModel.isFirstPage || viewModel.isPlayingFullBook || viewModel.isNavigating)
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
                height: buttonHeight, // Same height as audio button
                child: _buildNavigationButton(
                  Icons.arrow_forward_ios,
                  (viewModel.isLastPage || viewModel.isPlayingFullBook || viewModel.isNavigating)
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
    // Hide audio button on last page (completion page)
    if (viewModel.currentPage >= viewModel.story!.pages.length) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity, // Will be constrained by parent SizedBox
      child: ElevatedButton(
        onPressed: (viewModel.isPlayingPageAudio || viewModel.isPlayingFullBook)
            ? () => viewModel.stopFullBookAudio()
            : () => viewModel.playPageAudio(widget.bookId),
        style: _getButtonStyleAudio(),
        child: Text(
          viewModel.isPlayingPageAudio ? 'Hentikan' : 'Dengarkan Halaman Ini',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  ButtonStyle _getButtonStyleAudioFull() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.bookSecondaryColor,
      foregroundColor: FlipbookConstants.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(36),
      ),
    );
  }

  ButtonStyle _getButtonStyleAudio() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.bookSecondaryColor,
      foregroundColor: FlipbookConstants.primaryColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28), // Matched with navigation buttons
      ),
    );
  }
}