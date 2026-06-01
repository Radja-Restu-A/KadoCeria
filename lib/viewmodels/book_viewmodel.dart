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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. OFFLINE-FIRST: Muat data lokal sebagai fondasi absolut
      List<BookSummaryModel> localBooks = await _bookService.fetchLocalBundledCatalog();
      _books = List.from(localBooks);

      // Render layar secepat mungkin dengan data lokal (Dongeng Janiti & Sakeclak)
      notifyListeners();

      // 2. NETWORK SYNC: Coba sinkronisasi dengan data API CMS
      try {
        List<BookSummaryModel> networkBooks = await _bookService.fetchNetworkBookCatalog();
        for (var netBook in networkBooks) {
          // Hanya tambahkan jika buku dari server belum ada di lokal
          if (!_books.any((b) => b.idBuku == netBook.idBuku)) {
            _books.add(netBook);
          }
        }
      } catch (networkError) {
        // SILENT CATCH: Jika API mati atau belum dibuat, aplikasi hanya mencetak log
        // dan TETAP HIDUP dengan data lokal.
        debugPrint("API CMS gagal atau offline: $networkError");
      }

      // 3. RESOLUSI STATUS UNDUHAN UI
      for (var book in _books) {
        if (book.judulBukuIndonesia == "Setetes Air Hujan Ingin ke Samudra" || book.judulBukuIndonesia == "Dongeng Janiti") {
          bookStates[book.idBuku] = "READY";
        } else {
          bool isDownloaded = await _storageService.isBookDownloaded(book.idBuku);
          bookStates[book.idBuku] = isDownloaded ? "READY" : "NOT_DOWNLOADED";
        }
      }
    } catch (e) {
      _error = 'Kegagalan sistem fatal saat memuat katalog: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> triggerDownloadBook(String bookId, int version) async {
    bookStates[bookId] = "DOWNLOADING";
    notifyListeners();

    try {
      await _bookService.downloadAndExtractBookArchive(bookId);
      await _storageService.saveBookDownloadStatus(bookId, version);
      bookStates[bookId] = "READY";
    } catch (e) {
      bookStates[bookId] = "NOT_DOWNLOADED";
      _error = 'Gagal mengunduh buku: $e';
    }
    notifyListeners();
  }

  BookSummaryModel? getBookById(String id) {
    try {
      return _books.firstWhere((book) => book.idBuku == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshBooks() async {
    await loadDashboardCatalog();
  }
}