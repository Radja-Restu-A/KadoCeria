import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kado_ceria/provider/teks_provider.dart';
import '../../provider/language_provider.dart';
import '../../viewmodels/flipbook_viewmodel.dart';

class AudioErrorModal extends StatelessWidget {
  final AudioErrorType errorType;
  final String errorMessage;
  final String bookId;
  final Color primaryColor;
  final FlipbookViewModel viewModel;

  const AudioErrorModal({
    super.key,
    required this.errorType,
    required this.errorMessage,
    required this.bookId,
    required this.primaryColor,
    required this.viewModel,
  });

  static void show(
      BuildContext context, {
        required AudioErrorType errorType,
        required String errorMessage,
        required String bookId,
        required Color primaryColor,
        required FlipbookViewModel viewModel,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AudioErrorModal(
          errorType: errorType,
          errorMessage: errorMessage,
          bookId: bookId,
          primaryColor: primaryColor,
          viewModel: viewModel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: _buildModalDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildContent(languageProvider),
                _buildActions(languageProvider, context),
              ],
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildModalDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor,
          primaryColor.withValues(alpha: 0.9),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: 2,
        ),
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.2),
          blurRadius: 40,
          offset: const Offset(0, 0),
          spreadRadius: 10,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAnimatedIcon(),
          const SizedBox(height: 16),
          _buildTitle(),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
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
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.volume_off_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      'Ups, Ada Gangguan Audio',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContent(LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
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
    );
  }

  Widget _buildActions(LanguageProvider languageProvider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _getActionWidgets(languageProvider, context),
      ),
    );
  }

  List<Widget> _getActionWidgets(LanguageProvider languageProvider, BuildContext context) {
    switch (errorType) {
      case AudioErrorType.pageAudio:
        return [
          _ActionButton(
            text: TeksProvider.getString('ok', languageProvider.selectedLanguage),
            icon: null,
            isOutlined: false,
            primaryColor: primaryColor,
            onPressed: () => _handleOkAction(context),
          ),
        ];

      case AudioErrorType.fullBookAudio:
        return [
          _ActionButton(
            text: TeksProvider.getString('stop', languageProvider.selectedLanguage),
            icon: Icons.stop_circle_rounded,
            isOutlined: true,
            primaryColor: primaryColor,
            onPressed: () => _handleStopAction(context),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            text: TeksProvider.getString('continue', languageProvider.selectedLanguage),
            icon: Icons.skip_next_rounded,
            isOutlined: false,
            primaryColor: primaryColor,
            onPressed: () => _handleContinueAction(context),
          ),
        ];
    }
  }

  void _handleOkAction(BuildContext context) {
    Navigator.of(context).pop();
    viewModel.clearError();
  }

  void _handleStopAction(BuildContext context) {
    Navigator.of(context).pop();
    viewModel.stopFullBookAudio();
    viewModel.clearError();
  }

  void _handleContinueAction(BuildContext context) {
    Navigator.of(context).pop();
    viewModel.continueFullBookFromNextPage(bookId);
    viewModel.clearError();
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isOutlined;
  final Color primaryColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.isOutlined,
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: isOutlined ? _buildOutlinedButton() : _buildElevatedButton(),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(text, style: textStyle),
        style: buttonStyle,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(text, style: textStyle),
    );
  }

  Widget _buildElevatedButton() {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(text, style: textStyle),
        style: buttonStyle,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(text, style: textStyle),
    );
  }
}