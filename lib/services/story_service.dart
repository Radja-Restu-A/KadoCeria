import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class StoryService {
  static BookModel? _cachedBook;

  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    final imageRatio = page.widthImage / page.heightImage;
    final screenRatio = constraints.maxWidth / constraints.maxHeight;

    double renderedWidth, renderedHeight;
    double imageOffsetX = 0, imageOffsetY = 0;

    if (screenRatio > imageRatio) {
      renderedHeight = constraints.maxHeight;
      renderedWidth = renderedHeight * imageRatio;
      imageOffsetX = (constraints.maxWidth - renderedWidth) / 2;
    } else {
      renderedWidth = constraints.maxWidth;
      renderedHeight = renderedWidth / imageRatio;
      imageOffsetY = (constraints.maxHeight - renderedHeight) / 2;
    }

    final scaleX = renderedWidth / page.widthImage;
    final scaleY = renderedHeight / page.heightImage;

    return PageLayout(
      interactiveLeft: (page.x * scaleX) + imageOffsetX,
      interactiveTop: (page.y * scaleY) + imageOffsetY,
      interactiveWidth: page.width * scaleX,
      interactiveHeight: page.height * scaleY,
    );
  }

  // Fixed: Make this method async and await the folder name
  Future<List<String>> generateAudioPaths(String storyId, int pageNumber, Language language) async {
    final folderName = await _getFolderNameById(storyId);
    final basePath = 'assets/$folderName';

    switch (language) {
      case Language.indonesia:
        return ['$basePath/page${pageNumber}_narasi_indonesia.mp3'];
      case Language.sunda:
        return ['$basePath/page${pageNumber}_narasi_sunda.mp3'];
      case Language.keduanya:
        return [
          '$basePath/page${pageNumber}_narasi_indonesia.mp3',
          '$basePath/page${pageNumber}_narasi_sunda.mp3',
        ];
    }
  }

  Future<String> _getFolderNameById(String storyId) async {
    // Implementasi untuk mendapatkan folderName dari metadata berdasarkan ID
    if (_cachedBook != null && _cachedBook!.id == storyId) {
      return _cachedBook!.folderName;
    }

    // Ambil data dari BookService
    final book = await BookService.loadBookById(storyId);
    if (book != null) {
      _cachedBook = book; // Simpan ke cache
      return book.folderName;
    }

    // Fallback jika tidak ditemukan
    throw Exception('Book with ID $storyId not found');
  }

  Future<String> generateObjectAudioPath(String storyId, String audioFile) async {
    final folderName = await _getFolderNameById(storyId);
    return 'assets/$folderName/$audioFile';
  }

  Future<String> generateImagePath(String storyId, String imageName) async {
    final folderName = await _getFolderNameById(storyId);
    return 'assets/$folderName/$imageName';
  }

  bool isFirstPage(int currentPage) {
    return currentPage == 0;
  }

  bool isLastPage(int currentPage, int totalPages) {
    return currentPage >= totalPages - 1;
  }
}