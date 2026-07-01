import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _downloadedKey = 'downloaded_books_ids';
  static const String _versionKeyPrefix = 'book_version_';
  Future<void> saveBookDownloadStatus(String bookId, int version) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedIds = prefs.getStringList(_downloadedKey) ?? [];
    if (!downloadedIds.contains(bookId)) {
      downloadedIds.add(bookId);
      await prefs.setStringList(_downloadedKey, downloadedIds);
    }
    await prefs.setInt('$_versionKeyPrefix$bookId', version);
  }
  Future<bool> isBookDownloaded(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedIds = prefs.getStringList(_downloadedKey) ?? [];
    return downloadedIds.contains(bookId);
  }
  Future<void> removeBookStatus(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedIds = prefs.getStringList(_downloadedKey) ?? [];
    downloadedIds.remove(bookId);
    await prefs.setStringList(_downloadedKey, downloadedIds);
    await prefs.remove('$_versionKeyPrefix$bookId');
  }
}