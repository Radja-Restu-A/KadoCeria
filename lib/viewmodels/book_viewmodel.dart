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
        
        for (var netBook in networkBooks) {
          bool idMatch = _books.any((b) => b.idBuku == netBook.idBuku);
          bool titleMatch = _books.any((b) {
            String bTitleId = b.judulBukuIndonesia.toLowerCase().trim();
            String bTitleSu = b.judulBukuSunda.toLowerCase().trim();
            String netTitleId = netBook.judulBukuIndonesia.toLowerCase().trim();
            String netTitleSu = netBook.judulBukuSunda.toLowerCase().trim();
            return bTitleId == netTitleId || bTitleSu == netTitleSu;
          });

          if (idMatch && titleMatch) {
            debugPrint("[BookViewModel] Skipping exact duplicate from network: ${netBook.judulBukuIndonesia} (ID: ${netBook.idBuku})");
            continue;
          }

          if (idMatch && !titleMatch) {
            debugPrint("[BookViewModel] ID collision detected for ${netBook.judulBukuIndonesia} (ID: ${netBook.idBuku}). Assigning new ID...");
            
            // Find max numeric ID among current books
            int maxId = 0;
            for (var b in _books) {
              int currentId = int.tryParse(b.idBuku) ?? 0;
              if (currentId > maxId) maxId = currentId;
            }
            String newId = (maxId + 1).toString();
            debugPrint("[BookViewModel] Assigned pending ID: $newId");
            
            _books.add(netBook.copyWith(pendingId: newId));
          } else {
            debugPrint("[BookViewModel] Adding new network book: ${netBook.judulBukuIndonesia} (ID: ${netBook.idBuku})");
            _books.add(netBook);
          }
        }
      } catch (networkError) {
        debugPrint("[BookViewModel] API CMS gagal atau offline: $networkError");
      }

      debugPrint('[BookViewModel] Resolving download states for ${_books.length} books...');
      for (var book in _books) {
        bool isLocal = book.fileSize == 'Bundled' || book.fileSize == 'Downloaded';
        if (isLocal) {
          bookStates[book.idBuku] = "READY";
        } else {
          bool isDownloaded = await _storageService.isBookDownloaded(book.idBuku);
          bookStates[book.idBuku] = isDownloaded ? "READY" : "NOT_DOWNLOADED";
        }
        debugPrint('[BookViewModel] Book ${book.judulBukuIndonesia} (ID: ${book.idBuku}) state: ${bookStates[book.idBuku]}');
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

    // Temukan model buku untuk mengecek pendingId
    BookSummaryModel? bookModel = getBookById(bookId);
    String? pendingId = bookModel?.pendingId;
    String finalId = pendingId ?? bookId;

    bookStates[bookId] = "DOWNLOADING";
    notifyListeners();

    try {
      await _bookService.downloadAndExtractBookArchive(bookId, overrideId: pendingId);
      await _storageService.saveBookDownloadStatus(finalId, version);
      
      // Jika ID berubah, kita perlu mengupdate state untuk ID baru
      if (pendingId != null) {
        bookStates[finalId] = "READY";
        // Opsional: bersihkan state ID lama jika diperlukan
        // bookStates.remove(bookId);
      } else {
        bookStates[bookId] = "READY";
      }
      
      debugPrint("Download success for book: $finalId");
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