import '../models/book_model_bundle.dart';
import '../services/book_service.dart';

class StoryRepository {
  // Load all available books
  Future<List<BookModelBundle>> getAllBooks() async {
    try {
      return await BookService.loadBooks();
    } catch (e) {
      throw Exception('Failed to load books: $e');
    }
  }

  // Load book by ID
  Future<BookModelBundle?> getBookById(String bookId) async {
    try {
      return await BookService.loadBookById(bookId);
    } catch (e) {
      throw Exception('Failed to load book with id $bookId: $e');
    }
  }

  // Load book by ID (with exception if not found)
  Future<BookModelBundle> getStory(String storyId) async {
    try {
      final BookModelBundle? book = await BookService.loadBookById(storyId);
      if (book == null) {
        throw Exception('Book with id $storyId not found');
      }
      return book;
    } catch (e) {
      throw Exception('Failed to load story: $e');
    }
  }
}