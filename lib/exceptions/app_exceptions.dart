class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class StoryLoadException extends AppException {
  StoryLoadException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AudioPlayException extends AppException {
  AudioPlayException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AssetNotFoundException extends AppException {
  AssetNotFoundException(String assetPath)
      : super('Asset not found: $assetPath', code: 'ASSET_NOT_FOUND');
}

class InvalidStoryDataException extends AppException {
  InvalidStoryDataException(String message)
      : super('Invalid story data: $message', code: 'INVALID_STORY_DATA');
}