import 'package:flutter/material.dart';
import 'package:kado_ceria/provider/teks_provider.dart';
import 'package:provider/provider.dart';
import 'package:page_flip/page_flip.dart';
import '../../provider/language_provider.dart';
import '../../viewmodels/flipbook_viewmodel.dart';

class FlipbookFooter extends StatelessWidget {
  final String bookId;
  final Color bookPrimaryColor;
  final Color bookSecondaryColor;
  final FlipbookViewModel viewModel;
  final GlobalKey<PageFlipWidgetState> controller;

  const FlipbookFooter({
    super.key,
    required this.bookId,
    required this.bookPrimaryColor,
    required this.bookSecondaryColor,
    required this.viewModel,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bookPrimaryColor,
      ),
      child: Column(
        children: [
          // Row 1 - Full Book Button or Empty Space (50% of footer height)
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              child: (viewModel.isOnSenaraiKataPage || viewModel.isOnCompletionPage)
                  ? const SizedBox.shrink()
                  : _buildFullBookButton(),
            ),
          ),

          // Row 2 - Navigation Controls (50% of footer height)
          Expanded(
            flex: 5,
            child: _buildNavigationRow(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBookButton() {
    return Consumer2<FlipbookViewModel, LanguageProvider>(
        builder: (context, flipbookViewModel, languageProvider, child) {
          final bool isPlaying = viewModel.isPlayingFullBook;
          final bool playingOnePage = viewModel.isPlayingPageAudio;
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: isPlaying
                  ? () => viewModel.stopFullBookAudio()
                  : () => viewModel.playFullBookAudio(bookId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying || playingOnePage
                    ? Colors.grey.withValues(alpha: 0.5)
                    : bookSecondaryColor,
                foregroundColor: const Color(0xFF4FC3F7),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
              child: Text(
                isPlaying
                    ? TeksProvider.getString('stop', languageProvider.selectedLanguage)
                    : (playingOnePage ? "" : TeksProvider.getString('fullbook', languageProvider.selectedLanguage)),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          );
        }
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
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
              child: _buildPageAudioButton(context),
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
                  (viewModel.isFirstPage ||
                      viewModel.isPlayingFullBook ||
                      viewModel.isNavigating ||
                      viewModel.isPlayingPageAudio)
                      ? null
                      : () async {
                    await viewModel.previousPage();
                    controller.currentState?.previousPage();
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
                  (viewModel.isOnFinalCompletionPage ||
                      viewModel.isPlayingFullBook ||
                      viewModel.isNavigating ||
                      viewModel.isPlayingPageAudio)
                      ? null
                      : () async {
                    await viewModel.nextPage();
                    controller.currentState?.nextPage();
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
      width: 100,
      height: 56,
      decoration: BoxDecoration(
        color: onPressed != null ? bookSecondaryColor : Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
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
                left: isLeft ? 8 : 0,
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

  Widget _buildPageAudioButton(BuildContext context) {
    // Show completion button on final completion page
    if (viewModel.isOnCompletionPage) {
      return Consumer2<FlipbookViewModel, LanguageProvider>(
          builder: (context, flipbookViewModel, languageProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  viewModel.stopAudio();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookSecondaryColor,
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

    // Hide page audio button on Senarai Kata page
    if (viewModel.isOnSenaraiKataPage) {
      return const SizedBox.shrink();
    }

    // Normal page audio button for regular story pages
    return Consumer2<FlipbookViewModel, LanguageProvider>(
        builder: (context, viewModel, languageProvider, child) {
          final bool isPlayingPageAudio = viewModel.isPlayingPageAudio;
          final bool isPlayingFullBook = viewModel.isPlayingFullBook;
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: isPlayingPageAudio
                  ? () => viewModel.stopAudio()
                  : () => viewModel.playPageAudio(bookId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlayingPageAudio || isPlayingFullBook
                    ? Colors.grey.withValues(alpha: 0.5)
                    : bookSecondaryColor,
                foregroundColor: const Color(0xFF4FC3F7),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                isPlayingPageAudio
                    ? TeksProvider.getString('stop', languageProvider.selectedLanguage)
                    : (isPlayingFullBook ? "" : TeksProvider.getString('onepage', languageProvider.selectedLanguage)),
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
  }
}