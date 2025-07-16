class AppConfig {
  static const String appName = 'Flipbook App';
  static const String appVersion = '1.0.0';

  // Audio settings
  static const double defaultVolume = 1.0;
  static const bool enableAudioAutoplay = false;
  static const int audioFadeInDuration = 500;
  static const int audioFadeOutDuration = 300;

  // Animation settings
  static const int defaultAnimationDuration = 300;
  static const int interactiveAnimationDuration = 1000;
  static const int pageTransitionDuration = 500;

  // UI settings
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 4.0;
  static const double defaultPadding = 16.0;

  // Story settings
  static const int maxPagesPerStory = 50;
  static const int maxInteractiveAreasPerPage = 10;

  // Performance settings
  static const bool enableImageCaching = true;
  static const bool enableAudioCaching = true;
  static const int maxCacheSize = 100; // MB

  // Debug settings
  static const bool enableDebugMode = false;
  static const bool enablePerformanceOverlay = false;
  static const bool enableLogging = true;
}