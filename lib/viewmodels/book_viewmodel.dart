import 'package:flutter/material.dart';
// Pastikan path import model ini mengarah ke file yang memuat BookSummaryModel dari Langkah 1
import '../models/book_model_bundle.dart';
import '../services/book_service.dart';
import '../services/local_storage_service.dart';

class BookViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();
  final LocalStorageService _storageService = LocalStorageService();

  List<BookSummaryModel> _books = [];
  bool _isLoading = false;
  String? _error;

  Map<String, String> bookStates = {};
  Map<String, double> downloadProgress = {};

  List<BookSummaryModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookViewModel() {
    loadDashboardCatalog();
  }

  Future<void> loadDashboardCatalog() async {
    debugPrint('[BookViewModel] Starting loadDashboardCatalog...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[BookViewModel] Fetching local bundled catalog...');
      List<BookSummaryModel> localBooks = await _bookService.fetchLocalBundledCatalog();
      _books = List.from(localBooks);
      debugPrint('[BookViewModel] Local books loaded: ${_books.length}');

      debugPrint('[BookViewModel] Fetching downloaded books from storage...');
      List<BookSummaryModel> downloadedBooks = await _bookService.fetchDownloadedBooksMetadata();
      for (var downloadedBook in downloadedBooks) {
        if (!_books.any((b) => b.idBuku == downloadedBook.idBuku)) {
          _books.add(downloadedBook);
        }
      }
      debugPrint('[BookViewModel] Total books after including downloaded: ${_books.length}');

      notifyListeners();

      try {
        debugPrint('[BookViewModel] Fetching network book catalog...');
        List<BookSummaryModel> networkBooks = await _bookService.fetchNetworkBookCatalog();
        debugPrint('[BookViewModel] Network books received: ${networkBooks.length}');
        
        final excludedTitles = {
          "dongeng janiti",
          "sakeclak cihujan hayang ka sagara",
          "setetes air hujan ingin ke samudra"
        };

        for (var netBook in networkBooks) {
          String netTitleId = netBook.judulBukuIndonesia.toLowerCase().trim();
          String netTitleSu = netBook.judulBukuSunda.toLowerCase().trim();

          if (excludedTitles.contains(netTitleId) || excludedTitles.contains(netTitleSu)) {
            debugPrint("[BookViewModel] Skipping bundled book from network: ${netBook.judulBukuIndonesia}");
            continue;
          }

          bool alreadyExists = _books.any((b) {
            String bTitleId = b.judulBukuIndonesia.toLowerCase().trim();
            String bTitleSu = b.judulBukuSunda.toLowerCase().trim();
            return bTitleId == netTitleId || bTitleSu == netTitleSu;
          });

          if (!alreadyExists) {
            debugPrint("[BookViewModel] Adding new network book: ${netBook.judulBukuIndonesia} (ID: ${netBook.idBuku})");
            _books.add(netBook);
          } else {
            debugPrint("[BookViewModel] Skipping duplicate title from network: ${netBook.judulBukuIndonesia}");
          }
        }
      } catch (networkError) {
        debugPrint("[BookViewModel] API CMS gagal atau offline: $networkError");
      }

      debugPrint('[BookViewModel] Resolving download states for ${_books.length} books...');
      for (var book in _books) {
        if (book.judulBukuIndonesia == "Setetes Air Hujan Ingin ke Samudra" || book.judulBukuIndonesia == "Dongeng Janiti") {
          bookStates[book.idBuku] = "READY";
        } else {
          bool isDownloaded = await _storageService.isBookDownloaded(book.idBuku);
          bookStates[book.idBuku] = isDownloaded ? "READY" : "NOT_DOWNLOADED";
          debugPrint('[BookViewModel] Book ${book.judulBukuIndonesia} (ID: ${book.idBuku}) state: ${bookStates[book.idBuku]}');
        }
      }
    } catch (e) {
      debugPrint('[BookViewModel] FATAL ERROR in loadDashboardCatalog: $e');
      _error = 'Kegagalan sistem fatal saat memuat katalog: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[BookViewModel] loadDashboardCatalog finished.');
    }
  }

  Future<bool> triggerDownloadBook(String bookId, int version, BuildContext context) async {
    if (bookStates[bookId] == "DOWNLOADING") return false;

    bookStates[bookId] = "DOWNLOADING";
    notifyListeners();

    try {
      await _bookService.downloadAndExtractBookArchive(bookId);
      await _storageService.saveBookDownloadStatus(bookId, version);
      
      bookStates[bookId] = "READY";
      
      debugPrint("Download success for book: $bookId");
      notifyListeners();
      return true;
    } catch (e) {
      bookStates[bookId] = "NOT_DOWNLOADED";
      _error = 'Gagal mengunduh buku: $e';
      debugPrint("Download failed: $e");
      notifyListeners();
      return false;
    }
  }

  BookSummaryModel? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.idBuku == id);
    } catch (e) {
      return null;
    }
  }

  BookSummaryModel? findLocalCounterpart(BookSummaryModel netBook) {
    try {
      return _books.firstWhere((b) =>
        b.judulBukuIndonesia.toLowerCase().trim() == netBook.judulBukuIndonesia.toLowerCase().trim()
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshBooks() async {
    await loadDashboardCatalog();
  }
}