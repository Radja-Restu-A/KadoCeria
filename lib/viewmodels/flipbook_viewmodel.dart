import 'package:flutter/material.dart';

class FlipbookViewModel extends ChangeNotifier {
  final String bookId;
  late PageController _pageController;
  int _currentPage = 0;
  int _totalPages = 0;

  FlipbookViewModel(this.bookId) {
    _pageController = PageController();
  }

  PageController get pageController => _pageController;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  bool get canGoPrevious => _currentPage > 0;
  bool get canGoNext => _currentPage < _totalPages - 1;

  void setTotalPages(int total) {
    _totalPages = total;
    notifyListeners();
  }

  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (canGoNext) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (canGoPrevious) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pageController.animateToPage(
        page,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}