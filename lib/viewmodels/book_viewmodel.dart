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
      // 1. OFFLINE-FIRST: Muat data lokal sebagai fondasi absolut
      debugPrint('[BookViewModel] Fetching local bundled catalog...');
      List<BookSummaryModel> localBooks = await _bookService.fetchLocalBundledCatalog();
      _books = List.from(localBooks);
      debugPrint('[BookViewModel] Local books loaded: ${_books.length}');

      // Render layar secepat mungkin dengan data lokal (Dongeng Janiti & Sakeclak)
      notifyListeners();

      // 2. NETWORK SYNC: Coba sinkronisasi dengan data API CMS
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

          // 1. Eksklusi eksplisit untuk buku yang sudah ada di bundled assets
          if (excludedTitles.contains(netTitleId) || excludedTitles.contains(netTitleSu)) {
            debugPrint("[BookViewModel] Skipping bundled book from network: ${netBook.judulBukuIndonesia}");
            continue;
          }

          // 2. Deduplikasi berdasarkan judul (bukan ID)
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
        // SILENT CATCH: Jika API mati atau belum dibuat, aplikasi hanya mencetak log
        // dan TETAP HIDUP dengan data lokal.
        debugPrint("[BookViewModel] API CMS gagal atau offline: $networkError");
      }

      // 3. RESOLUSI STATUS UNDUHAN UI
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
      
      // Update state secara eksplisit agar UI langsung berubah ke "BACA"
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

  // Menemukan buku lokal yang sesuai berdasarkan judul jika ID tidak cocok
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