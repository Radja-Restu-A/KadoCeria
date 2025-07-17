import '../models/book_model.dart';
import '../services/book_service.dart';

class StoryRepository {
  // Memuat semua buku/cerita yang tersedia
  Future<List<BookModel>> getAllBooks() async {
    try {
      return await BookService.loadBooks();
    } catch (e) {
      throw Exception('Failed to load books: $e');
    }
  }

  // Memuat buku/cerita berdasarkan ID
  Future<BookModel?> getBookById(String bookId) async {
    try {
      return await BookService.loadBookById(bookId);
    } catch (e) {
      throw Exception('Failed to load book with id $bookId: $e');
    }
  }

  // Memuat buku/cerita berdasarkan ID (dengan exception jika tidak ditemukan)
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

  // Mendapatkan daftar ID cerita yang tersedia
  Future<List<String>> getAvailableStories() async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.map((book) => book.id).toList();
    } catch (e) {
      throw Exception('Failed to get available stories: $e');
    }
  }

  // Mendapatkan daftar judul cerita yang tersedia
  Future<List<String>> getAvailableStoryTitles() async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.map((book) => book.title).toList();
    } catch (e) {
      throw Exception('Failed to get available story titles: $e');
    }
  }

  // Mencari buku berdasarkan judul
  Future<List<BookModel>> searchBooksByTitle(String title) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.where((book) =>
          book.title.toLowerCase().contains(title.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Failed to search books by title: $e');
    }
  }

  // Mencari buku berdasarkan author
  Future<List<BookModel>> searchBooksByAuthor(String author) async {
    try {
      final List<BookModel> books = await BookService.loadBooks();
      return books.where((book) =>
          book.author.toLowerCase().contains(author.toLowerCase())
      ).toList();
    } catch (e) {
      throw Exception('Failed to search books by author: $e');
    }
  }

  // Mendapatkan buku berdasarkan warna primer
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
}