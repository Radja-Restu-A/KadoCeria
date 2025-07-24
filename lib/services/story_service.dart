import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class StoryService {
  static BookModel? _cachedBook;

  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    // Handle null values dengan default values atau early return
    final pageWidthImage = page.widthImage ?? 1.0; // Prevent division by zero
    final pageHeightImage = page.heightImage ?? 1.0; // Prevent division by zero
    final pageX = page.x ?? 0.0;
    final pageY = page.y ?? 0.0;
    final pageWidth = page.width ?? 0.0;
    final pageHeight = page.height ?? 0.0;

    // Validasi untuk mencegah division by zero
    if (pageWidthImage <= 0 || pageHeightImage <= 0) {
      // Return default layout jika dimensi image tidak valid
      return PageLayout(
        interactiveLeft: 0.0,
        interactiveTop: 0.0,
        interactiveWidth: 0.0,
        interactiveHeight: 0.0,
      );
    }

    // Validasi constraints
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return PageLayout(
        interactiveLeft: 0.0,
        interactiveTop: 0.0,
        interactiveWidth: 0.0,
        interactiveHeight: 0.0,
      );
    }

    final imageRatio = pageWidthImage / pageHeightImage;
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

    // Prevent division by zero untuk scale calculations
    final scaleX = pageWidthImage > 0 ? renderedWidth / pageWidthImage : 1.0;
    final scaleY = pageHeightImage > 0 ? renderedHeight / pageHeightImage : 1.0;

    return PageLayout(
      interactiveLeft: (pageX * scaleX) + imageOffsetX,
      interactiveTop: (pageY * scaleY) + imageOffsetY,
      interactiveWidth: pageWidth * scaleX,
      interactiveHeight: pageHeight * scaleY,
    );
  }

  // Fixed: Make this method async and await the folder name
  Future<List<String>> generateAudioPaths(String storyId, int pageNumber, Language language) async {
    final folderName = await _getFolderNameById(storyId);
    final basePath = 'assets/$folderName';

    switch (language) {
      case Language.indonesia:
        return ['$basePath/audio_narasi_indonesia/page${pageNumber}_narasi_indonesia.mp3'];
      case Language.sunda:
        return ['$basePath/audio_narasi_sunda/page${pageNumber}_narasi_sunda.mp3'];
      case Language.keduanya:
        return [
          '$basePath/audio_narasi_indonesia/page${pageNumber}_narasi_indonesia.mp3',
          '$basePath/audio_narasi_sunda/page${pageNumber}_narasi_sunda.mp3',
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
    return 'assets/$folderName/audio_objek/$audioFile';
  }

  Future<String> generateImagePath(String storyId, String imageName) async {
    final folderName = await _getFolderNameById(storyId);
    return 'assets/$folderName/halaman/$imageName';
  }

  bool isFirstPage(int currentPage) {
    return currentPage == 0;
  }

  bool isLastPage(int currentPage, int totalPages) {
    return currentPage >= totalPages - 1;
  }
}