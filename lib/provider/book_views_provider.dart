import 'package:flutter/cupertino.dart';

import '../services/book_views_service.dart';

class BookViewsProvider extends ChangeNotifier {
  final BookViewsService service = BookViewsService();
  Map<String, Future<int>> viewsFutures = {};

  Future<void> initViews(String bookId) async {
    if (!viewsFutures.containsKey(bookId)) {
      viewsFutures[bookId] = service.getBookViews(bookId);
      notifyListeners();
    }
  }

  Future<int> getViews(String bookId) async {
    await initViews(bookId);
    return viewsFutures[bookId]!;
  }

  Future<void> incrementViews(String bookId) async {
    await service.incrementBookViews(bookId);
    viewsFutures[bookId] = service.getBookViews(bookId);
    notifyListeners();
  }
}