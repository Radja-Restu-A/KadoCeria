import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_model.dart';

class BookService {
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