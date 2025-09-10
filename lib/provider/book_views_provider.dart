import 'package:flutter/cupertino.dart';

import '../services/book_views_service.dart';

class BookViewsProvider extends ChangeNotifier {
  BookViewsService service = BookViewsService();
  Map<String, Future<int>> viewsFutures = {};

  Future<void> initViews(String bookId) async {
    try {
      if (!viewsFutures.containsKey(bookId)) {
        viewsFutures[bookId] = service.getBookViews(bookId);
        notifyListeners();
      }
    } catch (e) {
      print('BookViewsProvider: Failed to initialize views for $bookId: $e');
      viewsFutures[bookId] = Future.value(0);
      notifyListeners();
    }
  }

  Future<int> getViews(String bookId) async {
    try {
      await initViews(bookId);
      return await viewsFutures[bookId]!;
    } catch (e) {
      print('BookViewsProvider: Failed to get views for $bookId: $e');
      return 0;
    }
  }

  Future<void> incrementViews(String bookId) async {
    try {
      await service.incrementBookViews(bookId);

      // Refresh the future to get updated count
      viewsFutures[bookId] = service.getBookViews(bookId);
      notifyListeners();

      print('BookViewsProvider: Successfully incremented views for $bookId');
    } catch (e) {
      print('BookViewsProvider: Failed to increment views for $bookId: $e');
      // Still notify listeners to update UI with local data
      viewsFutures[bookId] = service.getBookViews(bookId);
      notifyListeners();
    }
  }

  // Additional methods for better functionality
  Future<void> forceSyncAll() async {
    try {
      await service.forceSyncAll();

      // Refresh all view futures after sync
      for (final bookId in viewsFutures.keys) {
        viewsFutures[bookId] = service.getBookViews(bookId);
      }

      notifyListeners();
      print('BookViewsProvider: Force sync completed');
    } catch (e) {
      print('BookViewsProvider: Force sync failed: $e');
    }
  }

  Future<bool> hasPendingViews() async {
    try {
      return await service.hasPendingViews();
    } catch (e) {
      print('BookViewsProvider: Error checking pending views: $e');
      return false;
    }
  }

  bool get isOnline => service.isOnline;

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }
}