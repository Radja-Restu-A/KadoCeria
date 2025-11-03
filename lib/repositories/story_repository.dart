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
}