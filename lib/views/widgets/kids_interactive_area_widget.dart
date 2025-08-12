import 'package:flutter/material.dart';

class KidsInteractiveArea extends StatefulWidget {
  final String storyId;
  final String audioFile;
  final bool isPlaying;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color secondaryColor;

  const KidsInteractiveArea({
    super.key,
    required this.storyId,
    required this.audioFile,
    required this.isPlaying,
    required this.onTap,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<KidsInteractiveArea> createState() => _KidsInteractiveAreaState();
}

class _KidsInteractiveAreaState extends State<KidsInteractiveArea>
    with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _pulseController;
  late Animation<double> _tapScaleAnimation;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Tap animation
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.elasticOut),
    );

    // Continuous scale animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation: 1.0 -> 0.5 -> 1.0
    _pulseScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Opacity animation: 1.0 -> 0.2 -> 1.0
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Color animation
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: widget.primaryColor,
          end: widget.secondaryColor,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: widget.secondaryColor,
          end: widget.primaryColor,
        ),
        weight: 1,
      ),
    ]).animate(_pulseController);
  }

  void _startAnimations() {
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _tapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isPlaying) {
      print('Audio is already playing, ignoring tap');
      return;
    }

    await _tapController.forward();
    await _tapController.reverse();

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_tapController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _tapScaleAnimation.value * _pulseScaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: _handleTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _colorAnimation.value ?? widget.primaryColor,
                    width: 3.0,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isPlaying
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    key: ValueKey<bool>(widget.isPlaying),
                    color: _colorAnimation.value ?? widget.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}