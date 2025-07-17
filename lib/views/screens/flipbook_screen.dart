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

  const FlipbookScreen({super.key, required this.bookId, required this.bookTitle});

  @override
  State<FlipbookScreen> createState() => _FlipbookScreenState();
}

class _FlipbookScreenState extends State<FlipbookScreen> {
  late FlipbookViewModel _viewModel;
  final _controller = GlobalKey<PageFlipWidgetState>();

  @override
  void initState() {
    super.initState();
    _viewModel = FlipbookViewModel();
    _viewModel.loadStory(widget.bookId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        body: Consumer<FlipbookViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return _buildErrorWidget(viewModel.error!);
            }

            if (viewModel.story == null) {
              return const Center(child: Text('No story loaded'));
            }

            return SafeArea(
              child: Column(
                children: [
                  _buildHeader(viewModel),
                  _buildMainContent(viewModel),
                  _buildBottomControls(viewModel),
                ],
              ),
            );
          },
        ),
      ),
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
          _buildLanguageSelector(viewModel),
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

  Widget _buildLanguageSelector(FlipbookViewModel viewModel) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(FlipbookConstants.borderRadius),
        ),
        height: 48,
        child: DropdownButton<Language>(
          value: viewModel.selectedLanguage,
          underline: Container(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FlipbookConstants.primaryColor),
          isExpanded: true,
          onChanged: (Language? newValue) {
            if (newValue != null) {
              viewModel.changeLanguage(newValue);
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
      icon: Image.asset(
        'assets/logo/hade.png',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(FlipbookViewModel viewModel) {
    return Expanded(
      child: Container(
        color: FlipbookConstants.backgroundColor,
        child: PageFlipWidget(
          key: _controller,
          backgroundColor: FlipbookConstants.backgroundColor,
          children: _buildPages(viewModel),
          lastPage: _buildLastPage(),
        ),
      ),
    );
  }

  List<Widget> _buildPages(FlipbookViewModel viewModel) {
    return viewModel.story!.pages.map((page) => _buildPage(page, viewModel)).toList();
  }

  Widget _buildPage(StoryPage page, FlipbookViewModel viewModel) {
    return Container(
      color: FlipbookConstants.backgroundColor,
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
    );
  }

  Widget _buildPageImage(StoryPage page) {
    return Center(
      child: Image.asset(
        page.image,
        fit: BoxFit.contain,
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
          _buildFullBookButton(viewModel),
          const SizedBox(height: 12),
          _buildNavigationRow(viewModel),
        ],
      ),
    );
  }

  Widget _buildFullBookButton(FlipbookViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isPlayingPageAudio
            ? null
            : () => viewModel.playFullBookAudio(widget.bookId),
        style: _getButtonStyle(),
        child: Text(
          viewModel.isPlayingPageAudio ? 'Memutar...' : 'Dengarkan Seluruh Buku',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNavigationRow(FlipbookViewModel viewModel) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Audio button di tengah
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: _buildPageAudioButton(viewModel),
            ),
          ),

          // Previous button
          Positioned(
            left: -40,
            top: 0,
            bottom: 0,
            child: _buildNavigationButton(
              Icons.arrow_back_ios_new,
              viewModel.isFirstPage ? null : () {
                viewModel.previousPage();
                _controller.currentState?.previousPage();
              },
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
              viewModel.isLastPage ? null : () {
                viewModel.nextPage();
                _controller.currentState?.nextPage();
              },
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback? onPressed, {required bool isLeft}) {
    return Container(
      width: 100,
      height: 48,
      decoration: BoxDecoration(
        color: onPressed != null ? Colors.white.withOpacity(0.9) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
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
                left: isLeft ? 8 : 0,
                right: isLeft ? 0 : 8,
              ),
              child: Icon(
                icon,
                color: onPressed != null ? FlipbookConstants.primaryColor : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageAudioButton(FlipbookViewModel viewModel) {
    return Expanded(
      child: ElevatedButton(
        onPressed: viewModel.isPlayingPageAudio
            ? null
            : () => viewModel.playPageAudio(widget.bookId),
        style: _getButtonStyle(),
        child: Text(
          viewModel.isPlayingPageAudio ? 'Memutar...' : 'Dengarkan Halaman Ini',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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