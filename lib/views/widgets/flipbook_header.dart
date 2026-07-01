import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/language_provider.dart';
import '../../viewmodels/flipbook_viewmodel.dart';
import '../../models/book_model_bundle.dart';

class FlipbookHeader extends StatelessWidget {
  final Color bookPrimaryColor;
  final Color bookSecondaryColor;
  final FlipbookViewModel viewModel;
  final bool isLanguageDropdownOpen;
  final bool isFlipping;
  final VoidCallback onLanguageDropdownToggle;
  final Function(Language) onLanguageSelect;

  const FlipbookHeader({
    super.key,
    required this.bookPrimaryColor,
    required this.bookSecondaryColor,
    required this.viewModel,
    required this.isLanguageDropdownOpen,
    required this.isFlipping,
    required this.onLanguageDropdownToggle,
    required this.onLanguageSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bookPrimaryColor,
      ),
      child: Row(
        children: [
          _buildBackButton(context),
          const SizedBox(width: 12),
          Expanded(child: _buildLanguageSelector()),
          const SizedBox(width: 12),
          _buildProfileButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final bool isAudioPlaying = viewModel.isPlayingPageAudio || viewModel.isPlayingFullBook;
        final bool isDisabled = isAudioPlaying || isFlipping;

        return GestureDetector(
          onTap: isDisabled ? null : onLanguageDropdownToggle,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.withValues(alpha: 0.5)
                  : bookSecondaryColor,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    viewModel.selectedLanguage.getDisplayName(languageProvider.selectedLanguage),
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.white.withValues(alpha: 0.5)
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
                  isLanguageDropdownOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isDisabled
                      ? Colors.white.withValues(alpha: 0.5)
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

  Widget _buildProfileButton() {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: IconButton(
        onPressed: () {
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
}

class FlipbookLanguageDropdown extends StatelessWidget {
  final Color bookPrimaryColor;
  final double headerHeight;
  final Function(Language) onLanguageSelect;

  const FlipbookLanguageDropdown({
    super.key,
    required this.bookPrimaryColor,
    required this.headerHeight,
    required this.onLanguageSelect,
  });

  @override
  Widget build(BuildContext context) {
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
                color: bookPrimaryColor,
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
                    onTap: () => onLanguageSelect(language),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: bookPrimaryColor,
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
}