import 'package:flutter/material.dart';

class FlipbookConstants {
  // Padding & Spacing
  static const double headerPadding = 13.0;
  static const double controlPadding = 16.0;
  static const double borderRadius = 25.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 32.0;

  // Colors
  static const Color primaryColor = Color(0xFF4FC3F7);
  static const Color secondaryColor = Color(0xFF29B6F6);
  static const Color backgroundColor = Colors.white;

  // Settings
  static const String defaultLanguage = 'indonesia';
  static const int interactiveAreaOffset = 150;
  static const int tapFeedbackDuration = 200;
  static const int audioDelay = 500;

  // Animation durations
  static const int scaleAnimationDuration = 1000;
  static const int colorAnimationDuration = 2000;
  static const int tapAnimationDuration = 200;

  // Audio settings
  static const double audioVolume = 1.0;
  static const bool enableAudioFeedback = true;
}