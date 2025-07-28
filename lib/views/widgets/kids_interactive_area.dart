import 'package:flutter/material.dart';
import '../../core/constants.dart';

class KidsInteractiveArea extends StatefulWidget {
  final String storyId;
  final String audioFile;
  final bool isPlaying;
  final VoidCallback onTap;

  const KidsInteractiveArea({
    super.key,
    required this.storyId,
    required this.audioFile,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  State<KidsInteractiveArea> createState() => _KidsInteractiveAreaState();
}

class _KidsInteractiveAreaState extends State<KidsInteractiveArea>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _tapController;

  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: FlipbookConstants.scaleAnimationDuration),
      vsync: this,
    );

    _colorController = AnimationController(
      duration: const Duration(milliseconds: FlipbookConstants.colorAnimationDuration),
      vsync: this,
    );

    _tapController = AnimationController(
      duration: const Duration(milliseconds: FlipbookConstants.tapFeedbackDuration),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _colorAnimation = _createRainbowAnimation();

    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.elasticOut),
    );
  }

  Animation<Color?> _createRainbowAnimation() {
    return TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.yellow, end: Colors.orange),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.orange, end: Colors.yellow),
        weight: 1.0,
      ),
    ]).animate(_colorController);
  }

  void _startAnimations() {
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
    if (widget.isPlaying) return;

    await _tapController.forward();
    await _tapController.reverse();

    widget.onTap();
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
              _buildGlowEffect(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (_colorAnimation.value ?? Colors.blue).withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}