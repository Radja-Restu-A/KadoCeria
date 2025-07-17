import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _currentStoryId;
  List<String> _availableStories = [];
  bool _isInitialized = false;
  String? _lastError;

  // Getters
  String? get currentStoryId => _currentStoryId;
  List<String> get availableStories => List.unmodifiable(_availableStories);
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  // Setters
  void setCurrentStory(String storyId) {
    if (_currentStoryId != storyId) {
      _currentStoryId = storyId;
      notifyListeners();
    }
  }

  void setAvailableStories(List<String> stories) {
    _availableStories = stories;
    notifyListeners();
  }

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  void setError(String? error) {
    _lastError = error;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // Methods
  bool hasStory(String storyId) {
    return _availableStories.contains(storyId);
  }

  void reset() {
    _currentStoryId = null;
    _availableStories.clear();
    _isInitialized = false;
    _lastError = null;
    notifyListeners();
  }
}