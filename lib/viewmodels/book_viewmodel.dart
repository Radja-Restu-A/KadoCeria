// lib/viewmodels/book_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

class BookViewModel extends ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _error;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookViewModel() {
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _books = await BookService.loadBooks();
    } catch (e) {
      _error = 'Failed to load books: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  BookModel? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshBooks() async {
    await _loadBooks();
  }
}