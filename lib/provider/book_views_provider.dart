import 'package:flutter/cupertino.dart';

import '../services/book_views_service.dart';

class BookViewsProvider extends ChangeNotifier {
  BookViewsService service = BookViewsService();
  Map<String, Future<int>> viewsFutures = {};

  Future<void> initViews(String bookId) async {
    try{
      if (!viewsFutures.containsKey(bookId)) {
        viewsFutures[bookId] = service.getBookViews(bookId);
        notifyListeners();
      }
    }catch(e){
      viewsFutures[bookId] = Future.value(0);
      throw Exception('Failed to initialize views for book $bookId: $e');
    }
  }

  Future<int> getViews(String bookId) async {
    try{
      await initViews(bookId);
      return viewsFutures[bookId]!;
    }catch(e){
      throw Exception('Failed to get views for book $bookId: $e');
    }
  }

  Future<void> incrementViews(String bookId) async {
    try{
      await service.incrementBookViews(bookId);
      viewsFutures[bookId] = service.getBookViews(bookId);
      notifyListeners();
    }catch (e){
      throw Exception('Failed to increment views for book $bookId: $e');
    }
  }
}