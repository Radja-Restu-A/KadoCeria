import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:page_flip/page_flip.dart';
import '../../viewmodels/flipbook_viewmodel.dart';
import '../../models/book_model.dart';
import '../widgets/flipbook_audio_error_modal.dart';
import '../widgets/flipbook_addtional_pages.dart';
import '../widgets/flipbook_header.dart';
import '../widgets/flipbook_content.dart';
import '../widgets/flipbook_footer.dart';

class FlipbookScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final Color bookPrimaryColor;
  final Color bookSecondaryColor;

  const FlipbookScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookPrimaryColor,
    required this.bookSecondaryColor
  });

  @override
  State<FlipbookScreen> createState() => _FlipbookScreenState();
}

class _FlipbookScreenState extends State<FlipbookScreen> {
  late FlipbookViewModel _viewModel;
  final _controller = GlobalKey<PageFlipWidgetState>();
  bool _isLanguageDropdownOpen = false;
  final ScrollController _senaraiKataScrollController = ScrollController();
  late FlipbookAdditionalPages _additionalPages;

  @override
  void initState() {
    super.initState();

    // Initialize view model
    _viewModel = FlipbookViewModel();
    _viewModel.stopAudio();

    // Set callbacks
    _viewModel.setAutoNavigationCallback(_handleAutoNavigation);
    _viewModel.setAudioErrorCallback(_showAudioErrorModal);
    _viewModel.setStoryLoadedCallback(_onStoryLoaded);

    // Load story
    _viewModel.loadStory(widget.bookId);
  }

  void _initializeAdditionalPages() {
    // Get the senarai kata from viewModel using the bookId
    final kataDataSenarai = _viewModel.getSenaraiKata(widget.bookId);

    _additionalPages = FlipbookAdditionalPages(
      primaryColor: widget.bookPrimaryColor,
      secondaryColor: widget.bookSecondaryColor,
      senaraiKataScrollController: _senaraiKataScrollController,
      kataDataSenarai: kataDataSenarai,
    );
  }

  void _handleAutoNavigation() {
    if (_controller.currentState != null) {
      _controller.currentState!.nextPage();
    }
  }

  void _showAudioErrorModal(AudioErrorType errorType, String errorMessage) {
    if (!mounted) return;

    AudioErrorModal.show(
      context,
      errorType: errorType,
      errorMessage: errorMessage,
      bookId: widget.bookId,
      primaryColor: widget.bookPrimaryColor,
      viewModel: _viewModel,
    );
  }

  void _onStoryLoaded() {
    if (mounted) {
      // Initialize additional pages after story is loaded
      _initializeAdditionalPages();

      setState(() {
        // Force rebuild to show the content
      });
    }
  }

  @override
  void dispose() {
    _viewModel.stopAudio();
    _senaraiKataScrollController.dispose();
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

  void _handlePageFlipped(int index) {
    // Stop audio saat page flip manual HANYA jika bukan full book mode
    if (!_viewModel.isPlayingFullBook &&
        (_viewModel.isPlayingPageAudio || _viewModel.isPlayingObjectAudio)) {
      _viewModel.stopAudio();
    }
    _viewModel.setCurrentPage(index);
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
              // Show loading while story is loading or layout is being calculated
              if (!viewModel.isReadyForDisplay) {
                return Container(
                  color: widget.bookPrimaryColor,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }

              if (viewModel.story == null) {
                return Container(
                  color: widget.bookPrimaryColor,
                  child: const Center(
                    child: Text(
                      'No story loaded',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
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
        // Use the extracted calculation logic from viewModel
        final layout = viewModel.calculateResponsiveLayout(constraints);

        return Stack(
          children: [
            Column(
              children: [
                // AREA HEADER - Using extracted widget
                SizedBox(
                  width: double.infinity,
                  height: layout.headerHeight,
                  child: FlipbookHeader(
                    bookPrimaryColor: widget.bookPrimaryColor,
                    bookSecondaryColor: widget.bookSecondaryColor,
                    viewModel: viewModel,
                    isLanguageDropdownOpen: _isLanguageDropdownOpen,
                    onLanguageDropdownToggle: _toggleLanguageDropdown,
                    onLanguageSelect: _selectLanguage,
                  ),
                ),

                // AREA CONTENT - Using extracted widget
                SizedBox(
                  width: double.infinity,
                  height: layout.contentHeight,
                  child: FlipbookContent(
                    bookId: widget.bookId,
                    bookPrimaryColor: widget.bookPrimaryColor,
                    bookSecondaryColor: widget.bookSecondaryColor,
                    viewModel: viewModel,
                    controller: _controller,
                    additionalPages: _additionalPages,
                    onPageFlipped: _handlePageFlipped,
                  ),
                ),

                // AREA FOOTER - Now using the extracted widget
                SizedBox(
                  width: double.infinity,
                  height: layout.footerHeight,
                  child: FlipbookFooter(
                    bookId: widget.bookId,
                    bookPrimaryColor: widget.bookPrimaryColor,
                    bookSecondaryColor: widget.bookSecondaryColor,
                    viewModel: viewModel,
                    controller: _controller,
                  ),
                ),
              ],
            ),

            // Language dropdown overlay
            if (_isLanguageDropdownOpen)
              FlipbookLanguageDropdown(
                bookPrimaryColor: widget.bookPrimaryColor,
                headerHeight: layout.headerHeight,
                onLanguageSelect: _selectLanguage,
              ),
          ],
        );
      },
    );
  }
}