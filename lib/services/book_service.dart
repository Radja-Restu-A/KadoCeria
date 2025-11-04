import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_model.dart';
import 'package:flutter/material.dart';

class BookService {
  static BookModel? _cachedBook;

  // Updated method to handle multiple interactive objects
  List<PageLayout> calculateInteractiveObjectsLayout(StoryPage page, BoxConstraints constraints) {
    List<PageLayout> layouts = [];

    // Handle null values dengan default values
    final pageWidthImage = page.widthImage ?? 1.0; // Prevent division by zero
    final pageHeightImage = page.heightImage ?? 1.0; // Prevent division by zero

    // Validasi untuk mencegah division by zero
    if (pageWidthImage <= 0 || pageHeightImage <= 0) {
      return layouts; // Return empty list jika dimensi image tidak valid
    }

    // Validasi constraints
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return layouts;
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

    // Calculate layout for each interactive object
    for (InteractiveObject obj in page.interactiveObjects) {
      final objX = obj.x ?? 0.0;
      final objY = obj.y ?? 0.0;
      final objWidth = obj.width ?? 0.0;
      final objHeight = obj.height ?? 0.0;

      layouts.add(PageLayout(
        interactiveLeft: (objX * scaleX) + imageOffsetX,
        interactiveTop: (objY * scaleY) + imageOffsetY,
        interactiveWidth: objWidth * scaleX,
        interactiveHeight: objHeight * scaleY,
      ));
    }

    return layouts;
  }

  // Backward compatibility method - returns layout for first interactive object or default
  PageLayout calculatePageLayout(StoryPage page, BoxConstraints constraints) {
    final layouts = calculateInteractiveObjectsLayout(page, constraints);

    if (layouts.isNotEmpty) {
      return layouts.first;
    }

    return PageLayout(
      interactiveLeft: 0.0,
      interactiveTop: 0.0,
      interactiveWidth: 0.0,
      interactiveHeight: 0.0,
    );
  }

  bool isFirstPage(int currentPage) {
    return currentPage == 0;
  }

  bool isLastPage(int currentPage, int totalPages) {
    return currentPage >= totalPages - 1;
  }

  // Helper method to check if a page has interactive objects
  bool hasInteractiveObjects(StoryPage page) {
    return page.interactiveObjects.isNotEmpty;
  }

  // Helper method to get count of interactive objects in a page
  int getInteractiveObjectsCount(StoryPage page) {
    return page.interactiveObjects.length;
  }

  // Helper method to get specific interactive object by index
  InteractiveObject? getInteractiveObjectAt(StoryPage page, int index) {
    if (index >= 0 && index < page.interactiveObjects.length) {
      return page.interactiveObjects[index];
    }
    return null;
  }

  // Main method for load all book from metadata.json
  static Future<List<BookModel>> loadBooks() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> booksJson = data['books'];

      return booksJson.map((json) => BookModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading books: $e');
      return [];
    }
  }

  // Method for load one book by ID (optional)
  static Future<BookModel?> loadBookById(String id) async {
    try {
      final List<BookModel> books = await loadBooks();
      return books.firstWhere((book) => book.id == id);
    } catch (e) {
      print('Error loading book with id $id: $e');
      return null;
    }
  }

  // Method for load complete metadata (optional)
  static Future<Map<String, dynamic>> loadMetadata() async {
    try {
      final String response = await rootBundle.loadString('assets/metadata.json');
      return json.decode(response);
    } catch (e) {
      print('Error loading metadata: $e');
      return {};
    }
  }
}