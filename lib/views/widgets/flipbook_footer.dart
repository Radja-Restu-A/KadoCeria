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
  final bool isFlipping;
  final Function(bool)? onFlippingStateChanged;

  const FlipbookFooter({
    super.key,
    required this.bookId,
    required this.bookPrimaryColor,
    required this.bookSecondaryColor,
    required this.viewModel,
    required this.controller,
    required this.isFlipping,
    required this.onFlippingStateChanged,
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
          
          final VoidCallback? onPressed = (isFlipping || playingOnePage) 
              ? null 
              : (isPlaying
                  ? () => viewModel.stopFullBookAudio()
                  : () => viewModel.playFullBookAudio(bookId));

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null
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
                    : TeksProvider.getString('fullbook', languageProvider.selectedLanguage),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          );
        }
    );
  }

  Widget _buildPageAudioButton(BuildContext context) {
    if (viewModel.isOnCompletionPage) {
      return Consumer2<FlipbookViewModel, LanguageProvider>(
          builder: (context, flipbookViewModel, languageProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ElevatedButton(
                onPressed: isFlipping ? null :() {
                  viewModel.stopAudio();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFlipping ? Colors.grey.withValues(alpha: 0.5) : bookSecondaryColor,
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

    if (viewModel.isOnSenaraiKataPage) {
      return const SizedBox.shrink();
    }

    return Consumer2<FlipbookViewModel, LanguageProvider>(
        builder: (context, viewModel, languageProvider, child) {
          final bool isPlayingPageAudio = viewModel.isPlayingPageAudio;
          final bool isPlayingFullBook = viewModel.isPlayingFullBook;
          
          final VoidCallback? onPressed = (isFlipping || isPlayingFullBook)
              ? null
              : (isPlayingPageAudio
                  ? () => viewModel.stopAudio()
                  : () => viewModel.playPageAudio(bookId));

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: onPressed == null
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
  }

  Widget _buildNavigationRow(BuildContext context) {
    const double buttonHeight = 56;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              height: buttonHeight,
              child: _buildPageAudioButton(context),
            ),
          ),

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
                      viewModel.isPlayingPageAudio ||
                      isFlipping)
                      ? null
                      : () async {
                    onFlippingStateChanged?.call(true);
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
                      viewModel.isPlayingPageAudio ||
                      isFlipping)
                      ? null
                      : () async {
                    onFlippingStateChanged?.call(true);
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
}