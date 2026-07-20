import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import '../../viewmodels/flipbook_viewmodel.dart';
import '../../models/book_model_bundle.dart';
import '../widgets/kids_interactive_area_widget.dart';
import '../widgets/flipbook_addtional_pages.dart';
import 'dart:io';

class FlipbookContent extends StatelessWidget {
  final String bookId;
  final Color bookPrimaryColor;
  final Color bookSecondaryColor;
  final FlipbookViewModel viewModel;
  final GlobalKey<PageFlipWidgetState> controller;
  final FlipbookAdditionalPages additionalPages;
  final Function(int) onPageFlipped;
  final bool isFlipping;

  const FlipbookContent({
    super.key,
    required this.bookId,
    required this.bookPrimaryColor,
    required this.bookSecondaryColor,
    required this.viewModel,
    required this.controller,
    required this.additionalPages,
    required this.onPageFlipped,
    required this.isFlipping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          PageFlipWidget(
            key: controller,
            backgroundColor: Colors.white,
            lastPage: _buildLastPage(),
            onPageFlipped: onPageFlipped,
            children: _buildPages(),
          ),

          // Overlay untuk memblokir gesture saat full book audio diputar
          if (viewModel.isPlayingFullBook || isFlipping)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    List<Widget> pages = viewModel.story!.pages.map((page) => _buildPage(page)).toList();
    pages.add(additionalPages.buildSenaraiKataPage());
    return pages;
  }

  Widget _buildPage(StoryPage page) {
    return Container(
      color: Colors.white,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageLayouts = viewModel.calculateInteractiveObjectsLayout(page, constraints);

            return Stack(
              children: [
                _buildPageImage(page),
                ..._buildInteractiveAreas(page, pageLayouts),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageImage(StoryPage page) {
    final imagePath = page.image;

    if (imagePath == null || imagePath.isEmpty) {
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

    final bool isBundled = viewModel.story!.isBundled;
    final String? localDir = viewModel.story!.localDirectoryPath;

    if (isBundled) {
      return Positioned.fill(
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
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
    } else {
      final String fullLocalImagePath = '$localDir/$imagePath';

      return Positioned.fill(
        child: Image.file(
          File(fullLocalImagePath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
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
  }

  List<Widget> _buildInteractiveAreas(StoryPage page, List<PageLayout> layouts) {
    List<Widget> interactiveWidgets = [];

    final hasValidImageDimensions = page.widthImage != null &&
        page.heightImage != null &&
        page.widthImage! > 0 &&
        page.heightImage! > 0;

    if (!hasValidImageDimensions) {
      return interactiveWidgets;
    }

    for (int i = 0; i < page.interactiveObjects.length && i < layouts.length; i++) {
      final obj = page.interactiveObjects[i];
      final layout = layouts[i];

      final hasValidObjectDimensions = obj.x != null &&
          obj.y != null &&
          obj.width != null &&
          obj.height != null &&
          obj.width! > 0 &&
          obj.height! > 0;

      if (!hasValidObjectDimensions) {
        continue;
      }

      final audioObject = obj.audioObjectSd ?? obj.audioObjectId;

      final bool isBundled = viewModel.story!.isBundled;
      final String? localDir = viewModel.story!.localDirectoryPath;

      if (audioObject == null || audioObject.isEmpty) {
        continue;
      }

      interactiveWidgets.add(
        Positioned(
          left: layout.interactiveLeft,
          top: layout.interactiveTop,
          width: layout.interactiveWidth,
          height: layout.interactiveHeight,
          child: KidsInteractiveArea(
            key: Key('interactive_${i}_$audioObject'),
            storyId: bookId,
            audioFile: isBundled ? audioObject : '$localDir/$audioObject',
            isPlaying: viewModel.isPlayingObjectAudio && viewModel.currentPlayingObjectAudio == audioObject,
            onTap: () => viewModel.playObjectAudio(bookId, audioObject),
            primaryColor: bookPrimaryColor,
            secondaryColor: bookSecondaryColor,
          ),
        ),
      );
    }

    return interactiveWidgets;
  }

  Widget _buildLastPage() {
    return additionalPages.buildLastPage();
  }
}