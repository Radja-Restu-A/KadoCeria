import '../models/book_model.dart';
import '../services/book_service.dart';

class StoryRepository {
  // Load all available books
  Future<List<BookModel>> getAllBooks() async {
    try {
      return await BookService.loadBooks();
    } catch (e) {
      throw Exception('Failed to load books: $e');
    }
  }

  // Load book by ID
  Future<BookModel?> getBookById(String bookId) async {
    try {
      return await BookService.loadBookById(bookId);
    } catch (e) {
      throw Exception('Failed to load book with id $bookId: $e');
    }
  }

  // Load book by ID (with exception if not found)
  Future<BookModel> getStory(String storyId) async {
    try {
      final BookModel? book = await BookService.loadBookById(storyId);
      if (book == null) {
        throw Exception('Book with id $storyId not found');
      }
      return book;
    } catch (e) {
      throw Exception('Failed to load story: $e');
    }
  }

  // Get list of available story IDs
  Future<List<String>> getAvailableStories() async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.map((book) => book.id).toList();
    } catch (e) {
      throw Exception('Failed to get available stories: $e');
    }
  }

  // Get list of available story titles
  Future<List<String>> getAvailableStoryTitles(Language language) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.map((book) => book.getTitle(language)).toList();
    } catch (e) {
      throw Exception('Failed to get available story titles: $e');
    }
  }

  // Search books by title
  Future<List<BookModel>> searchBooksByTitle(String title, Language language) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.where((book) =>
          book.getTitle(language).toLowerCase().contains(title.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Failed to search books by title: $e');
    }
  }


  // Get books by primary color
  Future<List<BookModel>> getBooksByPrimaryColor(String colorHex) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.where((book) =>
      '#${book.primaryColor.value.toRadixString(16).substring(2)}' == colorHex
      ).toList();
    } catch (e) {
      throw Exception('Failed to get books by primary color: $e');
    }
  }

  // Get book descriptions by language
  Future<List<String>> getBookDescriptions(Language language) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.map((book) => book.getDescription(language)).toList();
    } catch (e) {
      throw Exception('Failed to get book descriptions: $e');
    }
  }

}