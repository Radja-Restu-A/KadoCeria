extension StringExtensions on String {
bool get isValidAssetPath {
  return startsWith('assets/') && isNotEmpty;
}

String get assetPath {
  return startsWith('assets/') ? this : 'assets/$this';
}

String removeAssetPrefix() {
  return startsWith('assets/') ? substring(7) : this;
}

bool get isAudioFile {
  return toLowerCase().endsWith('.mp3') ||
      toLowerCase().endsWith('.wav') ||
      toLowerCase().endsWith('.m4a');
}

bool get isImageFile {
  return toLowerCase().endsWith('.png') ||
      toLowerCase().endsWith('.jpg') ||
      toLowerCase().endsWith('.jpeg') ||
      toLowerCase().endsWith('.gif');
}
}